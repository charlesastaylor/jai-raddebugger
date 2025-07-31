//
// RAD Debugger markup integration (lib_raddbg_markup) module. Tested against release v0.9.20-alpha.
//
// This only works with the x64 backend atm. See the comment on Compiler.add_data_segment for why, as well as :RadSectionIssue
//
// @Incomplete: Calling any of the procs that call into the c library at compile time will crash your program. There should be someway to mitigate this (without having to compile a dll that makes no sense to exist)
// @Incomplete: Is there any reason to have these @PrintLike s? We could just take a string, and then the user can tprint if they want to? For the thread stuff I started doing this, one thing is we have to temp_c_string stuff to be sure. Hmm..

// NOTE(Charles): Atm I generate a static lib and bindings. The library, a single header lib in raddbg_markup.h, is not a lot
// of code so it would better to have a jai port, we could then even be a single file module. I chose to start with using a library 
// because 1) I wasn't 100% I could do the necessary SEH stuff from jai, and 2) maybe it'll save sometime maintaining the jai version while
// the rad debugger is still in active development.

#module_parameters()(ENABLED := true, DEFINE_TYPE_VIEWS_FOR_COMMON_JAI_TYPES := true);

#if ENABLED {

    // NOTE(Charles): This is currently broken if you use any raddbg_type_view, or raddbg_entry_point. I opened an issue which was fixed
    // same day. Not bad if you ask me. So on next release this will work!
    raddbg_is_attached :: () -> bool #expand #no_debug #no_context {
        return cast(bool, raddbg_is_attached__impl());
    }

    raddbg_thread_id :: () -> s32 #expand {
        return raddbg_thread_id__impl();
    }

    raddbg_thread_name :: (name: string) #expand {
        name_c := temp_c_string(name);
        raddbg_thread_name__impl(raddbg_thread_id(), name_c);
    }

    raddbg_thread_id_name :: (id: s32, name: string) #expand {
        name_c := temp_c_string(name);
        raddbg_thread_name__impl(id, name_c);
    }

    raddbg_thread_color :: (color: u32) #expand {
        raddbg_thread_color__impl(raddbg_thread_id(), color);
    }

    raddbg_thread_color :: (r: float, g: float, b: float, a: float) #expand {
        raddbg_thread_id_color(raddbg_thread_id(), r, g, b, a);
    }

    raddbg_thread_id_color :: (id: s32, color: u32) #expand {
        raddbg_thread_color__impl(id, color);
    }

    raddbg_thread_id_color :: (id: s32, r: float, g: float, b: float, a: float) #expand {
        color: u32;
        color |= cast(u32, r * 255) << 24;
        color |= cast(u32, g * 255) << 16;
        color |= cast(u32, b * 255) <<  8;
        color |= cast(u32, a * 255) <<  0;
        
        raddbg_thread_color__impl(id, color);
    }

    raddbg_break    :: debug_break;
    raddbg_break_if :: (condition: bool) #expand { if condition  raddbg_break(); }

    raddbg_watch :: (format: string, args: ..Any) #expand {
        #assert false "raddbg_watch is not implemented in the debugger yet!";
    } @PrintLike

    // raddbg_pin can be used to automatically pin variables in debuggers source viewer, with optional extra formatting. In c this is just an
    // empty macro and it's the debugger ui that interprets the expression as a string. Jai macros don't work that way so we don't implement
    // this, you can still use the pins by just putting it in a comment.
    // raddbg_pin :: (expr: string) #expand {}
    
    raddbg_log :: (format: string, args: ..Any) #expand {
        push_allocator(temp);
        formatted_text_builder: String_Builder;
        print_to_builder(*formatted_text_builder, format, ..args);
        append(*formatted_text_builder, "\0");
        formatted_text := builder_to_string(*formatted_text_builder);

        raddbg_log__impl("%s", formatted_text.data); // This just calls OutputDebugStringA, we may as well just do that directly?
    } @PrintLike

    // Similar story to raddbg_type_view, see the comment there.
    raddbg_entry_point :: (procedure_code: Code, loc := #caller_location) -> [] u8 #compile_time {
        nodes := compiler_get_nodes(procedure_code);
        if nodes.kind != .IDENT {
            compiler_report(tprint("raddbg_entry_point: Invalid paramter. Expected Code of kind IDENT, but got %", nodes.kind));
        }

        ident := cast(*Code_Ident, nodes);
        if ident.type.type != .PROCEDURE {
            compiler_report(tprint("raddbg_entry_point: Invalid paramter. Expeceted a procedure identifier but got an identifer of type % (with name %)", ident.type.type, ident.name));
        }

        // These error checks might not cover all ways you could miss call this?

        segment := raddbg_get_data_segment(loc);

        entry_point_data := tprint("entry_point: \"%\"\0", ident.name);

        result := add_global_data(xx entry_point_data, .USER_SEGMENT, segment);
        return result; // Is there any reason to return the data?
    }

    // In C, this macro is implemented like
    /*
    #pragma section(".raddbg", read, write)
    #define raddbg_exe_data __declspec(allocate(".raddbg"))

    #define raddbg_type_view(type, ...) raddbg_exe_data char <slot_name>[] = ("type_view: {type: ```" #type "```, expr: ```" #__VA_ARGS__ "```}")
    */
    // In jai the way this needs to be done is quite different. We have to call Compiler procedures at compile time.
    // So to use this you have to #run raddbg_type_view. 
    raddbg_type_view :: (type: Type, view_expression: string, loc := #caller_location) -> [] u8 #compile_time #expand {
        type_string := tprint("%", type); // Dumb.
        return raddbg_type_view(type_string, view_expression, loc);
    }
    
    // To define on polymorphic types we have to just use strings sadge.
    raddbg_type_view :: (type_string: string, view_expression: string, loc := #caller_location) -> [] u8 #compile_time {
        segment := raddbg_get_data_segment(loc);

        type_view_expression := tprint("type_view: {type: ```%```, expr: ```%```}\0", type_string, view_expression);

        result := add_global_data(xx type_view_expression, .USER_SEGMENT, segment);
        return result; // Is there any reason to return the data?
    }

    // Maybe we should polymorph the ptr parameters? Could also jaiify the other parameters?

    raddbg_add_breakpoint :: (ptr: *void, size: s32, r: s32, w: s32, x: s32) #expand {
        raddbg_add_or_remove_breakpoint__impl(ptr, 1, size, r, w, x);
    }

    raddbg_remove_breakpoint :: (ptr: *void, size: s32, r: s32, w: s32, x: s32) #expand {
        raddbg_add_or_remove_breakpoint__impl(ptr, 0, size, r, w, x);
    }

    raddbg_annotate_vaddr_range :: (ptr: *void, size: u64, fmt: string, args: ..Any) #expand {
        push_allocator(temp);
        formatted_text_builder: String_Builder;
        print_to_builder(*formatted_text_builder, fmt, ..args);
        append(*formatted_text_builder, "\0");
        formatted_text := builder_to_string(*formatted_text_builder);

        raddbg_annotate_vaddr_range__impl(ptr, size, "%s", formatted_text.data); // Is there any reason to not just pass the preformatted string as the string variable? I feel like there is a reason why that can be bad, but I forget...
    } @PrintLike

    #load "bindings.jai";
} else {
    raddbg_is_attached :: () -> bool #expand #no_debug #no_context { return false; }

    raddbg_thread_id :: () -> s32 #expand {}
    raddbg_thread_name     :: (#discard name: string) #expand {}
    raddbg_thread_id_name  :: (#discard id: s32, #discard name: string) #expand {}
    raddbg_thread_color    :: (#discard color: u32) #expand {}
    raddbg_thread_color    :: (#discard r: float, #discard g: float, #discard b: float, #discard a: float) #expand {}
    raddbg_thread_id_color :: (#discard id: s32, #discard color: u32) #expand {}
    raddbg_thread_id_color :: (#discard id: s32, #discard r: float, #discard g: float, #discard b: float, #discard a: float) #expand {}

    raddbg_break :: () #expand {}
    raddbg_break_if :: (#discard condition: bool) #expand {}

    raddbg_watch :: (#discard format: string, #discard args: ..Any) #expand {}
    // raddbg_pin :: (#discard expr: string) #expand {}
    raddbg_log :: (#discard fmt: string, #discard args: ..Any) #expand {}

    raddbg_entry_point :: (#discard procedure_code: Code) -> [] u8 #compile_time { return .[]; }
    raddbg_type_view :: (#discard type: Type,          #discard view_expression: string) -> [] u8 #compile_time { return .[]; }
    raddbg_type_view :: (#discard type_string: string, #discard view_expression: string) -> [] u8 #compile_time { return .[]; }
    
    raddbg_add_breakpoint    :: (#discard ptr: *void, #discard size: s32, #discard r: s32, #discard w: s32, #discard x: s32) #expand {}
    raddbg_remove_breakpoint :: (#discard ptr: *void, #discard size: s32, #discard r: s32, #discard w: s32, #discard x: s32) #expand {}
    raddbg_annotate_vaddr_range :: (#discard ptr: *void, #discard size: u64, #discard fmt: string, #discard args: ..Any) #expand {}
}



#scope_file

#if ENABLED {
    #import "Basic";
    #import "Compiler";

    raddbg_get_data_segment :: (loc: Source_Code_Location) -> *Data_Segment #compile_time {
        if !raddbg_segment {
            raddbg_segment=, will_be_created := add_data_segment(".raddbg", .READ | .WRITE);
            if !will_be_created {
                // Hmm, despite what comments in the add_data_segment.jai example say, there does seem to be a .raddbg
                // section in the executable when compiling with llvm backend, but the data doesn't seem to be put there?
                // `dumpbin /secttion:.raddbg example.exe` shows a section with virtual size 1? :RadSectionIssue
                compiler_report("[RAD_Debugger] Failed to create the data segment required for RAD Debugger type views and custom entry point! Probably you are using the LLVM back end, and this only works with X64 atm.", loc = loc, mode = .WARNING);
            }
        }
        assert(raddbg_segment != null);

        return raddbg_segment;
    }

    // We only want to create one section, so we need to keep a reference to this, but this means there will then be a global in
    // the users program, hmm.
    raddbg_segment: *Data_Segment;
}

#if ENABLED && DEFINE_TYPE_VIEWS_FOR_COMMON_JAI_TYPES {
    // NOTE(Charles): These views can hide fields you may need to look at, you can add a watch "raw(my_variable)" in that case.

    #run raddbg_type_view(bool, "bool($)");

    
    // String

    // #run raddbg_type_view(string, "array(data, count)");
    #run raddbg_type_view(string, "no_addr(array(data, count)"); // Hides the pointer value, maybe you do want the pointer sometimes though?

    // For longer strings or text with line breaks, text(..) might be useful (even though text seems to be mainly intended for source code?).
    // I tried to check on the length of string to do different things but had issues.
    // @TODO(Charles): Using the slice($) version you can see it correctly doing two different things based on value of count, but with the top one both
    // strings are treated the same?! Report/look at code
    // raddbg_type_view(string, count < 25 ? no_addr(array(data,count)) : text(array(data, count)));
    // raddbg_type_view(string, count < 25 ? slice($) : text(array(data, count)));


    // Dynamic arrays and array views. (Static arrays are fine by default)

    #run raddbg_type_view("[] ?", "rows($, count, array(data, count))");

    // How many of the extra dynamic array fields are worth viewing? Take your pick.
    // #run raddbg_type_view("[..] ?", "array(data, count)");                // Just show the items
    #run raddbg_type_view("[..] ?", "rows($, count, array(data, count))");   // Show the count, then the items
    // #run raddbg_type_view("[..] ?", "rows($, count, allocated, allocator, allocator_data, array(data, count))"); // Show the whole shebang, then the items

    // @TODO(Charles): When just doing the items, there was an issue where the count would be the count of the first string in the array.
    // I think this is a bug in the debugger? It probably also applies to any type that has a "count" member? Report/look at code.
    // #run raddbg_type_view([..] string, "array(data, count)"); //

    
    #import "Simp";

    // Probably don't want the bitmap() view if stride != bpp*width, but all my attempts at using type view conditional operators have failed...
    #run raddbg_type_view(Bitmap, "rows($, width, height, stride, mipmap_count, flags, format, bitmap(data.data, width, height)");

    
    #import "Math";

    #run raddbg_type_view(Vector2, "rows($, x, y)");
    #run raddbg_type_view(Vector3, "rows($, x, y, z)");
    #run raddbg_type_view(Vector4, "rows($, x, y, z, w)");

    #run raddbg_type_view(Matrix2, "columns($.coef, $[0], $[1]");
    #run raddbg_type_view(Matrix3, "columns($.coef, $[0], $[1], $[2]");
    #run raddbg_type_view(Matrix4, "columns($.coef, $[0], $[1], $[2], $[3])");
    #run raddbg_type_view(Matrix4x3, "columns($.coef, $[0], $[1], $[2], $[3]");        
}
