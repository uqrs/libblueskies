# Documentation - Flipnotes
A flipnote object is a table with a collection of functions and facilities
for storing and retrieving individual parts of a flipnote. It acts only as a
gateway for Lua scripts to edit and interact with `.kwz` files.
The following diagram should explain the general overview
```
                  --------------------- --------------------------------
            ----► | .kwz file on disk | | Piped Process via io.popen() |
            |     --------------------- --------------------------------
            |              |                          |
            |      [ flipnote:load() ] ◄---------------
            |              |
            |              ▼
            |     ---------------------     ---------------------------------------
            |     |  Flipnote Object  |.... | Metatables located in `self.header` |
            |     ---------------------     ---------------------------------------
            |              .                   ▲                           |
            |              .                   |                           |
            |              .                   |                     [ __newindex ]
            |              .               [ __index ]                     |
            |              .                   |                         ------------------------------
            |              .                   |                         |                            |
    [ flipnote:write() ]   .                   |                         ▼                            ▼
            |              .            --------------------- ---------------------- ----------------------------------
            |              .            | kwz READ handlers | | kwz WRITE handlers | |           WRITE hooks          |
            |              .            --------------------- ---------------------- | (Modify CRC32, checksums, etc. |
            |              .                     ▲                       |           ----------------------------------
            |              .                     |                       |                            |
            |              .                     |                       |                            |
            |              .               [ string.sub ]                |                            |
            |              .                     |                       |                            |
            |     ---------------------------------------------          |                            |
            |-----| 'raw' copies of sections in the .kwz file | ◄--------------------------------------
            |     ---------------------------------------------
            |
            |     -----------------      --------------
            |---► | Video Decoder |----► | Video Data | -----
            |     -----------------      --------------     |    ----------     ------------------
            ▼                                               |--► | FFMPEG | --► | MP4, AVI, etc. |
       -----------           ---------------                |    ----------     ------------------
       | sox API | --------► | Sound Files |-----------------
       -----------           ---------------
```
## Basic Data Reading
The Flipnote object contains raw copies of the various sections included in
the .kwz file (KFH, KSN, etc.) These individual raw sections are copied over
to a table `self.header_raw`. This is done so that the individual sections
each start from byte position `1` (this is done to traverse individual
sections consistently- this way they are not affected by the lengths of
other sections). The `flipnote` object contains a table called `header`.
Whenever this `header` table (henceforth referred to as `hub`) is indexed for the name of a `kwz` file section
(KFH, KSN, KMI, etc.), another table is returned (now referred to as a
`branch`). `hub` was assigned a metatable that- when indexed for the name of
an individual file section, _generates_ a table along with a metatable, and
then returns this as `branch`. `branch`'s metatable makes it so that - when
it is indexed for a value - a _reference table_ with its name corresponding
to the `.kwz` file section `branch` is bound to located in `src/indices.lua`
is consulted. This reference table contains `keys`, each with an individual
table assigned as its value. This table contains a `byte offset` (`o`), a `value
length` (in bytes, `l`), and a `handler` (`h`). Whenever `branch` is indexed for a
value that corresponds to a `key` in this reference table, then the sequence
of bytes between `o` and `o+l` located in the corresponding `kwz` file
section is retrieved, and passed to `h`. `branch` finally returns whatever `h` spits out.

### An Example - Basic Data Reading
A `branch` bound to `KFH` is indexed for the value `creator_name`. This
branch's `__index` metamethod is invoked, causing it to consult the
`INDEX.KFH` table located in `src/indices.lua` for the key `creator_name`.
It finds a table describing an offset of `54`, a length of `22`, and the
`UTF16` handler. It goes to the `KFH` header located in `self.header_raw`-
`self.header_raw.KFH`, and retrieves bytes `55` to `76` from the string
stored therein. It then submits these `22` bytes to `UTF16` (which spits out
a UTF16 character string), and returns its return value. In the end:
```
print(self.header.KFH.creator_name) -- => Fluffy\0\0\0\0\0
```

## Data Indexing With Variable Length/Offset
The reference tables may also contain string values for either the length or
offset. These're special cases- If offset `o` for key `k` is a string, then
`o` must refer to another key in the same reference table- `kp` (with its
respective offset and length- `op` and `lp`). Then, `o` is considered to be
located at `op+lp+1` (the byte located after the sequence of bytes
describing the value for `kp`).

If length `l` is a string describing key `kp`, then the length of `k` shall be considered
to be whatever the handler for `kp` returns. 

### An Example - Indexing With Variable Length/Offset
A `branch` bound to `KSN` is indexed for the value `se1_data`. This branch's
`__index` metamethod is invoked, causing it to consuld the `INDEX.KSN` table
located in `src/indices.lua` for the key `se1_data`. It finds a table with
the offset describing `bgm_data`, and a length describing `se1_length`.

First, to calculate the offset, it looks at the reference for the variable
`bgm_data`. It sees that `bgm_data` has an offset of `32`, and a length of
`bgm_length`. Consequently- it shall look at the reference for `bgm_length`,
which has an offset of `12`, and a length of `4`. It hands bytes `13-16` to
the `LITTLE_ENDIAN` handler (which is a function that parses hexadecimal
byte sequences little endian, returning a full integer). Let's say for the
sake of example this handler returns `318`. The length of `bgm_data` is now
`318` bytes, so that means that `bgm_data` ends at `350`, which means that
`350` is the offset for `se1_data`.

Then, `se1_length` is consulted which has an offset of `16`, and a length
of `4`. Similar to `bgm_length`- `se1_length` is resolved- bytes `17-20` are
passed to the `LITTLE_ENDIAN` handler, and the output of this handler is
used as the length for `se1_data`. Let's say for example that this length is
`40`. Consequently, bytes `351` to `390` are ripped, and passed as the
result for `se1_data`.

## Assorted Misc. Info
### Reading Half Bytes
A final exception (which is semi-poorly supported) is when the length or
offset are decimal values- such as `.5`, or `.125`. If the offset happens to
have a decimal part (divided into the `integer` part `i`, and `decimal` part `d`- the
latter of which must - by the way - always be divisible by `.125`. I think
you can guess why.) then the first `8*d` _bits_ are removed from the final
sequence of (now bits) that are passed to the handler. If the `length` has a
decimal part, then the last `8*d` _bits_ are removed from the final sequence
before they get passed to the handler.

### Caching
Considering the fact index calculations can be a bit expensive, values
retrieved from raw headers are stored in a cache inaccessible from the
outside due to closures. To _force_ the metamethods to re-read the value
from the raw headers, one may append `_nocache` to the key value (e.g.
`KFH.crc32_nocache`).

### Raw Values
Sometimes- the format in which a given indexed value is returned is simply
not desirable- the data may be passed as a UTF-16 string, but we may for
example, want data in big endian. For this, `_raw` can be appended to the
index name- this overrides the original handler (`UTF16`) with `COPY`. This
way we can handle the raw data however we want (e.g.
`BIG_ENDIAN(KFH.creator_name_raw)`).

## About Handlers
Handlers - though portrayed as a regular function - are under the hood,
specially generated functions derived from a prototype.

Prototypes are declared in `src/handlers.lua` as regular lua functions,
accepting arguments only concerning their own execution. These functions are
all stored in the `HANDLERS_PROTO` table. A globally accessible table-
`HANDLERS` remains empty, but has a metatable assigned to it that returns a
function `gen_handler()` when indexed for 'n'.
`gen_handler()` accepts any amount of arguments-` these arguments have a
`n to n+1` correspondence with the arguments accepted by
`HANDLERS_PROTO[h]`. This means that the first argument supplied to
`gen_handler()`, corresponds to the second argument accepted by
`HANDLERS_PROTO[h]`.
`gen_handler()` stores these arguments (inaccessible from the outside due to closures), and returns a wrapper function. This
wrapper function- whenever called, executes the function
`HANDLERS_PROTO[h]`, supplying the arguments that were initially handed to
`gen_handler()`.

An example- The `HANDLERS_PROTO.ENDIAN()` function accepts a multitude of
variables- to simplify this example, only the first two shall be focused
upon. The first, `input`, related to the sequence of bytes that must be
parsed and interpreted as a number. The second, `endianness` corresponds to
either one of two strings- "big" or "little".

When calling `HANDLERS.ENDIAN("big")`, `gen_handler()` is invoked.
`gen_handler()` stores the string `"big"` in a local variable, and then
creates a function that accepts a single string (`input`), then calls 
calls `HANDLERS_PROTO.ENDIAN(input,"big")`, and then finally returns
whatever `HANDLERS_PROTO.ENDIAN` returns.

This way, one might construct:
```lua
local BIG_ENDIAN=HANDLERS.ENDIAN("big");
print(BIG_ENDIAN(big_endian_byte_sequence)) -- => 12345
```

### The `CHAIN` Handler
The `CHAIN` handler prototype takes any number of ('n') functions or other
handlers, and returns a function that - when called - passes its input to
function `n`, takes `n`s return value, and passes that to function `n+1`,
repeat that process from `n+1` to `n+2`, etc. This effectively allows (as
the name implies) several handlers to be chained together.
