--------------------------------------------------------------------------------------------------------------------------------
-- Initialization File. Requires all the appropriate files, and makes a few bridges between files.
--------------------------------------------------------------------------------------------------------------------------------
do
	Blueskies={};
    Blueskies.flipnote=require("blueskies.flipnote");
	Blueskies.handlers=require("blueskies.handlers");
	Blueskies.mold=require("blueskies.mold");
	Blueskies.reference=require("blueskies.reference");
	Blueskies.flipnote.meta=require("blueskies.meta");
	Blueskies.crc32=require("blueskies.crc32");
end;