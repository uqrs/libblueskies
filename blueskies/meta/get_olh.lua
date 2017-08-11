local lookup=_lookup;
local blueskies_reference=Blueskies.reference;
--------------------------------------------------------------------------------------------------------------------------------
-- Get Offset-length-handler
--------------------------------------------------------------------------------------------------------------------------------
-- A function used by many metamethods- accepts two arguments- self (the table that's being indexed), and index (the field
-- being looked for.) get_olh() goes to the appropriate subtable in reference[] and attempts to retrieve the offset, length, and
-- handler for this field, dereferencing as necessary--
--
-- If in the reference[] table "offset" is a string referring to another field 'f', then get_olh() will assume the offset is 'f's
-- offset + 'f's length (meaning the offset is right after the aforementioned field).
--
-- If in the reference[] table "length" is a string referring to another field 'n', then the value of this field will be used as
-- the length (to deal with one field describing anothers' length).
--
-- If in the reference[] table "length" is nil, then get_olh() will assume the rest of the section belongs to this field.
--------------------------------------------------------------------------------------------------------------------------------
local function get_olh ( self , index );
	-- Get a reference to the appropriate index-reference table.
	local reference=blueskies_reference[lookup[self].consult or lookup[self].header];

	-- Does the index even exist?
	-- If not- it's gonna be a nil.
	if ( not reference[index] ) then
		return nil
	end

	-- Retrieve the offset, length, and handler.
	local offset =(reference[index][1]);
	local length =(reference[index][2]);
	local handler=(reference[index][3]);
	-- If the length is a string, then it will assume the numerical value outputted by the contents of the index referred to by
	-- the string. If the length is nil, then assume it's the rest of the header.
	if ( type(length) == "string" ) then; length=tonumber(self[length]);
	elseif ( length == nil        ) then; length=math.abs(header:len()-offset-1);
	else --[[ not a string or nil]]     ; length=math.abs(length-1); end;
	-- If the offset is a string, then it will assume this field directly succeeds the field referred to by the string.
	if ( type(offset) == "string" ) then;
		-- This block attempts to deduce where the offset should be, based on the offsets and values before it.
		local margin=1; local iter=0; local current=offset;
		repeat
			margin=margin+self[current]:len(); iter=iter+1; current=reference[current][1];
		until (type(current) ~= "string")
		offset=current+margin-iter;
	else --[[ not a string       ]]     ; offset=offset+1; end;

	return offset,length,handler;
end

return get_olh;