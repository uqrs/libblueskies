local lookup=_lookup;
local reference=Blueskies.reference
--------------------------------------------------------------------------------------------------------------------------------
-- Iterating Over Indices
--------------------------------------------------------------------------------------------------------------------------------
-- Generates an iterator that can iterate over kwz file headers.
--------------------------------------------------------------------------------------------------------------------------------
return function ( self )
	-- Keep track of where we are.
	local where=(reference[lookup[self].consult or lookup[self].header]);
	local current=nil;
	-- Keep returning the next value until we're through.
	return function ()
		current=next(where,current);
		return current,(current and self[current]) or nil
	end
end
