
ENABLED :: true;
#import,dir "../RAD_Debugger"()(ENABLED);

// @TODO: sequence(), table(), other fancy stuff?

main :: () {
    print("I am the main (man)\n");
    fake_main();
}

#run raddbg_entry_point(fake_main); // Mark fake_main as where RAD should break when you "step in" to the program.

fake_main :: () {
    print("I am a total phoney main\n");

    rad_mode := raddbg_is_attached();

    raddbg_thread_name("Jai is cool");
    raddbg_thread_color(0.23, 0.93, 0.34, 1);

    if rad_mode {
        print("RAD_Debugger is attached!\n");
    } else {
        print("Running without the RAD_Debugger, why even bother bro.\n");
    }

    raddbg_log("Hello Mr Debugger! % % %", 123, 1.23, "123");

    static_string := "I am null terminated!";
    dynamic_string := copy_string(static_string);

    temporary_string := tprint("Wtf % % %", 1, 1.2, true);

    long_string := A_REALLY_LONG_STRING; // raddbg_pin(text(array(long_string.data, long_string.count)))

    a := string.{3, static_string.data};
    b := string.{3, static_string.data + 5};

    ints: [5] int;
    for *ints  it.* = it_index;

    dynamic_ints: [..] int;
    for 1..10  array_add(*dynamic_ints, it);

    dynamic_strings: [..] string;
    array_add(*dynamic_strings, "Apples And Stuff To Make A Long String");
    array_add(*dynamic_strings, "Pears");
    array_add(*dynamic_strings, "Peaches");
    array_add(*dynamic_strings, "Bums");

    aa := array_view(dynamic_ints, 0, 3);
    ba := array_view(dynamic_ints, 5, 3);

    image_data : [] u8 = IMAGE_DATA;
    bitmap: Bitmap;
    if image_data {
        bitmap_load_from_memory(*bitmap, image_data);

        bitmap.stride = 2;
    }

    u128: U128;
    u128.low  = 0xCAFEBABECAFEBABE; // Maybe there is some encantation that will be useful, closest I got was:
    u128.high = 0xDEADBEEFDEADBEEF; // raddbg_pin(hex(array((u8*)(&u128), 16)))

    s128 := to_s128(-999393);

    v2 := Vector2.{1, 2};
    v3 := Vector3.{1, 2, 3};
    v4 := Vector4.{1, 2, 3, 4};

    q := Quaternion.{1, 2, 3 , 4};
    normalize_or_identity(*q); // Might as well make it pwopa!

    baby_matrix:       Matrix2;
    mother_matrix:     Matrix3;
    father_matrix:     Matrix4;
    goldilocks_matrix: Matrix4x3;
    for 0..3   baby_matrix.floats[it]       = xx it;
    for 0..8   mother_matrix.floats[it]     = xx it;
    for 0..15  father_matrix.floats[it]     = xx it;
    for 0..11  goldilocks_matrix.floats[it] = xx it;


    // Discriminated union test. (Jai has modules/Tagged_Union, but getting that to work would be a lot more involved / maybe not possible).
    scary_monster := Entity.{kind = .MONSTER, monster.teeth_count = 153, monster.scariness = 9001.123};
    tulip         := Entity.{kind = .FLOWER,  flower.name = "tulip", flower.petal_count = 6, flower.color = .{0.91, 0.16, 0.18, 1}};
    
    // A more real use case of the discriminated union thing, Jai Type_Infos!
    {
        test_procedure :: (a: int, b := 12.3) -> bool, string #no_context { return true, ""; }

        // The compiler automatically returns pointers of the relevant Type_Info_*, but we specifically want just *Type_Info here, so we
        // see the type view do the cast for us.
        ti_integer   : *Type_Info = type_info(s32);
        ti_float     : *Type_Info = type_info(float);
        ti_string    : *Type_Info = type_info(string);
        ti_pointer   : *Type_Info = type_info(*s32);
        ti_procedure : *Type_Info = type_info(type_of(test_procedure));
        ti_struct    : *Type_Info = type_info(Entity);
        ti_array     : *Type_Info = type_info([..] int);
        ti_enum      : *Type_Info = type_info(Type_Info_Tag);
        // Variant?

        #import "Compiler";
        type_table := get_type_table();

        print("Types Are Thriving\n"); // So we can step to the end of the scope, Sadge.
    }


    example_color_u32: u32 = 0xff6f30ff; // raddbg_pin(color(example_color_u32))

    red: Vector4; // raddbg_pin(color(red.component))
    red.w = 1.;
    red.x = 0.89;
    red.y = 0.12;
    red.z = 0.23;

    //- rjf: booleans (checkboxes)
    bool1 := true;  // raddbg_pin(bool1)
    bool2 := false; // raddbg_pin(bool2)
    bool3 := true;  // raddbg_pin(bool3)

    //- rjf: sliders
    slide1 : float32 = 500.; // raddbg_pin(range1(slide1, 0, 1000))
    slide2 : float64 = 0.75; // raddbg_pin(range1(slide2, 0, 1.0))
    slide3 : int     = 25;   // raddbg_pin(range1(slide3, 0, 100))

    // Memory annotation
    some_block_of_memory := alloc(256);
    memset(some_block_of_memory, 0x24, 256);
    raddbg_annotate_vaddr_range(some_block_of_memory, 256, "0x24 is the highest number");

    // Add/remove breakpoint.
    {
        x := 0;
        raddbg_add_breakpoint(xx *x, size_of(type_of(x)), 0, 1, 0);
        for 0..10000-1 {
            if it == 5000 {
                x += 1; // We should hit this as a breakpoint if things are functioning correctly.
            }
        }
        raddbg_remove_breakpoint(xx *x, size_of(type_of(x)), 0, 1, 0);
    }

    // Break at the end to look at stuff.    
    raddbg_break_if(rad_mode);

    print("Done.\n");
}

// Have to define the type down here, because if it's inside main it gets namespaced to that function and more awkward to get type
// name correct!
Entity :: struct {
    kind: enum {
        MONSTER;
        FLOWER;
    };

    union {
        monster: struct {
            teeth_count: int;
            scariness: float;
        } 

        flower: struct {
            name: string;
            petal_count: int;
            color: Vector4;
        }
    }
}
#run raddbg_type_view(Entity, "kind == 0 ? monster : rows(flower, name, petal_count, color(color.component))");

A_REALLY_LONG_STRING :: #string DONE
Now We Are Six

When I was One,
I had just begun.
When I was Two,
I was nearly new.
When I was Three
I was hardly me.
When I was Four,
I was not much more.
When I was Five,
I was just alive.
But now I am Six,
I'm as clever as clever,
So I think I'll be six now for ever and ever.

- A. A. Milne
DONE

IMAGE_DATA :: #run -> [] u8 {
    #import "Compiler";
    #import "File";
    #import "File_Utilities";

    data: [] u8;

    RELATIVE_PATH :: "examples/invaders/data/ship.png";
    image_path := tprint("%/%", compiler_get_base_path(), RELATIVE_PATH);
    if !file_exists(image_path) {
        log_error("Failed to find test image at '%'", image_path);
    } else {
        data_string, success := read_entire_file(image_path);
        assert(success);
        data = xx data_string;
    }
    
    return data;
}

#import "Basic";
#import "Math";
#import "Simp";
