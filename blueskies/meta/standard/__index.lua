local lookup=_lookup;
local blueskies_index=_index
local blueskies_static=Blueskies;
--------------------------------------------------------------------------------------------------------------------------------
-- The `__call` metamethod does all of the dirty work- it does the job of consulting the reference table
-- (`Blueskies.reference`) for the correct byte offsets, and then starts pulling them out of the raw headers.
--------------------------------------------------------------------------------------------------------------------------------
return function ( self , index )
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
	local offset,length,handler=blueskies_index.get_olh(self,index);
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