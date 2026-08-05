# Getting Started with Reia

Welcome to Reia! This guide will walk you through setting up the project step-by-step, whether you are trying out pre-alpha builds, exploring the codebase, or contributing changes.

---

## Quick Navigation

- [Prerequisites](#prerequisites)
- [Step 1: Downloading & Cloning the Repository](#step-1-downloading--cloning-the-repository)
- [Step 2: Opening the Project in Godot Engine](#step-2-opening-the-project-in-godot-engine)
- [Step 3: Rust Backend & Binary Updates](#step-3-rust-backend--binary-updates)
- [Step 4: Compiling Rust from Source (Optional)](#step-4-compiling-rust-from-source-optional)
- [Troubleshooting & Common Pitfalls](#troubleshooting--common-pitfalls)

---

## Prerequisites

Before getting started, ensure you have the following tools installed on your system:

1. **Git**: Required to download the project repository.
2. **Git LFS (Large File Storage)**: Required to download 3D models, textures, audio, and visual assets.
3. **Godot Engine 4.x**: Download standard Godot 4.x (4.7 recommended) from [godotengine.org](https://godotengine.org).
4. **Rust Toolchain (Optional)**: Only required if you intend to modify and compile code inside the `rust/` directory.

---

## Step 1: Downloading & Cloning the Repository

> **CRITICAL WARNING FOR ZIP DOWNLOADS:**  
> **Do not download this repository as a ZIP file using GitHub's "Download ZIP" button.**  
> Downloading a ZIP bypasses Git LFS and Git Submodules. As a result, all binary assets (textures, audio, 3D models) will remain 100-byte text pointer files, and essential plugins like `gecs` will be missing. This will cause errors and prevent you from starting the game.

### 1. Initialize Git LFS

Open a terminal or command prompt and run the following command once to set up Git LFS globally on your system:

```bash
git lfs install
```

### 2. Clone the Repository with Submodules

Clone the repository using the `--recursive` flag to automatically fetch submodules (such as `godot/addons/gecs`):

```bash
git clone --recursive https://github.com/Quaint-Studios/Reia.git
```

### 3. Verify LFS Assets and Submodules

Navigate into the cloned project directory:

```bash
cd Reia
```

If you previously cloned the repository without `--recursive` or without Git LFS enabled, run these commands to pull missing assets and submodules:

```bash
git submodule update --init --recursive
git lfs pull
```

---

## Step 2: Opening the Project in Godot Engine

1. Launch **Godot Engine 4.x**.
2. Click **Import** in the Project Manager.
3. Browse to the `godot/` folder inside the `Reia` repository directory (select `godot/project.godot`).
4. Click **Import & Edit** to open the project in the Godot Editor.

---

## Step 3: Rust Backend & Binary Updates

Reia utilizes a high-performance Rust backend connected to Godot via GDExtension.

### Automatic Binary Downloader

**You do not need to install Rust or compile C++/Rust code to run the game.**

When you open the project in Godot, the built-in `rust_binary_updater` plugin automatically checks for pre-compiled Rust GDExtension binaries matching your operating system (Windows `.dll`, Linux `.so`, macOS `.dylib`). If an update is needed, Godot will fetch the compiled binary from the build server automatically.

### Manual Binary Update / Hot-Swap Finalization

If Godot was actively running while an update downloaded, the OS may lock the binary file. If you see a warning in the Godot Output console about locked binaries:

1. Stop any running instances of the project.
2. In the Godot menu bar, go to **Project -> Tools -> Reia Tools -> Finalize Rust Binary Update**.
3. If files remain locked, close the Godot Editor, reopen it, and the update will complete.

---

## Step 4: Compiling Rust from Source (Optional)

If you plan to modify code inside `rust/` (such as spatial queries, networking, or database layer code), you will need to compile the Rust backend locally.

### Prerequisites for Compiling Rust

- Install the Rust toolchain via [rustup.rs](https://rustup.rs/).

### Windows Build

Run the build script from the root or `rust/` directory:

```cmd
cd rust
build.bat
```

For a release build:

```cmd
cd rust
build.bat release
```

### Linux / macOS Build

Make the script executable and run it:

```bash
cd rust
chmod +x build.sh
./build.sh
```

For a release build:

```bash
cd rust
./build.sh release
```

The script will compile the library and output the compiled binary into `godot/build/bin/`.

---

## Troubleshooting & Common Pitfalls

| Issue / Symptom                                                           | Root Cause                                                        | Solution                                                                                                                                                               |
| :------------------------------------------------------------------------ | :---------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Boot splash image fails to load; game crashes on Single Player button** | Repository downloaded as ZIP file instead of cloned with Git LFS. | Install Git LFS (`git lfs install`), then clone via terminal using `git clone --recursive https://github.com/Quaint-Studios/Reia.git`.                                 |
| **`gecs` addon directory is empty**                                       | Git submodules were not initialized during clone.                 | Run `git submodule update --init --recursive` inside the repository directory.                                                                                         |
| **"Binary locked" warning when updating Rust GDExtension**                | Active process locked the `.dll` or `.so` file during download.   | Stop running game sessions, go to **Project -> Tools -> Reia Tools -> Finalize Rust Binary Update**, or restart Godot Editor.                                          |
| **macOS Security warning ("Developer cannot be verified")**               | macOS Gatekeeper flags un-signed GDExtension dynamic libraries.   | Run `xattr -c godot/build/bin/*` in your terminal to clear extended quarantine attributes, or allow the library under macOS **System Settings -> Privacy & Security**. |
| **Unresolved script errors when opening Godot editor for the first time** | GDExtension binary downloaded but not yet indexed by Godot.       | Restart the Godot Editor once so Godot re-indexes GDExtension bindings.                                                                                                |

---

## Next Steps & Contributing

- Check out [docs/ROADMAP.md](/docs/ROADMAP.md) for planned features and tasks.
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming conventions and pull request guidelines.
- Join the community on [Discord](https://discord.playreia.com) for discussions and support.
