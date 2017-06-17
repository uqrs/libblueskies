--------------------------------------------------------------------------------------------------------------------------------
-- File Indices
--------------------------------------------------------------------------------------------------------------------------------
-- This file contains several tables storing sequences of numbers, strings and function pointers that correspond to offset,
-- section length, and identifier so that the methods declared in flipnote.lua can easily navigate these files. Lastly, the
-- function pointer points to a function that should be executed. This function gets passed the value of the words themselves,
-- and whatever they return gets assigned to the identifier. These functions are found in src/handlers.lua, and must be loaded
-- into memory before this file.
--
-- Additionally, this file supplies a "binding" method- when invoked on a flipnote object, the given objects' KFH, KTN, KMC,
-- KMI, and KSN tables will be assigned a metatable that contains a __index metamethod. If one of the fields that appear in
-- META.<table> down below is accessed, the metamethod will take the OFFSET, LENGTH, and HANDLER from META.<table> below,
-- retrieve the given data from the header using string.sub(), pass it through the specified handler, and then pass it back.
--
-- If the indexed field ends in '_raw', then the 'COPY' handler will be used- i.e. the metamethod doesn't process the data-
-- instead, it will hand it back in its entirety.
--
-- Down below, for the subtables in the META table, a few special rules apply:
--		If either the LENGTH or OFFSET is a string, then the respective contents of the field the string describes will be used.
--			e.g. LENGTH of field `A` is "B", then `B`s length will be used.
--		If OFFSET/LENGTH is nil, then the metamethod will attempt to guess these.
--
-- [The reference tables found in this file are registered under a Creative Commons Attribution-ShareAlike 4.0 International
--  License, and it authored by and can be accredited to the Flipnote Collective. Nothing but the wording has been slightly
--  altered; the addition of the "IDENTIFIER" column has been introduced by libblueskies and was not at all included by the
--  Flipnote Collective. http://github.com/flipnote-collective/flipnote-studio-3d-docs ]
--------------------------------------------------------------------------------------------------------------------------------
local META={};
--------------------------------------------------------------------------------------------------------------------------------
-- Generate all of the handlers that will be utilised in this file:
--------------------------------------------------------------------------------------------------------------------------------
local EPOCH=HANDLERS.MULTI(
   HANDLERS.ENDIAN("little",true,true),
   HANDLERS.EPOCH(946681200)
)
local COPY=HANDLERS.COPY()
local BIG_ENDIAN=HANDLERS.ENDIAN("big",true)
local LITTLE_ENDIAN=HANDLERS.ENDIAN("little",true)
local UTF16=HANDLERS.UTF16()
--------------------------------------------------------------------------------------------------------------------------------
-- File Header Data -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            CRC32 of section contents      Big Endian                             crc32
-- 12      4            Creation Timestamp             LE seconds since 00:00:00 jan 1st      creation
-- 16      4            Last Edit Timestamp            Ditto                                  last_edit
-- 20      4            ?????                          All-Zero                               unknown
-- 24      10           Root Creator ID                Null-terminated hex                    creator_id
-- 34      10           Parent Creator ID              Ditto                                  parent_id
-- 44      10           Current Creator ID             Ditto                                  current_id
-- 54      22           Root Creator Username          Null-padded UTF-16 LE                  creator_name
-- 76      22           Parent Creator Username        Ditto                                  parent_name
-- 98      22           Current Creator ID             Ditto                                  current_id
-- 120     28           Root Filename                  Encoded.                               root_file
-- 148     28           Parent Filename                Ditto.                                 parent_file
-- 176     28           Current Filename               Ditto.                                 current_file
-- 204     2            Frame Count                    Unsigned LE                            frames
-- 206     2            Thumbnail Frame Index          Unsigned LE. Starts from zero          thumbnail
-- 208     2            Various Flags                  ???                                    flags
-- 210     2            Flipnote Speed                 Speeds Below                           framerate
-- 211     1            Layer Visibility               ???                                    layer_vis
--------------------------------------------------------------------------------------------------------------------------------
META.KFH={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   header       ={0,        8,                COPY          },
   crc32        ={8,        4,                COPY          },
   creation     ={12,       4,                EPOCH_2000    },
   last_edit    ={16,       4,                EPOCH_2000    },
   unknown      ={20,       4,                COPY          },
   creator_id   ={24,       10,               BIG_ENDIAN    },
   parent_id    ={34,       10,               BIG_ENDIAN    },
   current_id   ={44,       10,               BIG_ENDIAN    },
   creator_name ={54,       22,               UTF16         },
   parent_name  ={76,       22,               UTF16         },
   current_name ={98,       22,               UTF16         },
   root_file    ={120,      22,               COPY          },
   parent_file  ={148,      22,               COPY          },
   current_file ={176,      22,               COPY          },
   frames       ={204,      2,                LITTLE_ENDIAN },
   thumbnail    ={206,      2,                LITTLE_ENDIAN },
   flags        ={208,      2,                COPY          },
   framerate    ={210,      1,                COPY          },
   layer_vis    ={211,      1,                COPY          }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Thumbnail Section -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            Unknown                                                               unknown
-- 12      4            JPG Image Data                 80x64px                                jpg
--------------------------------------------------------------------------------------------------------------------------------
-- Need to figure out how to turn the JPG Image data into something sensible.
--------------------------------------------------------------------------------------------------------------------------------
META.KTN={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   header       ={0,        8,                COPY          },
   unknown      ={8,        4,                COPY          },
   jpg          ={12,       4,                COPY          }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Sound Section -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            Speed When Recorded                                                   speed
-- 12      4            Background Music Length        Unsigned Little Endian                 bgm_length
-- 16      4            Sound Effect 1 (A) Length      Ditto.                                 se1_length
-- 20      4            Sound Effect 2 (X) Length      Ditto.                                 se2_length
-- 24      4            Sound Effect 3 (Y) Length      Ditto.                                 se3_length
-- 28      4            Sound Effect 4 (UP)Length      Ditto.                                 se4_length
-- 32      bgm_length   Background Music Data          4-bit ADPCM @ 16.5kHz                  bgm_data
--         se1_length   Sound Effect 1 (A) Data        Ditto.                                 se1_data
--         se2_length   Sound Effect 2 (X) Data        Ditto.                                 se2_data
--         se3_length   Sound Effect 3 (Y) Data        Ditto.                                 se3_data
--         se4_length   Sound Effect 4 (UP)Data        Ditto.                                 se4_data
--------------------------------------------------------------------------------------------------------------------------------
META.KSN={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER
   header       ={0,        8,                COPY          },
   speed        ={8,        4,                COPY          },
   bgm_length   ={12,       4,                LITTLE_ENDIAN },
   se1_length   ={16,       4,                LITTLE_ENDIAN },
   se2_length   ={20,       4,                LITTLE_ENDIAN },
   se3_length   ={24,       4,                LITTLE_ENDIAN },
   se4_length   ={28,       4,                LITTLE_ENDIAN },
   bgm_data     ={32,       "bgm_length",     COPY          },
   se1_data     ={nil,      "se1_length",     COPY          },
   se2_data     ={nil,      "se2_length",     COPY          },
   se3_data     ={nil,      "se3_length",     COPY          },
   se4_data     ={nil,      "se4_length",     COPY          }
}

--------------------------------------------------------------------------------------------------------------------------------
-- Binding Function
--------------------------------------------------------------------------------------------------------------------------------
-- Generates two unique metatables- one that is to be assigned to the flipnotes' 'header' table (hub). This 'header'
-- table returns another metatable (branch) that:
--		Deciphers which index 'hub' was accessed for.
--		It takes this index, and looks for the appropriate listing in META (e.g. master.KFH => META.KFH).
--		It returns a metatable 'branch' that- when indexed for a value, looks through the earlier specified META listing for the
--			corresponding field (e.g. master.KFH.thumbnail => META.KFH.thumbnail).
--		The corresponding META listing holds the BYTE OFFSET, LENGTH, and HANDLER (int, int, function).
--		'branch' now uses this info to look through the flipnotes' appropriate header. Using string.sub(), it fishes the given
--			LENGTH-sized byte sequence from the header. (e.g. master.KFH.thumbnail => bytes 207 - 208 in
--------------------------------------------------------------------------------------------------------------------------------
local function flipnote_headermeta ( flipnote ) --TO BE DONE
	do -- Start a local block where we declare a hidden 'self' variable so that the newly created __index method knows where to
		-- look for which header.
		local self=flipnote;
	end -- End local block
end

return flipnote_headermeta;