# Reia
## This section utilizes godot-zig to take advantage of Zig.

Zig version: `0.13.0`
Godot version: `4.3`

Use cases:
- Custom NetCode
- PostgreSQL for authentication
- Turso/LibSQL for online / offline database

## Building

### Requirements

You'll need Godot installed on your machine. You'll also need to find a way to enable using it via your CLI. On Windows I found the installation path of Godot (I use Steam to manage it). Then I added a `godot.cmd` file in that directory with the following content inside of it:

```bat
@echo off
godot.windows.opt.tools.64.exe /u %*
```

This will run the executable that's in the same directory. And because the name is `godot.cmd`, I can use `godot` in PowerShell and Command Prompt. I haven't tried this on Linux yet. But creating an alias and setting it up in `~/.bashrc` should be the standard solution there.

Just a heads up. On Windows, your computer won't know to look in that folder for the .cmd file if it's not in your environment variables. So don't forget to add that too. Then you're done. Oh, and if you're frustrated about your terminal not updating the environment variable, just type `refreshenv`. It's a command that will do exactly what you think it says.

### Binding

Now that you have Godot, you should first try opening the project. I saw some issues when trying to bind *before* opening Reia. But that could just be me.


**Working Directory: `./Reia/zig`**
```sh
godot -e --path ../godot
```

This will, from the zig folder, go to the parent folder and inside of the godot folder and open the project to generate the proper files.

**Working Directory: `./Reia/zig`**
```sh
zig build bind
```

If everything works, you're set. You can run `zig build run` and it should start Reia automatically.
