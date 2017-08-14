--------------------------------------------------------------------------------------------------------------------------------
-- File Indices
--------------------------------------------------------------------------------------------------------------------------------
-- This file contains several tables storing sequences of numbers, strings and function pointers that correspond to offset,
-- section length, and identifier so that the methods declared in flipnote.lua can easily navigate these files. Lastly, the
-- function pointer points to a function that should be executed. This function gets passed the value of the words themselves,
-- and whatever they return gets assigned to the identifier. These functions are found in src/handlers.lua, and must be loaded
-- into memory before this file.
--
-- Down below, for the subtables in the REF table, a few special rules apply:
--		If either the LENGTH or OFFSET is a string, then the respective contents of the field the string describes will be used.
--			e.g. LENGTH of field `A` is "B", then `B`s length will be used.
--		If OFFSET/LENGTH is nil, then the metamethod will attempt to guess these.
--
-- The actual code that interacts with these indices can be found in `meta`.
--
-- [The reference tables found in this file are registered under a Creative Commons Attribution-ShareAlike 4.0 International
--  License, and it authored by and can be accredited to the Flipnote Collective. Nothing but the wording has been slightly
--  altered; the addition of the "IDENTIFIER" column has been introduced by libblueskies and was not at all included by the
--  Flipnote Collective. http://github.com/flipnote-collective/flipnote-studio-3d-docs ]
--------------------------------------------------------------------------------------------------------------------------------
local blueskies_static=Blueskies;
local REF={};
--------------------------------------------------------------------------------------------------------------------------------
-- Generate all of the handlers that will be utilised in this file:
--------------------------------------------------------------------------------------------------------------------------------
local MOST=blueskies_static.handlers.chain(
	string.byte,
	blueskies_static.handlers.bits(4,8)
)
local LEAST=blueskies_static.handlers.chain(
	string.byte,
	blueskies_static.handlers.bits(0,4)
)
local COPY=blueskies_static.handlers.copy()
local BIG_ENDIAN=blueskies_static.handlers.endian("big")
local LITTLE_ENDIAN=blueskies_static.handlers.endian("little")
local BIG_STRENDIAN=blueskies_static.handlers.strendian("big")
local LITTLE_STRENDIAN=blueskies_static.handlers.strendian("little")
local EPOCH=blueskies_static.handlers.chain(
   LITTLE_ENDIAN,
   blueskies_static.handlers.epoch(946681200)
)
local UTF16=blueskies_static.handlers.utf16()
--------------------------------------------------------------------------------------------------------------------------------
-- Generate all of the molds that will be utilised in this file:
--------------------------------------------------------------------------------------------------------------------------------
local M_COPY=blueskies_static.mold.copy()
local M_BIG_STRENDIAN=blueskies_static.mold.strendian("big")
local M_BIG_ENDIAN=blueskies_static.mold.chain(
   tonumber,
   blueskies_static.mold.endian("big")
)
local M_LITTLE_ENDIAN=blueskies_static.mold.chain(
   tonumber,
   blueskies_static.mold.endian("little")
)
local M_EPOCH=blueskies_static.mold.chain(
   blueskies_static.mold.epoch(946681200),
   blueskies_static.mold.endian("little")
)
local M_MOST=blueskies_static.mold.replace(4,8)
local M_LEAST=blueskies_static.mold.replace(0,4)
--------------------------------------------------------------------------------------------------------------------------------
-- File Header Data -- CC-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            CRC32 of section contents      Big Endian                             crc32
-- 12      4            Creation Timestamp             LE seconds since 2000 00:00:00 jan 1st creation
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
REF.KFH={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER            MOLD
   magic        ={0,        4,                COPY,              M_COPY              },
   length       ={4,        4,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   crc32        ={8,        4,                LITTLE_STRENDIAN,  M_LITTLE_STRENDIAN  },
   creation     ={12,       4,                EPOCH,             M_EPOCH             },
   last_edit    ={16,       4,                EPOCH,             M_EPOCH             },
   unknown      ={20,       4,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   creator_id   ={24,       9,                LITTLE_STRENDIAN,  M_BIG_STRENDIAN     }, -- Final NULL byte is cut off (hence the 9-length)
   parent_id    ={34,       9,                LITTLE_STRENDIAN,  M_BIG_STRENDIAN     },
   current_id   ={44,       9,                LITTLE_STRENDIAN,  M_BIG_STRENDIAN     },
   creator_name ={54,       22,               UTF16,             M_COPY              }, -- Need to write proper UTF-16 encoder.
   parent_name  ={76,       22,               UTF16,             M_COPY              },
   current_name ={98,       22,               UTF16,             M_COPY              },
   root_file    ={120,      22,               COPY,              M_COPY              },
   parent_file  ={148,      22,               COPY,              M_COPY              },
   current_file ={176,      22,               COPY,              M_COPY              },
   frames       ={204,      2,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   thumbnail    ={206,      2,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   flags        ={208,      2,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   framerate    ={210,      1,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   layer_vis    ={211,      1,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     }
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
REF.KTN={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER            MOLD
   magic        ={0,        4,                COPY,              M_COPY              },
   length       ={4,        4,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   unknown      ={8,        4,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
   jpg          ={12,       4,                COPY,              M_COPY              }
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
REF.KSN={
-- IDENTIFIER     OFFSET     LENGTH            HANDLER           MOLD
   magic        ={0,         4,                COPY,             M_COPY               },
   length       ={4,         4,                LITTLE_ENDIAN,    M_LITTLE_ENDIAN      },
   speed        ={8,         4,                COPY,             M_COPY               },
   bgm_length   ={12,        4,                LITTLE_ENDIAN,    M_LITTLE_ENDIAN      },
   se1_length   ={16,        4,                LITTLE_ENDIAN,    M_LITTLE_ENDIAN      },
   se2_length   ={20,        4,                LITTLE_ENDIAN,    M_LITTLE_ENDIAN      },
   se3_length   ={24,        4,                LITTLE_ENDIAN,    M_LITTLE_ENDIAN      },
   se4_length   ={28,        4,                LITTLE_ENDIAN,    M_LITTLE_ENDIAN      },
   bgm_data     ={32,        "bgm_length",     COPY,             M_COPY               },
   se1_data     ={"bgm_data","se1_length",     COPY,             M_COPY               },
   se2_data     ={"se1_data","se2_length",     COPY,             M_COPY               },
   se3_data     ={"se2_data","se3_length",     COPY,             M_COPY               },
   se4_data     ={"se3_data","se4_length",     COPY,             M_COPY               }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Memo Color Section -- C-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       8            Section Header                                                        header
-- 8       4            Unknown Value                                                         unknown
-- 12      remaining    Frame Data                     Format Unknown                         data
--------------------------------------------------------------------------------------------------------------------------------
REF.KMC={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER            MOLD
   magic        ={0,        4,                COPY,              M_COPY               },
   length       ={4,        4,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN      },
   unknown      ={8,        4,                COPY,              M_COPY               },
   data         ={12,       nil,              COPY,              M_COPY               }
}
--------------------------------------------------------------------------------------------------------------------------------
-- Memo Info Section -- C-BY-SA 4.0 applies to this comment block.
--------------------------------------------------------------------------------------------------------------------------------
-- OFFSET  LENGTH       CONTENT                        NOTES                                  IDENTIFIER
-- 0       .5           Unknown                                                               unknown
-- .5      .5           Paper Colour                                                          colour
-- 1       .5           Layer A colour 1                                                      lA_c1
-- 1.5     .5           Layer A colour 2                                                      lA_c2
-- 2       .5           Layer B colour 1                                                      lB_c1
-- 2.5     .5           Layer B colour 3                                                      lB_c3
-- 3       .5           Layer C colour 1                                                      lC_c1
-- 3.5     .5           Layer C colour 3                                                      lC_c3
-- 4       2            Layer A size in KMC            Unsigned Little Endian                 lA_size
-- 6       2            Layer B size in KMC            Ditto.                                 lB_size
-- 8       2            Layer C size in KMC            Ditto.                                 lC_size
-- 10      10           Frame Author ID                Null-terminated Hex(?)                 author
-- 20      1            Layer A 3D Depth               Unsigned Little Endian                 lA_3d
-- 21      1            Layer B 3D Depth               Ditto.                                 lB_3d
-- 22      1            Layer C 3D Depth               Ditto.                                 lC_3d
-- 23      1            Sound Effect Flags             To be deciphered(?)                    se_flags
-- 24      4            Camera Usage                   No: 0x0000; Yes: 0x0700;               camera
--------------------------------------------------------------------------------------------------------------------------------
-- Everything after KMI's header/length repeats itself- For REF.KMI[n] offsets every single value appearing in REF.KMI[n]
-- with by 28 bytes (meaning REF.KMI[1] holds the first frames' data- REF.KMI[2] holds the seconds frames' data, etc.).
--------------------------------------------------------------------------------------------------------------------------------
REF.KMI={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER            MOLD
   magic        ={0,        4,                COPY,              M_COPY              },
   length       ={4,        4,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
}

REF.KMI_FRAMES={
-- IDENTIFIER     OFFSET    LENGTH            HANDLER            MOLD
   unknown      ={0,        1,                MOST,              M_MOST              },
	colour       ={0,        1,                LEAST,             M_LEAST             },
	lA_c1        ={1,        1,                MOST,              M_MOST              },
	lA_c2        ={1,        1,                LEAST,             M_LEAST             },
	lB_c1        ={2,        1,                MOST,              M_MOST              },
	lB_c3        ={2,        1,                LEAST,             M_LEAST             },
	lC_c1        ={3,        1,                MOST,              M_MOST              },
	lC_c3        ={3,        1,                LEAST,             M_LEAST             },
	lA_size      ={4,        2,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
	lB_size      ={6,        2,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
	lC_size      ={8,        2,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
	author       ={10,       9,                BIG_STRENDIAN,     M_BIG_STRENDIAN     }, -- Final NULL cut off.
	lA_3d        ={20,       1,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
	lB_3d        ={21,       1,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
	lC_3d        ={22,       1,                LITTLE_ENDIAN,     M_LITTLE_ENDIAN     },
	se_flags     ={23,       1,                COPY,              M_COPY              },
	camera       ={24,       4,                BIG_ENDIAN,        M_BIT_ENDIAN        }
}

return REF;