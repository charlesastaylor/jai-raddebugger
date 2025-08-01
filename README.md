# RAD Debugger markup integration module

The RAD Debugger provides [lib_raddbg_markup](https://github.com/EpicGamesExt/raddebugger/blob/master/src/lib_raddbg_markup/raddbg_markup.h) that lets you do various integration with the debugger form your source code. This module lets you do that stuff from jai. My primary motivation for doing this was to be able to define "type views" for jai types in code, without having to enter them into the debugger ui.

To get started you can compile the example program `jai example.jai -x64` and run it in the debugger. For more information see:
- The `raddbg_readme.md` that is included in RAD Debugger release, or output to build directory.
- The `mule_main` example program shipped with the RAD Debugger. This can be built with `build.bat mule_main mule_module mule_hotload`

Tested with RAD Debugger v0.9.20-alpha.

## Latest

This branch is kept up to date with `raddebugger/master`. Latest commit `25963dc9b40a4c357c5240da156a57e6a0ee2cca`. It has a number of fixes over the v0.9.20-alpha version.

I'm not sure how much I want to be in the business of maintaining branches... for now we are doing this though.
