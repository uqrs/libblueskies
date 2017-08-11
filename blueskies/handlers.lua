--------------------------------------------------------------------------------------------------------------------------------
-- File Content Handlers
--------------------------------------------------------------------------------------------------------------------------------
-- The "HANDLER_PROTO" table contains a bunch of function pointers that accept arguments, and return arbitrary data. Further
-- down, gen_handler() generates wrapper functions for these handlers- a feature that src/indices.lua makes use of.
--------------------------------------------------------------------------------------------------------------------------------
do; local handlers_proto={}
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - Chain
--------------------------------------------------------------------------------------------------------------------------------
-- Takes any amount of handler objects, and passes the input throughout other handlers.
--------------------------------------------------------------------------------------------------------------------------------
	function handlers_proto.chain ( input , ... )
		local last_output=input;
		for _,handler in pairs({...}) do
			last_output=handler(last_output);
		end
		return last_output;
	end;
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - Copy
--------------------------------------------------------------------------------------------------------------------------------
-- Literally copies data from one end to another.
--------------------------------------------------------------------------------------------------------------------------------
	function handlers_proto.copy ( input )
		return input
	end;
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - Epoch
--------------------------------------------------------------------------------------------------------------------------------
-- Return the total amount of seconds since 1970 + since
--------------------------------------------------------------------------------------------------------------------------------
	function handlers_proto.epoch ( input , since )
		if ( not since ) then; since=0; end
		return os.date("*t",tonumber(input)+since)
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - UTF-16 display name.
--------------------------------------------------------------------------------------------------------------------------------
	function handlers_proto.utf16 ( input )
		local full="";
		-- Go from the last pair of bytes to the very first:
		for i = input:len(),1,-2 do
			full=utf8.char( tonumber("0x" .. ("%02X%02X"):format( input:sub(i,i):byte(),input:sub(i-1,i-1):byte() ) ) )..full
		end
		return full;
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - Generic Little Endian Parsing
--------------------------------------------------------------------------------------------------------------------------------
-- Parses the given byte sequence, either little or big endian (depending on the value of "endianness"). If 'hexify' is set to
-- 'true', then the output will be a hexidecimal digit. If set to 'false', it will return the number as an integer. If
-- 'prefix' is set to 'true', "0x" is prepended to the output.
--------------------------------------------------------------------------------------------------------------------------------
	function handlers_proto.endian ( input , endianness , hexify , prefix )
		local full="";
		-- Determine from where to where the for loop should go:
		local start,stop,interval;
		if ( endianness == "big" )    then; start,stop,interval=input:len(),1,-1;
		else --[[little endian          ]]; start,stop,interval=1,input:len(), 1;
		end
		-- Need we prepend '0x'?
		if ( prefix ) then; prefix="0x"; end

		-- Go from the begin to the end, either generating a hex character or a regular decimal integer.
		;;;; if ( not hexify )	then; for i = start,stop,interval do
					full=tonumber( "0x" ..("%02X"):format( input:sub(i,i):byte() ) ) .. full;
		end; else --[[leave as hex]]; for i = start,stop,interval do
					full=("%02X"):format(input:sub(i,i):byte() ) .. full
		end; end
		-- Done.
		return (prefix or "") .. full
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Handler - Bit Extraction
--------------------------------------------------------------------------------------------------------------------------------
-- Returns bits 'from' to 'to' as an individual number. Really just a fancy bit32.extract() wrapper.
--------------------------------------------------------------------------------------------------------------------------------
	function handlers_proto.bits ( input , from , to )
		return bit32.extract(input,from,to)
	end
--------------------------------------------------------------------------------------------------------------------------------
-- Meta Handlers
--------------------------------------------------------------------------------------------------------------------------------
-- The "handlers" table is what can be accessed globally- it contains a metatable that, when indexed, returns a function that
-- accepts arguments, and then returns a function pointer to a handler function that has been generated on-the-fly.
--------------------------------------------------------------------------------------------------------------------------------
	local function gen_handler ( self , index )
		return function ( ... )
			do
				-- Keep the arguments and index safe.
				local arguments={...};
				local which=index;
				-- Ensure this handler even exists (if not, throw an error):
				if ( not handlers_proto[which] ) then
					error("no such handler prototype '" .. which .. "'",2);
				end

				-- Return a function that calls the handler with the appropriate arguments.
				return function ( input )
					return handlers_proto[which]( input , table.unpack(arguments) )
				end
			end;
		end;
	end;
	return setmetatable({},{__index=gen_handler});
end
