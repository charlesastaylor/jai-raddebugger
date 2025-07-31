AT_COMPILE_TIME :: true;

HEADER_FILE :: "raddbg_markup.h";
SOURCE_FILE :: "raddbg_markup.c";

LIB_BASE_NAME :: "lib_raddbg_markup";

entry :: (args: [] string) {
    if generate_bindings(args) {
        log("SUCCESS");
    } else {
        log("FAILURE");
    }
}

generate_bindings :: (args: [] string) -> bool {
    compile       := array_find(args, "-compile");
    compile_debug := array_find(args, "-debug");

    compile = true; // Just always compile?

    if OS != .WINDOWS {
        log_error("RAD Debugger only supports windows for now!");
        return false;
    }

    lib_directory := "windows";

    if compile {
        source_file := SOURCE_FILE;

        make_directory_if_it_does_not_exist(lib_directory, recursive = true);
        lib_path := tprint("%/%", lib_directory, LIB_BASE_NAME);

        extra: [..] string;
        // array_add(*extra, "-DRADDBG_MARKUP_IMPLEMENTATION")

        success := true;
        // I don't think it makes sense for us to run at compile time, so no dynamic lib. Also means we don't have to deal with the
        // fact the functions we care about aren't marked as export!
        // success &&= build_cpp_dynamic_lib(lib_path, source_file, debug = compile_debug, extra = extra);
        success &&= build_cpp_static_lib(lib_path, source_file, debug = compile_debug, extra = extra);

        if !success  return false;
    }

    options: Generate_Bindings_Options;
    {
        using options;

        array_add(*library_search_paths, lib_directory);
        array_add(*libraries, .{filename=LIB_BASE_NAME});
        array_add(*source_files, HEADER_FILE);

        generate_library_declarations = true;
        // footer = tprint(FOOTER_TEMPLATE, LIB_BASE_NAME);

        auto_detect_enum_prefixes = true;
        log_stripped_declarations = true;
        generate_compile_time_struct_checks = false;
        generate_printf_wrappers = false; // I am doing this print stuff directly in the module code for now. Maybe bit silly and should just use these...

        header = "#scope_module"; // Don't actually want to export any of the bindings.
    }

    output_filename := "bindings.jai";
    return generate_bindings(options, output_filename);
}

#import "Basic";
#import "Bindings_Generator";
#import "BuildCpp";
#import "Compiler";
#import "File";
// #import "Process";
#import "String";

#if AT_COMPILE_TIME {
    #import "Compiler";
    #run {
        set_build_options_dc(.{do_output=false});
        options := get_build_options();
        args := options.compile_time_command_line;
        entry(args);
    }
} else {
    #import "System";
    main :: () {
        args := get_command_line_arguments();
        if args {            
            // @Hack At runtime the first argument is the name of exectuable, at compile time it's not, skip over it here.
            basename := path_basename(#location().fully_pathed_filename);

            if path_basename(args[0]) == basename {
                args.data  += 1;
                args.count -= 1;
            }
        }
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        entry(args);
    }
}
