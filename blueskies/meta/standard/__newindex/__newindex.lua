local lookup=_lookup;
local blueskies_index=_index
local blueskies_static=Blueskies;
--------------------------------------------------------------------------------------------------------------------------------
-- The `__newindex` metamethod does all of the dirty assignment work- it does the job of consulting the reference table
-- (`Blueskies.reference`) for the correct byte offsets, and then starts overwriting the proper position in the byte header.
--------------------------------------------------------------------------------------------------------------------------------
return function ( self , index , value )
	-- Temporarily store which header and flipnote this instance belongs to.
	local header=lookup[self].flipnote.header_raw[lookup[self].header];
	local flipnote=lookup[self].flipnote;
	local raw=false; nocache=false;
	-- If there's an extra offset:
	local extra_offset=lookup[self].offset or 0;
	-- Does the 'index' end in '_raw'? If so, set 'raw' to true, and remove it from the index field:
	if ( index:find("_raw$") ) then; raw=true; index=index:gsub("_raw$",""); end;
	-- Retrieve the offset, length, and handler:
	local offset,length,_,handler=blueskies_index.get_olh(self,index);
	-- If the offset is 'nil', then this field does not exist:
	if ( not offset ) then
		return nil
	else
		offset=offset+extra_offset;
	end

	-- Push the value through the handler if `raw` isn't true.
	if ( raw ) then
		value=value;
	else
		-- The current contents of this field are also passed to the handler (some handlers/molds need to know the current value
		-- in order to appropriately modify it.
		value=handler(value,header:sub(offset,offset+length));
	end

	-- If the value isn't a string, complain:
	if ( not (type(value) == "string") ) then
		error("fatal handler exception- handler did not return a string value")
	end

	-- Now, assign the new value by overwriting the previous header.
	lookup[self].flipnote.header_raw[lookup[self].header]=(
		header:sub(0,offset-1)..value..header:sub(offset+length+1)
	)
	-- Wipe the cache for this field:
	lookup[self].cache[index]=nil;
end
