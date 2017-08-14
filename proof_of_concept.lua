#!/usr/bin/lua
require("blueskies.debug");
require("blueskies");

-- Load command line stuff.
local arg={...}

-- Did the user specify anything?
if ( not arg[1] ) then
	print("Specify a flipnote to analyse.");
	os.exit()
end

-- Generate a flipnote for this file:
local test_flipnote=Blueskies.flipnote:new(io.open(arg[1],"r"), true)
-- Store the headers temporarily.
local KFH=test_flipnote.header.KFH
local KSN=test_flipnote.header.KSN
local KMI=test_flipnote.header.KMI
local KTN=test_flipnote.header.KTN
local KMI_raw=test_flipnote.header_raw.KMI
local KSN_raw=test_flipnote.header_raw.KSN
local KFH_raw=test_flipnote.header_raw.KFH

local KFH_ORG={}; local KSN_ORG={};
for KEY,VALUE in KFH() do
	KFH_ORG[KEY]=VALUE;
end

for KEY,VALUE in KSN() do
	KSN_ORG[KEY]=VALUE;
end

-- This is 4-bit ADPCM @ 16500Hz.
-- sox -N -t ima -v 1 -r 16500 INPUT_FILE OUTPUT_FILE.wav
-- Setting -v to the desired volume (.1, .5, 1, 2, 4, etc.)
local bgm_f=io.open("bgm_data.pcm","w"); bgm_f:write(KSN.bgm_data); bgm_f:close(); print("Dumped background audio to bgm_data.pcm");
local se1_f=io.open("se1_data.pcm","w"); se1_f:write(KSN.se1_data); se1_f:close(); print("Dumped sound effect 1   to se1_data.pcm");
local se2_f=io.open("se2_data.pcm","w"); se2_f:write(KSN.se2_data); se2_f:close(); print("Dumped sound effect 2   to se2_data.pcm");
local se3_f=io.open("se3_data.pcm","w"); se3_f:write(KSN.se3_data); se3_f:close(); print("Dumped sound effect 3   to se3_data.pcm");
local se4_f=io.open("se4_data.pcm","w"); se4_f:write(KSN.se4_data); se4_f:close(); print("Dumped sound effect 4   to se4_data.pcm");
local jpg_f=io.open("jpg_data.jpg","w"); jpg_f:write(KTN.jpg);      jpg_f:close(); print("Dumped JPG header data  to jpg_data.jpg");

print("CRC32 as calculated by crc32(): 0x" .. ("%08X"):format(Blueskies.crc32(KFH_raw:sub(13))))
print("CRC32 as given by KFH         : 0x" .. ("%08X"):format(KFH.crc32))
