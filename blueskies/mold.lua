--------------------------------------------------------------------------------------------------------------------------------
-- File Content Assignment Handlers
--------------------------------------------------------------------------------------------------------------------------------
-- The "mold_proto" table contains a bunch of function pointers that accept arguments, and return arbitrary data. Further
-- down, gen_mold() generates wrapper functions for these handlers- a feature that src/indices.lua makes use of.
--
-- Molds, unlike Handlers, are used to serialise data into bytestrings so that they can be substituted into the raw `kwz`
-- headers.
--------------------------------------------------------------------------------------------------------------------------------
do; local mold_proto={}
--------------------------------------------------------------------------------------------------------------------------------
-- Mold - Chain
--------------------------------------------------------------------------------------------------------------------------------
-- Takes any amount of molds, handlers, or functions, and passes the input throughout other handlers.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.chain ( input , old , ... )
		local last_output=input;
		for _,handler in pairs({...}) do
			last_output=handler(last_output);
		end
		return last_output;
	end;
--------------------------------------------------------------------------------------------------------------------------------
-- Mold - Copy
--------------------------------------------------------------------------------------------------------------------------------
-- Literally copies data from one end to another.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.copy ( input , old )
		return input
	end;
--------------------------------------------------------------------------------------------------------------------------------
-- Mold - Replace
--------------------------------------------------------------------------------------------------------------------------------
-- Fancy wrapper for `bit32.replace()`.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.replace ( input , old , from , to )
		return bit32.replace(old,input,from,to)
	end

--------------------------------------------------------------------------------------------------------------------------------
-- Mold - Epoch
--------------------------------------------------------------------------------------------------------------------------------
-- Takes the amount of seconds since 1970, and removes `since` so that the resulting value holds the amount of seconds since
-- 1970+since.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.epoch ( input , old , since )
		if ( not since ) then; since=0; end
		return (input-since)
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Mold - Generic Little Endian Parsing
--------------------------------------------------------------------------------------------------------------------------------
-- Parses the given number left-to-right and returns it as either a little or big endian string.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.endian ( input , old, endianness )
			-- This is the final table that's going to store all the bytes.
			local bytes = {};

			-- Keep turning the remainder into its corresponding byte value.
			while ( input > 0 ) do
				bytes[#bytes+1]=string.char(input % 256)
				input = (input-(input%256)) / 256
			end

			-- Return the finished byte string.
			if ( endianness == "big" ) then
				return table.concat(bytes):reverse()
			else
				return table.concat(bytes)
			end
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Mold - Convert string of hexadecimal bytes to a big/little endian byte sequence.
--------------------------------------------------------------------------------------------------------------------------------
-- Parses the given number left-to-right and returns it as either a little or big endian string.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.strendian ( input , old, endianness )
			-- This is the final table that's going to store all the bytes.
			local bytes = {};

			for i = 1,input:len(),2 do
				bytes[#bytes+1]=("%c"):format("0x"..input:sub(i,i+1))
			end

			-- Return the finished byte string.
			if ( endianness == "big" ) then
				return table.concat(bytes):reverse()
			else
				return table.concat(bytes)
			end
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - UTF-16 display name.
--------------------------------------------------------------------------------------------------------------------------------
	function mold_proto.utf16 ( input )
		local full="";
		-- Go from the last pair of bytes to the very first:
		for position,codepoint in utf8.codes(input) do
			full=utf8.char( tonumber("0x" .. ("%02X%02X"):format( input:sub(i,i):byte(),input:sub(i-1,i-1):byte() ) ) )..full
		end
		return full;
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Meta Molds
--------------------------------------------------------------------------------------------------------------------------------
-- The "molds" table is what can be accessed globally- it contains a metatable that, when indexed, returns a function that
-- accepts arguments, and then returns a function pointer to a mold that has been generated on-the-fly.
--------------------------------------------------------------------------------------------------------------------------------
	local function gen_mold ( self , index )
		return function ( ... )
			do
				-- Keep the arguments and index safe.
				local arguments={...};
				local which=index;
				-- Ensure this handler even exists (if not, throw an error):
				if ( not mold_proto[which] ) then
					error("no such mold prototype '" .. which .. "'",2);
				end

				-- Return a function that calls the handler with the appropriate arguments.
				return function ( input )
					return mold_proto[which]( input , table.unpack(arguments) )
				end
			end;
		end;
	end;
	return setmetatable({},{__index=gen_mold});
end
