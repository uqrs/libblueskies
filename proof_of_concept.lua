#!/usr/bin/lua
-- Require appropriate files.
require("./src/flipnote")
require("./src/handlers")
local meta=require("./src/indices")
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
meta(test_flipnote);
-- Store the header file temporarily.
local KFH=test_flipnote.header.KFH
local KTN=test_flipnote.header_raw.KTN
local KSN=test_flipnote.header.KSN

KFH_ORG={}; KSN_ORG={};
for KEY,VALUE in KFH() do
	KFH_ORG[KEY]=VALUE;
end

for KEY,VALUE in KSN() do
	KSN_ORG[KEY]=VALUE;
end

print(table.serialise(KFH_ORG))

-- This is 4-bit ADPCM @ 16500Hz.
-- sox -N -t ima -v 1 -r 16500 INPUT_FILE OUTPUT_FILE.wav
-- Setting -v to the desired volume (.1, .5, 1, 2, 4, etc.)
local bgm_f=io.open("bgm_data.pcm","w"); bgm_f:write(KSN.bgm_data); bgm_f:close();
local se1_f=io.open("se1_data.pcm","w"); se1_f:write(KSN.se1_data); se1_f:close();
local se2_f=io.open("se2_data.pcm","w"); se2_f:write(KSN.se2_data); se2_f:close();
local se3_f=io.open("se3_data.pcm","w"); se3_f:write(KSN.se3_data); se3_f:close();
local se4_f=io.open("se4_data.pcm","w"); se4_f:write(KSN.se4_data); se4_f:close();