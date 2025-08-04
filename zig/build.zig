const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const dylib = b.addSharedLibrary(.{
        .name = "reia",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const godot = b.dependency("godot", .{
        .optimize = optimize,
        .target = target,
    });
    const godot_module = godot.module("godot");
    dylib.root_module.addImport("godot", godot_module);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.install_prefix = "../godot/lib";
    b.lib_dir = "./godot/lib";
    b.exe_dir = "./godot/lib";
    b.installArtifact(dylib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.root_module.addImport("godot", godot_module);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests with Godot");
    test_step.dependOn(&run_lib_unit_tests.step);

    /////////////////////////////////////////////////

    // b.lib_dir = "../godot/lib";
    // b.installArtifact(lib);

    // const run_cmd = b.addSystemCommand(&.{
    //     godot_path, "--path", "../godot",
    // });

    // run_cmd.step.dependOn(b.getInstallStep());
    // const run_step = b.step("run", "Run with Godot");
    // run_step.dependOn(&run_cmd.step);

    // const run_tests = b.addRunArtifact(tests);
    // run_tests.has_side_effects = true;
    // run_tests.step.dependOn(b.getInstallStep());
    // const test_step = b.step("test", "Run tests with Godot");
    // test_step.dependOn(&run_tests.step);
}
