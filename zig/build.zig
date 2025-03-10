const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const godot_path = b.option([]const u8, "godot", "Path to Godot engine binary [default: `godot`]") orelse "godot";

    const lib = b.addSharedLibrary(.{
        .name = "reia",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .name = "test",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .test_runner = b.path("test_runner.zig"),
    });

    const godot_zig_build = @import("./godot-zig/build.zig");
    const godot = godot_zig_build.createModule(b, target, optimize, godot_path);

    lib.root_module.addImport("godot", godot);
    tests.root_module.addImport("godot", godot);

    // use explicit imports to make jump work properly
    // todo: remove this once zls get improved
    var iter = godot.import_table.iterator();
    while (iter.next()) |it| {
        lib.root_module.addImport(it.key_ptr.*, it.value_ptr.*);
        tests.root_module.addImport(it.key_ptr.*, it.value_ptr.*);
    }
    /////////////////////////////////////////////////

    b.lib_dir = "../godot/lib";
    b.installArtifact(lib);

    const run_cmd = b.addSystemCommand(&.{
        godot_path, "--path", "../godot",
    });

    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run with Godot");
    run_step.dependOn(&run_cmd.step);

    const run_tests = b.addRunArtifact(tests);
    run_tests.has_side_effects = true;
    run_tests.step.dependOn(b.getInstallStep());
    const test_step = b.step("test", "Run tests with Godot");
    test_step.dependOn(&run_tests.step);
}
