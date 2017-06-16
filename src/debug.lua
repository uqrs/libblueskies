--Recursive table-content printing. Useful for debugging.
function table.rprint(tbl,tab)
	tab = tab or 0
	for k,v in pairs(tbl) do
		print(
			("%s %s : %s"):format(
				("\t"):rep(tab),
				tostring(k),
				tostring(v)
			)
		)
		if type(v) == "table" then
			table.rprint(v,tab+1)
		end
	end
end

-- Simple (and perhaps a little bit ugly) table serialisation function.
do
	local keywords = " and break do else elseif end false for function if in local nil not or repeat return then true until while " -- Lua keywords which may not be subjected to syntactic sugar.
	local legal_string_key = "^[A-Za-z_][A-Za-z_%d]*$" -- A pattern that matches string keys that can be subjected to syntactic sugar.

	function table.serialise(tab,lvl)
		tab = (tab or {}) -- The table we're going to be serialising.
		lvl = (lvl or 1) -- The indentation level (amount of tabs)
		local output = "{\n" -- Our final output string.
		local indent = string.rep( "\t" , lvl ) -- Our indentation string (series of tabs)

		for key,value in pairs( tab ) do

			-- We begin by writing a key:
			if ( type(key) == "string" ) then

				if ( key:find( legal_string_key ) ) and ( not keywords:find( " "..key.." " ) ) then -- If both the key is 'legal' (matchable against legal_string_key) and is not a keyword...
					output = ("%s%s%s = "):format( output , indent , key ) -- Write it without brackets and quotes []

				else -- On the contrary, if illegal:
					output = ("%s%s['%s'] = "):format( output , indent , (key:gsub([[\]],[[\\]]):gsub( [[']],[[\']] )) ) -- Write it with brackets and quotes, and take care of backslashes.

				end

			elseif ( type(key) == "number" ) then
				output = ("%s%s[%s] = "):format( output , indent , tostring(key) ) -- Write a number with brackets.

			elseif ( key == true ) then
				output = ("%s%s[%s] = "):format( output , indent , "true" )

			elseif ( key == false ) then
				output = ("%s%s[%s] = "):format( output , indent , "false" )

			else
				error( ("cannot serialise a type %s"):format( type(key) ) ) -- It's probably a function, thread, or userdata.

			end

			-- Now, we write a value:
			if ( type( value ) == "string" ) then
				output = ("%s%q,\n"):format( output, value:gsub([[\]],[[\\]]):gsub([["]],[[\"]]) ) -- Take care of backslashes, and escape double quotes.

			elseif ( type( value ) == "number" ) then
				output = output..value..",\n" -- Write the number normally.

			elseif ( type( value ) == "table" ) then
				output = output.. ( table.serialise( value , lvl+1 ) )..",\n" -- Recurse! Serialise a table inside of this table!

			elseif ( value == true ) then
				output = output.."true,\n"

			elseif ( value == false ) then
				output = output.."false,\n"

			else
				error( ("cannot serialise a type %s"):format( type(value) ) ) -- It's probably a function, thread, or userdata.

			end

		end
		return output..indent:gsub("\t","",1).."}"
	end

end
