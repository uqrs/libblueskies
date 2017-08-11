--------------------------------------------------------------------------------------------------------------------------------
-- Basic Flipnote Object- "kwz" deserialised.
--------------------------------------------------------------------------------------------------------------------------------
-- The main "flipnote" object should aid in properly managing and keeping track of
-- flipnotes that have been loaded into memory. It shall contain several
-- methods for loading data from, and deserialising .kwz files into memory.
--
-- In the classic lua manner, we declare a singular "object"- a table with
-- an index field pointing to itself, and a "new" method for generating new
-- objects. This should all be fairly obvious to regular Lua programmers.
--------------------------------------------------------------------------------------------------------------------------------
Blueskies.flipnote={};
Blueskies.flipnote.__index=Blueskies.flipnote;
Blueskies.flipnote.header_raw={};
--------------------------------------------------------------------------------------------------------------------------------
-- If 'file' is specified, then the data will be loaded from the given file
-- handle/process. If 'init' is either nil or true and file is specified,
-- then the loaded data will automatically be deserialised.
--
-- 'bind', when false, prevents the Flipnote object from being bound to the reference tables located in `src/indices.lua`.
--------------------------------------------------------------------------------------------------------------------------------
function Blueskies.flipnote:new ( file , init , bind )
	-- Create a new object.
	local object=setmetatable({},self);
	object.__index=self;
	-- If "file" is specified, :new will call load_from_file.
	if ( file ) then
		object:load( file )
	end

	if ( (bind == nil) or bind ) then
		self:meta_init();
	end

	-- Return it.
	return object;
end;

--------------------------------------------------------------------------------------------------------------------------------
-- Parsing Headers
--------------------------------------------------------------------------------------------------------------------------------
-- Utilising documentation courtesy of Flipnote Collective. Thank god for them.
--
-- Note that length values are stored little endian.
-- b8 0b 00 00 => 00 00 0b b8 => 0xbb8
--
-- parse_header() takes an eight-byte sequence (the header), and returns two
-- values: magic, and length.
--------------------------------------------------------------------------------------------------------------------------------
do
	function parse_header ( header )
		-- Dunno what the fourth magic byte does. Ignore it.
		local magic = header:sub(1,3);
		local length= header:sub(5,8);

		-- Our final hexidecimal value.
		local hex_val="0x";

		-- Start at the very final byte (most significant) and end at the very
		-- last byte of the length. Construct an appropriate hexadecimal
		-- value.
		for i = 4,1,-1 do
			hex_val=(hex_val .. ("%02X"):format(length:sub(i,i):byte()))
		end

		return magic,tonumber(hex_val);
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Loading Flipnotes from File.
--------------------------------------------------------------------------------------------------------------------------------
-- 'deserialise' does what it says on the tin- it takes a file handle for a
-- .kwz file, and guts it for lines, before properly parsing the full thing.
--
-- "file" is a file handle for a .kwz file or a process.
--------------------------------------------------------------------------------------------------------------------------------
	function Blueskies.flipnote:load ( file )
		-- Essential assertions:
		assert(type(file) == "userdata", "expected userdata. Got " .. type(file))

		-- Declare essential local variables.
		local full=file:read("*all"); file:close();
		local parse_what={};

		-- Now, we iterate over the entire contents of 'full', attempting to
		-- parse it into memory.
		local current_position = 1;
		local section;
		local content_length=full:len();
		repeat
			-- Parse the appropriate magic and header.
			magic,length=parse_header(full:sub(current_position,current_position+7))
			-- Load the entirety of this section into memory:
			self.header_raw[magic]=full:sub(current_position,current_position+length+7);
			-- And skip to the next position.
			current_position=current_position+length+8
		until (current_position >= content_length)
		-- Everything's done.
	end;
--------------------------------------------------------------------------------------------------------------------------------
-- Deserialising data.
--------------------------------------------------------------------------------------------------------------------------------
-- Here, the data stored to the header will be deserialised. This meaning-
-- individual hexadecimal values will be converted to (usable) Lua data. It
-- utilises the indices specified in src/indices.lua as the second argument to
-- keep track of what means what.
--------------------------------------------------------------------------------------------------------------------------------
	function Blueskies.flipnote:deserialise ( section , index )
		-- TO DO
	end;
end;

--------------------------------------------------------------------------------------------------------------------------------
-- Framerate lookup table.
--------------------------------------------------------------------------------------------------------------------------------
Blueskies.flipnote.framerate={[0]=.2,.5,4,6,8,9,10}
--------------------------------------------------------------------------------------------------------------------------------
