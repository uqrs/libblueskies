--------------------------------------------------------------------------------------------------------------------------------
-- File Indices
--------------------------------------------------------------------------------------------------------------------------------
-- This file contains several tables storing sequences of numbers, strings and function pointers that correspond to offset,
-- section length, and identifier so that the methods declared in flipnote.lua can easily navigate these files. Lastly, the
-- function pointer points to a function that should be executed. This function gets passed the value of the words themselves,
-- and whatever they return gets assigned to the identifier. These functions are found in src/handlers.lua, and must be loaded
-- into memory before this file.
--
-- Additionally, this file supplies a "binding" method- when invoked on a flipnote object, the given objects' KFH, KTN, KMC,
-- KMI, and KSN tables will be assigned a metatable that contains a __index metamethod. If one of the fields that appear in
-- INDEX.<table> down below is accessed, the metamethod will take the OFFSET, LENGTH, and HANDLER from INDEX.<table> below,
-- retrieve the given data from the header using string.sub(), pass it through the specified handler, and then pass it back.
--
-- If the indexed field ends in '_raw', then the 'COPY' handler will be used- i.e. the metamethod doesn't process the data-
-- instead, it will hand it back in its entirety.
--
-- Down below, for the subtables in the INDEX table, a few special rules apply:
--		If either the LENGTH or OFFSET is a string, then the respective contents of the field the string describes will be used.
--			e.g. LENGTH of field `A` is "B", then `B`s length will be used.
--		If OFFSET/LENGTH is nil, then the metamethod will attempt to guess these.
--
-- [The reference tables found in this file are registered under a Creative Commons Attribution-ShareAlike 4.0 International
--  License, and it authored by and can be accredited to the Flipnote Collective. Nothing but the wording has been slightly
--  altered; the addition of the "IDENTIFIER" column has been introduced by libblueskies and was not at all included by the
--  Flipnote Collective. http://github.com/flipnote-collective/flipnote-studio-3d-docs ]
--------------------------------------------------------------------------------------------------------------------------------
local INDEX={};
--------------------------------------------------------------------------------------------------------------------------------
-- Generate all of the handlers that will be utilised in this file:
--------------------------------------------------------------------------------------------------------------------------------
local EPOCH=HANDLERS.MULTI(
   HANDLERS.ENDIAN("little",true,true),
   HANDLERS.EPOCH(946681200)
)
local COPY=HANDLERS.COPY()
local BIG_ENDIAN=HANDLERS.ENDIAN("big",true,true)
local LITTLE_ENDIAN=HANDLERS.ENDIAN("little",true,true)
local UTF16=HANDLERS.UTF16()
--------------------------------------------------------------------------------------------------------------------------------
-- File Header Data -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            CRC32 of section contents      Big Endian                             crc32
-- 12      4            Creation Timestamp             LE seconds since 00:00:00 jan 1st      creation
-- 16      4            Last Edit Timestamp            Ditto                                  last_edit
-- 20      4            ?????                          All-Zero                               unknown
-- 24      10           Root Creator ID                Null-terminated hex                    creator_id
-- 34      10           Parent Creator ID              Ditto                                  parent_id
-- 44      10           Current Creator ID             Ditto                                  current_id
-- 54      22           Root Creator Username          Null-padded UTF-16 LE                  creator_name
-- 76      22           Parent Creator Username        Ditto                                  parent_name
-- 98      22           Current Creator ID             Ditto                                  current_id
-- 120     28           Root Filename                  Encoded.                               root_file
-- 148     28           Parent Filename                Ditto.                                 parent_file
-- 176     28           Current Filename               Ditto.                                 current_file
-- 204     2            Frame Count                    Unsigned LE                            frames
-- 206     2            Thumbnail Frame Index          Unsigned LE. Starts from zero          thumbnail
-- 208     2            Various Flags                  ???                                    flags
-- 210     2            Flipnote Speed                 Speeds Below                           framerate
-- 211     1            Layer Visibility               ???                                    layer_vis
--------------------------------------------------------------------------------------------------------------------------------
INDEX.KFH={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   magic        ={0,        4,                COPY          },
   length       ={4,        4,                LITTLE_ENDIAN },
   crc32        ={8,        4,                LITTLE_ENDIAN },
   creation     ={12,       4,                EPOCH         },
   last_edit    ={16,       4,                EPOCH         },
   unknown      ={20,       4,                LITTLE_ENDIAN },
   creator_id   ={24,       10,               LITTLE_ENDIAN },
   parent_id    ={34,       10,               LITTLE_ENDIAN },
   current_id   ={44,       10,               LITTLE_ENDIAN },
   creator_name ={54,       22,               UTF16         },
   parent_name  ={76,       22,               UTF16         },
   current_name ={98,       22,               UTF16         },
   root_file    ={120,      22,               COPY          },
   parent_file  ={148,      22,               COPY          },
   current_file ={176,      22,               COPY          },
   frames       ={204,      2,                LITTLE_ENDIAN },
   thumbnail    ={206,      2,                LITTLE_ENDIAN },
   flags        ={208,      2,                LITTLE_ENDIAN },
   framerate    ={210,      1,                LITTLE_ENDIAN },
   layer_vis    ={211,      1,                LITTLE_ENDIAN }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Thumbnail Section -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            Unknown                                                               unknown
-- 12      4            JPG Image Data                 80x64px                                jpg
--------------------------------------------------------------------------------------------------------------------------------
-- Need to figure out how to turn the JPG Image data into something sensible.
--------------------------------------------------------------------------------------------------------------------------------
INDEX.KTN={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   magic        ={0,        4,                COPY          },
   length       ={4,        4,                LITTLE_ENDIAN },
   unknown      ={8,        4,                LITTLE_ENDIAN },
   jpg          ={12,       4,                COPY          }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Sound Section -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            Speed When Recorded                                                   speed
-- 12      4            Background Music Length        Unsigned Little Endian                 bgm_length
-- 16      4            Sound Effect 1 (A) Length      Ditto.                                 se1_length
-- 20      4            Sound Effect 2 (X) Length      Ditto.                                 se2_length
-- 24      4            Sound Effect 3 (Y) Length      Ditto.                                 se3_length
-- 28      4            Sound Effect 4 (UP)Length      Ditto.                                 se4_length
-- 32      bgm_length   Background Music Data          4-bit ADPCM @ 16.5kHz                  bgm_data
--         se1_length   Sound Effect 1 (A) Data        Ditto.                                 se1_data
--         se2_length   Sound Effect 2 (X) Data        Ditto.                                 se2_data
--         se3_length   Sound Effect 3 (Y) Data        Ditto.                                 se3_data
--         se4_length   Sound Effect 4 (UP)Data        Ditto.                                 se4_data
--------------------------------------------------------------------------------------------------------------------------------
INDEX.KSN={
-- IDENTIFIER     OFFSET     LENGTH            HANDLER
   magic        ={0,         4,                COPY          },
   length       ={4,         4,                LITTLE_ENDIAN },
   speed        ={8,         4,                COPY          },
   bgm_length   ={12,        4,                LITTLE_ENDIAN },
   se1_length   ={16,        4,                LITTLE_ENDIAN },
   se2_length   ={20,        4,                LITTLE_ENDIAN },
   se3_length   ={24,        4,                LITTLE_ENDIAN },
   se4_length   ={28,        4,                LITTLE_ENDIAN },
   bgm_data     ={32,        "bgm_length",     COPY          },
   se1_data     ={"bgm_data","se1_length",     COPY          },
   se2_data     ={"se1_data","se2_length",     COPY          },
   se3_data     ={"se2_data","se3_length",     COPY          },
   se4_data     ={"se3_data","se4_length",     COPY          }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Memo Color Section -- C-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            Unknown Value                                                         unknown
-- 12      remaining    Frame Data                     Format Unknown                         data
--------------------------------------------------------------------------------------------------------------------------------
INDEX.KMC={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   magic        ={0,        4,                COPY          },
   length       ={4,        4,                LITTLE_ENDIAN },
   unknown      ={8,        4,                COPY          },
   data         ={12,       nil,              COPY          }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Memo Info Section -- C-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       .5           Unknown                                                               unknown
-- .5      .5           Paper Colour                                                          colour
-- 1       .5           Layer A colour 1                                                      lA_c1
-- 1.5     .5           Layer A colour 2                                                      lA_c2
-- 2       .5           Layer B colour 1                                                      lB_c1
-- 2.5     .5           Layer B colour 3                                                      lB_c3
-- 3       .5           Layer C colour 1                                                      lC_c1
-- 3.5     .5           Layer C colour 3                                                      lC_c3
-- 4       2            Layer A size in KMC            Unsigned Little Endian                 lA_size
-- 6       2            Layer B size in KMC            Ditto.                                 lB_size
-- 8       2            Layer C size in KMC            Ditto.                                 lC_size
-- 10      10           Frame Author ID                Null-terminated Hex(?)                 author
-- 20      1            Layer A 3D Depth               Unsigned Little Endian                 lA_3d
-- 21      1            Layer B 3D Depth               Ditto.                                 lB_3d
-- 22      1            Layer C 3D Depth               Ditto.                                 lC_3d
-- 23      1            Sound Effect Flags             To be deciphered(?)                    se_flags
-- 24      4            Camera Usage                   No: 0x0000; Yes: 0x0700;               camera
--------------------------------------------------------------------------------------------------------------------------------
-- Everything after KMI's header/length repeats itself- For INDEX.KMI[n] offsets every single value appearing in INDEX.KMI[n]
-- with by 28 bytes (meaning INDEX.KMI[1] holds the first frames' data- INDEX.KMI[2] holds the seconds frames' data, etc.) The
-- "half byte" (.5 offsets/lengths) count as 4 bits, and they will be parsed as such.
--------------------------------------------------------------------------------------------------------------------------------
INDEX.KMI={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   magic        ={0,        4,                COPY          },
   length       ={4,        4,                LITTLE_ENDIAN },
}

INDEX.KMI_FRAMES={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   unknown      ={0,        .5,               COPY          },
	colour       ={.5,       .5,               LITTLE_ENDIAN }, -- Not sure on handler- needs be verified.
	lA_c1        ={1,        .5,               LITTLE_ENDIAN }, -- Ditto.
	lA_c2        ={1.5,      .5,               LITTLE_ENDIAN }, -- Ditto.
	lB_c1        ={2,        .5,               LITTLE_ENDIAN }, -- Ditto.
	lB_c3        ={2.5,      .5,               LITTLE_ENDIAN }, -- Ditto.
	lC_c1        ={3,        .5,               LITTLE_ENDIAN }, -- Ditto.
	lC_c3        ={3.5,      .5,               LITTLE_ENDIAN }, -- Ditto
	lA_size      ={4,        2,                LITTLE_ENDIAN },
	lB_size      ={6,        2,                LITTLE_ENDIAN },
	lC_size      ={8,        2,                LITTLE_ENDIAN },
	author       ={10,       10,               BIG_ENDIAN    },
	lA_3d        ={20,       1,                LITTLE_ENDIAN },
	lB_3d        ={21,       1,                LITTLE_ENDIAN },
	lC_3d        ={22,       1,                LITTLE_ENDIAN },
	se_flags     ={23,       1,                COPY          },
	camera       ={24,       4,                BIG_ENDIAN    }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Default Metamap
--------------------------------------------------------------------------------------------------------------------------------
-- A list of metatables with __index and __newindex methods for the headers in INDEX. These are assigned by
-- flipnote_headermeta() further down.
--
-- A lookup table 'lookup' will be generated- this allows metamethods to trace back which INDEX table they're looking through,
-- and which flipnote they belong to.
--------------------------------------------------------------------------------------------------------------------------------
local lookup=setmetatable({},{__mode="k"});
local META={};
--------------------------------------------------------------------------------------------------------------------------------
-- Get Offset-length-handler
--------------------------------------------------------------------------------------------------------------------------------
-- A function used by many metamethods- accepts two arguments- self (the table that's being indexed), and index (the field
-- being looked for.) get_olh() goes to the appropriate subtable in INDEX[] and attempts to retrieve the offset, length, and
-- handler for this field, dereferencing as necessary--
--
-- If in the INDEX[] table "offset" is a string referring to another field 'f', then get_olh() will assume the offset is 'f's
-- offset + 'f's length (meaning the offset is right after the aforementioned field).
--
-- If in the INDEX[] table "length" is a string referring to another field 'n', then the value of this field will be used as
-- the length (to deal with one field describing anothers' length).
--
-- If in the INDEX[] table "length" is nil, then get_olh() will assume the rest of the section belongs to this field.
--------------------------------------------------------------------------------------------------------------------------------
local function get_olh ( self , index );
	-- Get a reference to the appropriate INDEX table.
	local reference=INDEX[lookup[self].consult or lookup[self].header];

	-- Does the index even exist?
	-- If not- it's gonna be a nil.
	if ( not reference[index] ) then
		return nil
	end

	-- Retrieve the offset, length, and handler.
	local offset =(reference[index][1]);
	local length =(reference[index][2]);
	local handler=(reference[index][3]);
	-- If the length is a string, then it will assume the numerical value outputted by the contents of the index referred to by
	-- the string. If the length is nil, then assume it's the rest of the header.
	if ( type(length) == "string" ) then; length=tonumber(self[length]);
	elseif ( length == nil        ) then; length=math.abs(header:len()-offset-1);
	else --[[ not a string or nil]]     ; length=math.abs(length-1); end;
	-- If the offset is a string, then it will assume this field directly succeeds the field referred to by the string.
	if ( type(offset) == "string" ) then;
		-- This block attempts to deduce where the offset should be, based on the offsets and values before it.
		local margin=1; local iter=0; local current=offset;
		repeat
			margin=margin+self[current]:len(); iter=iter+1; current=reference[current][1];
		until (type(current) ~= "string")
		offset=current+margin-iter;
	else --[[ not a string       ]]     ; offset=offset+1; end;

	return offset,length,handler;
end
--------------------------------------------------------------------------------------------------------------------------------
-- "standard" is pretty normal- __index looks through its associated header file for the field that's supposed to be accessed,
-- and then uses the offset and length to return the appropriate field.
--------------------------------------------------------------------------------------------------------------------------------
META.STANDARD={};
function META.STANDARD.__index ( self , index )
	-- Temporarily store which header and flipnote this instance belongs to.
	local header=lookup[self].flipnote.header_raw[lookup[self].header];
	local flipnote=lookup[self].flipnote;
	local raw=false; nocache=false;
	-- If there's an extra offset:
	local extra_offset=lookup[self].offset or 0;
	-- Does the 'index' end in '_nocache'? If so, set 'nocache' to true and remove it from the index field.
	if ( index:find("_nocache$") ) then; nocache=true; index=index:gsub("_nocache$",""); end;
	if ( lookup[self].cache[index] and (not nocache) ) then return lookup[self].cache[index] end;
	-- Does the 'index' end in '_raw'? If so, set 'raw' to true, and remove it from the index field:
	if ( index:find("_raw$") ) then; raw=true; index=index:gsub("_raw$",""); end;
	-- Retrieve the offset, length, and handler:
	local offset,length,handler=get_olh(self,index);
	-- If we're supposed to be using a raw handler, set it to COPY:
	handler=((not raw) and handler) or COPY
	-- If the offset is 'nil', then this field does not exist:
	if ( not offset ) then
		return nil
	else
		offset=offset+extra_offset;
	end

   -- Sometimes (like with KMI's frame data), half bits must be interpreted.
   -- To deal with this, the offset is rounded down, and the length is rounded up. The resulting margins are used to retrieve
   -- the appropriate string of characters. Then, the two floats from the offset/length are used to cut off part of the first/final ---- byte.
   local offset_f,length_f;
   -- Split the integer and fractional part of the offset and length.
   offset,offset_f=math.modf(offset);
   length,length_f=math.modf(length);
   -- If either fractional is not 0, then start doing special stuff:
   if ( (length_f ~= 0) or (offset_f ~= 0) ) then
      -- Make sure both fractionals are divisible by .125:
      if ( ((length_f*1000)%125)~=0 or ((offset_f*1000)%125)~=0 ) then
         error("invalid length/offset: must be divisible by .125")
      end
      -- Retrieve the appropriate header.
      header=header:sub(math.floor(offset),math.ceil(offset+length));
      -- If the offset has a float:
		print(offset_f,length_f)
		print(header:byte())
      if ( offset_f ~= 0 ) then
         -- What to replace the character with: /just/ the least significant bits of the first character.
         local replacewith=string.char(bit32.extract(header:sub(1,1):byte(),0,(offset_f/.125)-1))
			print(bit32.extract(header:sub(1,1):byte(),0,(offset_f/.125)-1))
         header=header:gsub(
            -- Replace the very first character,
            "^.",
            -- If the character happens to be '%':
            (replacewith=="%" and "%%") or replacewith
         )
      end
      -- Else, if the length is a float (and this header is longer than one byte)
      if ( (length_f ~= 0) and header:len()>1 ) then
         -- What to replace the character with: /just/ the most significant bits of said final character.
         local replacewith=string.char(bit32.extract(header:sub(-1,-1):byte(),4,4+(length_f/.125)))
			header=header:gsub(
            -- Replace the very last character,
            ".$",
            -- If the character happens to be '%':
            (replacewith=="%" and "%%") or replacewith
         )
      end
		-- Cache the retrieved value:
		lookup[self].cache[index]=handler(header);
		-- And return it.
		return lookup[self].cache[index];
	-- Else, it's a boring whole value.
	else
		-- Cache the retrieved value:
		lookup[self].cache[index]=handler(header:sub(offset,offset+length));
		-- And return it.
		return lookup[self].cache[index];
	end
end
--------------------------------------------------------------------------------------------------------------------------------
-- Iterating Over Indices
--------------------------------------------------------------------------------------------------------------------------------
-- Generate an iterator that can iterate over kwz file headers.
--------------------------------------------------------------------------------------------------------------------------------
function META.STANDARD.__call ( self )
	-- Keep track of where we are.
	local reference=(INDEX[lookup[self].consult or lookup[self].header]);
	local current=nil;
	-- Keep returning the next value until we're through.
	return function ()
		current=next(reference,current);
		return current,(current and self[current]) or nil
	end
end
--------------------------------------------------------------------------------------------------------------------------------
-- KMI - Memo Info Handler
--------------------------------------------------------------------------------------------------------------------------------
-- A metamethod to be assigned to a KMI header that, when accessed with any integer larger than 0, returns a special subtable
-- that, when indexed for any of the values found in META.KMI[1], returns the given value for the appropriate frame.
--------------------------------------------------------------------------------------------------------------------------------
META.MEMOINFO={};
function META.MEMOINFO.__index ( self , index )
   -- If the given index isn't a number, forward it to the standard metamethod.
   if ( type(index) ~= "number" ) then
      return META.STANDARD.__index(self,index);
   end

   -- Does a frame table already exist? If so, don't bother generating a new one.
   if ( lookup[self].cache[index] ) then
      return lookup[self].cache[index];
   end

   -- If there's no lookup for frame data length, generate and store it:
   if ( not lookup[self].frames ) then
      -- Grab the KMI length, and divide it by '28' (which is the amount of data reserved for every frame.)
      lookup[self].frames=(self.length / 28)
   end

   -- If the indexed number is either below 1, or above the amount of frames:
   if ( (index > lookup[self].frames) or (index < 1) ) then
      -- Return nil. That'll show them.
      return nil;
   end

   -- Else, return a table not unlike the KSN and KFH ones- each returning the appropriate data for the indexed fields.
   -- To all of these, the following offset is applied to the existing one: '8 + ((index-1) * 28)'. The first '8' would is to
   -- skip over the magic-length found at the very start. The latter part of the calculation points the metatable to the
   -- appropriate 28-byte wide block in the KMI header.
   do
      -- Generate a table bound to metatable META.STANDARD.
      local frame_table=setmetatable({},META.STANDARD)
      -- Add a lookup entry for this frame table, including an appropriate byte offset.
      lookup[frame_table]={
         -- Refer to the flipnote the KMI header refers to.
         flipnote=lookup[self].flipnote,
         -- Set the proper header index to the one containing frame data indices:
         header="KMI",
         -- Consult KMI_FRAMES for indices, not KMI.
         consult="KMI_FRAMES",
         cache={},
         -- Always head to the appropriate 28-character long block of pixels.
         offset=(8+(index-1)*28),
      };
      -- Generate a cache entry for this frame table:
      lookup[self].cache[index]=frame_table
      -- Return this frame table:
      return frame_table;
   end;
end
--------------------------------------------------------------------------------------------------------------------------------
local metamap={KFH=META.STANDARD,KSN=META.STANDARD,KTN=META.STANDARD,KMC=META.STANDARD,KMI=META.MEMOINFO};
--------------------------------------------------------------------------------------------------------------------------------
-- Binding Function
--------------------------------------------------------------------------------------------------------------------------------
-- Generates two unique metatables- one that is to be assigned to the flipnotes' 'header' table (hub). This 'header'
-- table returns another metatable (branch) that:
--		Deciphers which index 'hub' was accessed for.
--		It takes this index, and looks for the appropriate listing in INDEX (e.g. hub.KFH => INDEX.KFH).
--		It returns a metatable 'branch' that- when indexed for a value, looks through the earlier specified INDEX listing for the
--			corresponding field (e.g. hub.KFH.thumbnail => INDEX.KFH.thumbnail).
--		The corresponding INDEX listing holds the BYTE OFFSET, LENGTH, and HANDLER (int, int, function).
--		'branch' now uses this info to look through the flipnotes' appropriate header. Using string.sub(), it fishes the given
--			LENGTH-sized byte sequence from the header. (e.g. hub.KFH.thumbnail => bytes 207 - 208 in the file header).
--		To prevent constant recalculation, the retrieved value is assigned to hub.branch[value] so that it needn't be
--			recalculated with every access (for example- variable-length indices may be a bit slow to lookup).
--------------------------------------------------------------------------------------------------------------------------------
--		Every individual branch might work a bit different- for example, INDEX.KMI repeats itself constantly, whereas INDEX.KMC is
--			relatively normal. To account for these differing ways of interpreting the indices found in INDEX, a 'metamap' will be
--			assigned- the metamap is a table with multiple subtables (each assigned to a key matching the name of a header- e.g.
--			KMC, KMI, etc.) that contain a __index and __newindex field. These subtables will directly be used as a metatable.
--------------------------------------------------------------------------------------------------------------------------------
-- Declare a lookup table that the metamethods in the metamap can look through to decipher which header and flipnote they're
-- looking for.
--------------------------------------------------------------------------------------------------------------------------------
local function flipnote_headermeta ( flipnote )
	do -- Start a local block where we declare a hidden 'self' variable so that the __index or __newindex methods know where to
		-- look.
		-- Now, populate the flipnotes' 'header' table:
		flipnote.header={};
		-- Begin assigning metatables:
		for header,metatable in pairs(metamap) do
			flipnote.header[header]=setmetatable({},metatable);
			lookup[flipnote.header[header]]={flipnote=flipnote,header=header,cache={},offset=0};
		end
	end -- End local block
end

return flipnote_headermeta;