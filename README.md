# Maze HyperCube — local Rust desktop port

Native Windows and Linux desktop edition of Peter Kramer's Maze HyperCube. The supplied [Objective-C controller](reference/ios/Play%20Page%20-%20Objective%20C.m) is the behavioral reference. No Python, server, browser, or network connection is needed to play. All 100 maze numbers per size and complexity are available, with no two-maze limit.

## Play

**Windows:** extract the supplied `maze-hypercube-windows.zip`, then double-click `hypercube-maze.exe` inside the extracted folder. Local delivery archives are kept in `dist/` and excluded from Git. The packaged executable needs no additional runtime DLLs. Rust is not required on the owner's machine. To build from a clone, see [Build and verify](#build-and-verify).

**Linux / WSLg:** run `./run.sh`, or open the packaged binary in `dist/linux/`. Run `./install-desktop.sh` to add Maze HyperCube to the desktop application menu. Source builds need Rust 1.95+ and a C linker. The Linux sound uses the local PulseAudio server; WSLg supplies it.

- Drag inside the left or right maze view to move in that view. Click either view to toggle a marker at your current four-dimensional cell.
- Arrow keys move in the left X/Y view; WASD moves in the right W/Z view. Space toggles a marker.
- `B` alternates showing and making the best move. Hold the best-move button to start automatic movement; press it again to stop.
- `R` restarts the same maze and keeps markers. `N` or Next Maze selects the next maze and clears markers.
- Porous Walls allows crossing internal walls, while outer boundaries still block movement. Moves shows the number of steps remaining. Portals shows passages into the other plane.
- Select changes shape, dimensions, maze number, complexity, and sound. Click adjacent wheel rows, drag a wheel, or use the mouse wheel. Escape, Play, or an outside click returns to play.

Maze shape and dimension names follow the original app: displayed X/Y/Z/W correspond to controller W/Z/Y/X. Both views always show the same position. Green is the entrance; blue is the exit. Your position is the smaller blue disk. White dots are your markers.

The timer pauses in Home, Select, and while the window is unfocused, and stops at the exit. Settings, position, time, markers and completion count save automatically every two seconds and on normal exit. Save location:

- Windows: `%LOCALAPPDATA%\hypercube-maze\game.json`
- Linux: `${XDG_DATA_HOME:-~/.local/share}/hypercube-maze/game.json`

Set `HYPERCUBE_MAZE_STATE` to an alternate file for an isolated session. Invalid saves are reported without overwriting them.

## Fidelity and scope

The generation engine preserves the version-620 seed formula, [Apple libc random sequence](https://github.com/apple-oss-distributions/Libc/blob/main/stdlib/FreeBSD/rand.c), two discarded initial random values, single-precision arithmetic, .99 random cap, frontier ordering and swap removal, Complex bias, reciprocal walls, and exact exit distances. Play behavior preserves all eight moves, porous walls, marker toggling, restart, number cycling, shape constraints, entrance/exit, remaining-move display, portals, colors and hint acceleration.

Play and Select appearance were reconstructed from the controller and the [official App Store iPad screenshots](https://apps.apple.com/us/app/maze-hypercube-lite/id378658863). The pictured 4D maze matches the older `210` seed mentioned in the controller comments (all 17 visible internal walls and its remaining-move count); the port uses the supplied controller's current `620` seed. Source-defined 10-point button corners and 13-point bold segmented labels with black selected text are preserved. Fonts and controls are desktop implementations; the owner did not have `QuartzFunView`, nib/storyboard, other controllers or `tap11.aiff`. This prevents claiming pixel-for-pixel or sound-for-sound identity. A synthesized click substitutes for the absent audio. Home contains local play instructions because its original implementation was not supplied.

As requested, this desktop edition exposes all 100 maze numbers per size and complexity, with no two-maze limit. It does not reproduce iOS purchases, receipt verification, purchase prompts, device licensing or review offers. The original Lite edition permits two maze numbers before upgrading. No payment service is simulated. macOS packaging is not included.

The original source and failed Python attempts are retained as references. The executable uses Rust only. Icon and app screenshots come from the owner's public App Store listing. Embedded Liberation Sans fonts are covered by `assets/fonts/LICENSE.txt`; the app/source owner retains their existing rights.

## Repository layout

- `src/` — native Rust application, rendering, maze generation, state and audio.
- `assets/` — embedded fonts, font license and app icon.
- `tests/` — original-controller parity and native desktop smoke checks.
- `reference/ios/` — supplied Objective-C controller and generation notes.
- `reference/python/` — historical conversion attempts, preserved for reference.
- `docs/porting-notes.md` — behavioral mapping, verification and original-asset research.

Build outputs (`target/`, `dist/`), test captures (`verification/`) and local test saves (`.local-state/`) are excluded from Git.

## Build and verify

```sh
cargo build --locked --release
cargo test --locked
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
```

The parity test extracts the actual generation methods from the supplied controller, compiles them as C, and compares every wall and distance for 104 cases: 13 sizes/shapes, numbers 1/2/37/100, and both Standard/Complex. Gameplay tests cover blocked and porous moves, outer boundaries, best-move solving and completion, all shape rules, marker retention/clearing, number wrapping, save/load, invalid saved positions, fractional-frame timer accuracy, and hint release/repress/automatic timing. Native pointer checks include tiny drags, exact diagonals and stationary clicks. The Select UI test reaches maze 100 without a purchase and wraps back to 1.

The native input smoke test requires an isolated X11 display, `libXtst`, and Pillow:

```sh
Xvfb :99 -screen 0 1100x1000x24 -nolisten tcp
# In another terminal:
DISPLAY=:99 python3 tests/ui_smoke.py target/debug/hypercube-maze
```

`tests/ui_smoke.py` drives the real window and writes screenshots and isolated saved state under the ignored `verification/` directory. Python is used only for this optional test harness.

On Windows, install Rust's MSVC toolchain and the Visual Studio C++ build tools, then `cargo build --locked --release`. To cross-build from Linux, install MinGW-w64 and `rustup target add x86_64-pc-windows-gnu`, then:

```sh
CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
  cargo build --locked --release --target x86_64-pc-windows-gnu
```

For reproducible checks, `--dump X Y Z W NUMBER COMPLEX` prints each cell's wall mask and exit distance in controller array order. Here X/Y/Z/W are the *internal controller* dimensions, and COMPLEX is 0 or 1.

Windows native smoke check (PowerShell):

```powershell
.\tests\windows_smoke.ps1 -Executable C:\path\hypercube-maze.exe -OutputDirectory C:\path\verification
```

Use a local Windows drive for this check; launching from a WSL UNC path can produce Windows file-security prompts. The test sends keyboard scan-code and focus messages to its own test window, checks marker/movement saves, closes normally, reopens, and captures the actual rendered framebuffer. Full mouse/hold/wheel/completion automation is exercised by the Linux X11 test.

Native Windows rendering, input, sound return status and persistence were tested on the host. Windows and Linux framebuffer images were captured and inspected. For an isolated render check, set `HYPERCUBE_MAZE_STATE` to a test save file and `HYPERCUBE_MAZE_CAPTURE` to a PNG destination; the app captures its framebuffer after startup and closes. This works without desktop-screen capture. Original-app pixel and audio identity still require the missing assets or access to the running original.
