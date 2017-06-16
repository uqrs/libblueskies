# libblueskies
## Overview
Hopefully a tool to turn DSi Flipnote Studio 3D flips into something a regular PC can display.
Why's it called libblueskies? Well, my initial motivation for making this tool was to deserialise all of [mellowforests'](http://mellowforests.deviantart.com/) (previously known as 'Blueskies') flipnotes. And it's better than... "deflippifier".
### Depencencies:
- Lua 5.3 or higher.
- ffmpeg, probably.

### Goals:
- Implement src/indices.lua properly.
- Finish the binding function.
- Parse/store the other headers.
- Obviously, we need to decipher whatever kind of video format .kwz files utilise to display content to the screen.
- Write an ffmpeg pseudo-api.

## Licensing and attribution.
The entirety of this repository is registered under the GNU GPL v3.0+ (see `LICENSE` for details), **EXCEPT FOR:**

### flipnote-collective
the [Flipnote Collective](http://github.com/Flipnote-Collective/) have done an absolutely amazing job at documenting the various aspects of Flipnote Hatena 3Ds'
workings. They have written extensive documentation on the subject [here](http://github.com/Flipnote-Collective/flipnote-studio-3d-docs).
Currently, `src/indices.lua` semi-directly rips some of the lookup tables and information they have on display. The lookup
tables in this file are registered under a [**Creative Commons Attribution-ShareAlike 4.0 International License**](https://creativecommons.org/licenses/by-sa/4.0/).
This is noted in the aforementioned file as well.

### mellowforests' samples
The flipnotes used for samples/analysing in `sample/` belong to [mellowforests on deviantart](http://mellowforests.deviantart.com/)
and [youtube](https://www.youtube.com/user/Blueskiez14) ("Z", Zara, etc.). The animations (but not the music or sound) contained within belong to them (even if nobody can actually see them
appropriately, yet.) When redistributing these for any reason whatsoever- attribute these to [mellowforests](http://mellowforests.deviantart.com/).
You shall not claim these for yourself.