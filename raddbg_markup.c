// Sigh. Msvc complains if we try to compile a header file, cba to fuss, just compile a c file instead.

#define RADDBG_MARKUP_STL_TYPE_VIEWS 0 // Screw you STL (this donesn't work for some reason?)
#define RADDBG_MARKUP_IMPLEMENTATION
#include "raddbg_markup.h"
