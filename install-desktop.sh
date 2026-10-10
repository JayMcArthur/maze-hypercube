#!/usr/bin/env bash
set -euo pipefail
maze_root=$(dirname -- "$(readlink -f -- "$0")")
cd -- "$maze_root"
cargo build --locked --release
maze_applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p -- "$maze_applications"
cat > "$maze_applications/hypercube-maze.desktop" <<ENTRY
[Desktop Entry]
Type=Application
Name=Maze HyperCube
Comment=Peter Kramer's multidimensional maze, ported to Rust
Exec="$maze_root/target/release/hypercube-maze"
Icon=$maze_root/assets/icon.png
Terminal=false
Categories=Game;LogicGame;
ENTRY
chmod +x "$maze_applications/hypercube-maze.desktop"
printf 'Installed launcher: %s\n' "$maze_applications/hypercube-maze.desktop"
