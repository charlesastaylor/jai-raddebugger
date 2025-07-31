//
// This file was auto-generated using the following command:
//
// jai generate.jai
//
#scope_module


RADDBG_MARKUP_DEFAULT_VSNPRINTF :: 1;

RADDBG_MARKUP_STL_TYPE_VIEWS :: 1;

raddbg_is_attached__impl :: () -> s32 #foreign lib_raddbg_markup;
raddbg_thread_id__impl :: () -> s32 #foreign lib_raddbg_markup;
raddbg_thread_name__impl :: (id: s32, fmt: *u8, __args: ..Any) -> void #foreign lib_raddbg_markup;
raddbg_thread_color__impl :: (id: s32, hexcode: u32) -> void #foreign lib_raddbg_markup;
raddbg_watch__impl :: (fmt: *u8, __args: ..Any) -> void #foreign lib_raddbg_markup;
raddbg_log__impl :: (fmt: *u8, __args: ..Any) -> void #foreign lib_raddbg_markup;
raddbg_add_or_remove_breakpoint__impl :: (ptr: *void, set: s32, size: s32, r: s32, w: s32, x: s32) -> void #foreign lib_raddbg_markup;
raddbg_annotate_vaddr_range__impl :: (ptr: *void, size: u64, fmt: *u8, __args: ..Any) -> void #foreign lib_raddbg_markup;

#scope_file

lib_raddbg_markup :: #library,no_dll "windows/lib_raddbg_markup";
