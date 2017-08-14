local lookup=_lookup;
local blueskies_index=_index
local blueskies_static=Blueskies;
--------------------------------------------------------------------------------------------------------------------------------
-- The `__index` metamethod does all of the dirty work- it does the job of consulting the reference table
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
	-- If the offset is 'nil', then this field does not exist:
	if ( not offset ) then
		return nil
	else
		offset=offset+extra_offset;
	end

	-- Cache the retrieved value:
	if ( raw ) then
		lookup[self].cache[index]=header:sub(offset,offset+length);
	else
		print(index)
		lookup[self].cache[index]=handler(header:sub(offset,offset+length));
	end
	-- And return it.
	return lookup[self].cache[index];
end
