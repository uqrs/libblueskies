#!/usr/bin/lua
-- Require appropriate files.
require("./src/flipnote")
require("./src/handlers")
require("./src/indices")
require("./src/debug")

-- Load command line stuff.
local arg={...}

-- Did the user specify anything?
if ( not arg[1] ) then
	print("Specify a flipnote to analyse.");
	os.exit()
end

-- Generate appropriate handlers.
local COPY=HANDLERS.COPY()
local UTF16=HANDLERS.UTF16()
local LITTLE_ENDIAN=HANDLERS.ENDIAN("little",true,true)
local BIG_ENDIAN=HANDLERS.ENDIAN("big",true)
local EPOCH_2000=HANDLERS.MULTI(
   HANDLERS.ENDIAN("little",true,true),
   HANDLERS.EPOCH(946681200)
)
-- Generate a flipnote for this file:
local test_flipnote=flipnote:new(io.open(arg[1],"r"), true)
-- Store the header file temporarily.
local KFH=test_flipnote.header_raw.KFH

-- Handle everything manually (to be automated using src/indices.lua)
rs={
   header=COPY(KFH:sub(1,8)),
   crc32=COPY(KFH:sub(9,12)),
   creation=EPOCH_2000(KFH:sub(13,16)),
   last_edit=EPOCH_2000(KFH:sub(17,20)),
   unknown=COPY(KFH:sub(21,24)),
   creator_id=BIG_ENDIAN(KFH:sub(25,34)),
   parent_id=BIG_ENDIAN(KFH:sub(35,44)),
   current_id=BIG_ENDIAN(KFH:sub(45,54)),
   creator_name=UTF16(KFH:sub(55,76)),
   parent_name=UTF16(KFH:sub(77,98)),
   current_name=UTF16(KFH:sub(99,120)),
   root_file=COPY(KFH:sub(121,148)),
   parent_file=COPY(KFH:sub(149,176)),
   current_file=COPY(KFH:sub(177,204)),
   frames=tonumber(LITTLE_ENDIAN(KFH:sub(205,206))),
   thumbnail=LITTLE_ENDIAN(KFH:sub(207,208)),
   flags=COPY(KFH:sub(209,210)),
   framerate=tonumber(LITTLE_ENDIAN(KFH:sub(211,211))),
   layer_vis=LITTLE_ENDIAN(KFH:sub(212,212))
}

-- And print the entire table.
print(table.serialise(rs))