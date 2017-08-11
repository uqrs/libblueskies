--------------------------------------------------------------------------------------------------------------------------------
-- Metatables
--------------------------------------------------------------------------------------------------------------------------------
-- A list of metatables with __index and __newindex methods for the headers in Blueskies.reference. These are assigned by
-- the function further down.
--
-- A lookup table 'lookup' will be generated- this allows metamethods to trace back which reference table they're looking
-- through, and which flipnote they belong to.
--------------------------------------------------------------------------------------------------------------------------------
local index={};
local lookup=setmetatable({},{__mode="k"});
-- Temporary global references to `index` and `lookup` will be made so that the required files can save local references to
-- these (using statements such as `local blueskies_index=_index; local lookup=_lookup);
-- These are cleared after all `require()` calls are done.
_lookup=lookup; _index=index;
index.meta={};
index.meta.standard={};
index.meta.memoinfo={};
index.get_olh=require("blueskies.meta.get_olh");
index.meta.standard.__index=require("blueskies.meta.standard.__index");
index.meta.standard.__call=require("blueskies.meta.standard.__call");
--Blueskies.index.meta.standard.__newindex=require("blueskies.meta.standard.__newindex.__newindex"); --TBD
--Blueskies.index.meta.standard.hooks=require("blueskies.meta.standard.__newindex.hooks"); --TBD
index.meta.memoinfo.__index=require("blueskies.meta.memoinfo.__index");
--Blueskies.index.meta.memoinfo.__call=require("blueskies.meta.memoinfo.__call"); -- TBD
--Blueskies.index.meta.memoinfo.__newindex=require("blueskies.meta.memoinfo.__newindex.hooks"); --TBD
--Blueskies.index.meta.memoinfo.hooks=require("blueskies.meta.memoinfo.__newindex.__newindex"); --TBD
_lookup=nil; _index=nil;

-- `index_metamap` keeps track which file sections (subtables in `Blueskies.reference`) should be bound to which metatables.
local index_metamap={
	KFH=index.meta.standard,
	KSN=index.meta.standard,
	KTN=index.meta.standard,
	KMC=index.meta.standard,
	KMI=index.meta.memoinfo,
};
--------------------------------------------------------------------------------------------------------------------------------
-- Binding Function
--------------------------------------------------------------------------------------------------------------------------------
-- Generates two unique metatables- one that is to be assigned to the flipnotes' 'header' table (hub). This 'header'
-- table returns another metatable (branch) that:
--		Deciphers which index 'hub' was accessed for.
--		It takes this index, and looks for the appropriate listing in reference (e.g. hub.KFH => reference.KFH).
--		It returns a metatable 'branch' that- when indexed for a value, looks through the earlier specified reference listing for the
--			corresponding field (e.g. hub.KFH.thumbnail => reference.KFH.thumbnail).
--		The corresponding reference listing holds the BYTE OFFSET, LENGTH, and HANDLER (int, int, function).
--		'branch' now uses this info to look through the flipnotes' appropriate header. Using string.sub(), it fishes the given
--			LENGTH-sized byte sequence from the header. (e.g. hub.KFH.thumbnail => bytes 207 - 208 in the file header).
--		To prevent constant recalculation, the retrieved value is assigned to hub.branch[value] so that it needn't be
--			recalculated with every access (for example- variable-length indices may be a bit slow to lookup).
--------------------------------------------------------------------------------------------------------------------------------
--		Every individual branch might work a bit different- for example, reference.KMI repeats itself constantly, whereas reference.KMC is
--			relatively normal. To account for these differing ways of interpreting the indices found in reference, a 'metamap' will be
--			assigned- the metamap is a table with multiple subtables (each assigned to a key matching the name of a header- e.g.
--			KMC, KMI, etc.) that contain a __index and __newindex field. These subtables will directly be used as a metatable.
--------------------------------------------------------------------------------------------------------------------------------
-- Declare a lookup table that the metamethods in the metamap can look through to decipher which header and flipnote they're
-- looking for.
--------------------------------------------------------------------------------------------------------------------------------
return function ( self )
	do -- Start a local block where we declare a hidden 'self' variable so that the __index or __newindex methods know where to
		-- look.
		-- Now, populate the flipnotes' 'header' table:
		self.header={};
		-- Begin assigning metatables:
		for header,metatable in pairs(index_metamap) do
			self.header[header]=setmetatable({},metatable);
			lookup[self.header[header]]={flipnote=self,header=header,cache={},offset=0};
		end
	end -- End local block
end
