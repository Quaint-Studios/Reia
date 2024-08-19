const std = @import("std");
const Godot = @import("godot");
const builtin = @import("builtin");
const GPA = std.heap.GeneralPurposeAllocator(.{});

var gpa = GPA{};

pub export fn my_extension_init(p_get_proc_address: Godot.GDExtensionInterfaceGetProcAddress, p_library: Godot.GDExtensionClassLibraryPtr, r_initialization: [*c]Godot.GDExtensionInitialization) Godot.GDExtensionBool {
    const allocator = gpa.allocator();
    return Godot.registerPlugin(p_get_proc_address, p_library, r_initialization, allocator, &init, &deinit);
}

fn init(_: ?*anyopaque, p_level: Godot.GDExtensionInitializationLevel) void {
    if (p_level != Godot.GDEXTENSION_INITIALIZATION_SCENE) {
        return;
    }

    const ExampleNode = @import("ExampleNode.zig");
    Godot.registerClass(ExampleNode);
}

fn deinit(_: ?*anyopaque, p_level: Godot.GDExtensionInitializationLevel) void {
    if (p_level == Godot.GDEXTENSION_INITIALIZATION_CORE) {
        _ = gpa.deinit();
    }
}
