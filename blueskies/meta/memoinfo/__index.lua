local lookup=_lookup
local blueskies_index=_index
local blueskies_static=Blueskies
--------------------------------------------------------------------------------------------------------------------------------
-- KMI - Memo Info Handler
--------------------------------------------------------------------------------------------------------------------------------
-- A metamethod to be assigned to a KMI header that, when accessed with any integer larger than 0, returns a special subtable
-- that, when indexed for any of the values found in reference.KMI[1], returns the given value for the appropriate frame.
--------------------------------------------------------------------------------------------------------------------------------
return function ( self , index )
   -- If the given index isn't a number, forward it to the standard metamethod.
   if ( type(index) ~= "number" ) then
      return blueskies_index.meta.standard.__index(self,index);
   end

   -- Does a frame table already exist? If so, don't bother generating a new one.
   if ( lookup[self].cache[index] ) then
      return lookup[self].cache[index];
   end

   -- If there's no lookup for frame data length, generate and store it:
   if ( not lookup[self].frames ) then
      -- Grab the KMI length, and divide it by '28' (which is the amount of data reserved for every frame.)
      lookup[self].frames=(self.length / 28)
   end

   -- If the indexed number is either below 1, or above the amount of frames:
   if ( (index > lookup[self].frames) or (index < 1) ) then
      -- Return nil. That'll show them.
      return nil;
   end

   -- Else, return a table not unlike the KSN and KFH ones- each returning the appropriate data for the indexed fields.
   -- To all of these, the following offset is applied to the existing one: '8 + ((index-1) * 28)'. The first '8' would is to
   -- skip over the magic-length found at the very start. The latter part of the calculation points the metatable to the
   -- appropriate 28-byte wide block in the KMI header.
   do
      -- Generate a table bound to metatable `standard`
      local frame_table=setmetatable({},blueskies_index.meta.standard)
      -- Add a lookup entry for this frame table, including an appropriate byte offset.
      lookup[frame_table]={
         -- Refer to the flipnote the KMI header refers to.
         flipnote=lookup[self].flipnote,
         -- Set the proper header index to the one containing frame data indices:
         header="KMI",
         -- Consult KMI_FRAMES for indices, not KMI.
         consult="KMI_FRAMES",
         cache={},
         -- Always head to the appropriate 28-character long block of pixels.
         offset=(8+(index-1)*28),
      };
      -- Generate a cache entry for this frame table:
      lookup[self].cache[index]=frame_table
      -- Return this frame table:
      return frame_table;
   end;
end
