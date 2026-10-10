
"""
maze4d.py — Faithful Python port of the 4‑D maze generation/solver from the Objective‑C code.

Key points mirrored exactly:
- 1-based indexing on interior cells with a padded boundary (size+2) per dimension.
- Walls indexed 1..8 for +/-X, +/-Y, +/-Z, +/-W.
- "HardMaze" frontier bias option using the same formula.
- Frontier growth: mark unseen neighbors as -1 (on frontier).
- Maze membership value (>0) stores a distance from the entry during growth.
- Post-generation BFS ("completeMaze") computes shortest-path distance from the exit.
- Inverse wall and delWall tables match the Obj‑C arrays.

Author: ChatGPT (Python port)
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import List, Tuple, Optional
import random
from collections import deque

# Direction indices 1..8 (inclusive), matching the Obj‑C layout:
# 1:+X, 4:-X ; 2:+Y, 5:-Y ; 3:+Z, 6:-Z ; 7:+W, 8:-W
INVERSE = [0, 4, 5, 6, 1, 2, 3, 8, 7]  # index 0 unused
# delWall[dim][dir] where dim=1..4 (X,Y,Z,W), dir=1..8
DEL = [
    [0]*9,  # 0th row unused
    [0,  1, 0, 0, -1,  0, 0, 0, 0],  # X deltas for dirs 1..8
    [0,  0, 1, 0,  0, -1, 0, 0, 0],  # Y
    [0,  0, 0, 1,  0,  0,-1, 0, 0],  # Z
    [0,  0, 0, 0,  0,  0, 0, 1,-1],  # W
]

@dataclass
class Maze4D:
    x_size: int
    y_size: int
    z_size: int
    w_size: int
    hard: bool = False
    seed: Optional[int] = None

    def __post_init__(self):
        if self.seed is not None:
            random.seed(self.seed)

        sx, sy, sz, sw = self.x_size+2, self.y_size+2, self.z_size+2, self.w_size+2

        # mazeXYZ: int padded grid. 0=unseen; -1=on frontier; >0=in-maze (growth distance); 200000=boundary
        self.mazeXYZ = [[[[0 for _ in range(sw)] for _ in range(sz)] for _ in range(sy)] for _ in range(sx)]
        # mazeWalls: bool padded grid per cell per direction (1..8). True means wall exists, False means open.
        self.mazeWalls = [[[[[True for _ in range(9)] for _ in range(sw)] for _ in range(sz)] for _ in range(sy)] for _ in range(sx)]

        # Initialize boundaries and interior walls
        for x in range(1, self.x_size+1):
            for y in range(1, self.y_size+1):
                for z in range(1, self.z_size+1):
                    for w in range(1, self.w_size+1):
                        self.mazeXYZ[0][y][z][w] = 200000
                        self.mazeXYZ[self.x_size+1][y][z][w] = 200000
                        self.mazeXYZ[x][0][z][w] = 200000
                        self.mazeXYZ[x][self.y_size+1][z][w] = 200000
                        self.mazeXYZ[x][y][0][w] = 200000
                        self.mazeXYZ[x][y][self.z_size+1][w] = 200000
                        self.mazeXYZ[x][y][z][0] = 200000
                        self.mazeXYZ[x][y][z][self.w_size+1] = 200000
                        # walls already True

        # Frontier storage like frontierXYZ[count][1..4]
        self.frontier: List[Tuple[int,int,int,int]] = []
        self.frontier_new_count = 0  # "newFrontier" from last expansion
        self._curr = (1,1,1,1)       # Xxx,Yyy,Zzz,Www

    # --- Core random helper (mirror getRandom producing [0,1) float) ---
    @staticmethod
    def _rand() -> float:
        return random.random()

    # --- Generation pipeline ---
    def generate(self):
        """Run full generation: initialize -> seed first cell -> loop -> completeMaze."""
        # Reset interior to 0 (unseen) and all walls True (already set by ctor). Boundaries already set.
        for x in range(1, self.x_size+1):
            for y in range(1, self.y_size+1):
                for z in range(1, self.z_size+1):
                    for w in range(1, self.w_size+1):
                        self.mazeXYZ[x][y][z][w] = 0
                        for d in range(1,9):
                            self.mazeWalls[x][y][z][w][d] = True

        # First cell (Obj‑C uses (1,1,1,1))
        self._curr = (1,1,1,1)
        cx,cy,cz,cw = self._curr
        self.mazeXYZ[cx][cy][cz][cw] = 1  # "in maze" with distance 1

        # Expand frontier and grow
        self._expand_frontier()
        while len(self.frontier) > 0:
            self._pick_cell_from_frontier()
            self._expand_maze_from_current()
            self._expand_frontier()

        # Compute shortest path distances from exit (x_size,y_size,z_size,w_size)
        self._complete_maze()

    # --- Frontier expansion (neighbors that are unseen -> mark -1, append to frontier) ---
    def _expand_frontier(self):
        cx,cy,cz,cw = self._curr
        before = len(self.frontier)

        # Iterate over the 8 directions in the same order used in Obj‑C (1..8)
        for d in range(1,9):
            nx = cx + DEL[1][d]
            ny = cy + DEL[2][d]
            nz = cz + DEL[3][d]
            nw = cw + DEL[4][d]
            if 1 <= nx <= self.x_size and 1 <= ny <= self.y_size and 1 <= nz <= self.z_size and 1 <= nw <= self.w_size:
                if self.mazeXYZ[nx][ny][nz][nw] == 0:
                    self.frontier.append((nx,ny,nz,nw))
                    self.mazeXYZ[nx][ny][nz][nw] = -1  # "on frontier"

        self.frontier_new_count = len(self.frontier) - before

    # --- Randomly pick a frontier cell (HardMaze biases into the most recent new items) ---
    def _pick_cell_from_frontier(self):
        n = len(self.frontier)
        if n == 0:
            return
        r = self._rand()
        if self.hard and self.frontier_new_count > 0:
            # Count = frontierCount - random*newFrontier + 0.999  (1-based)
            idx_1based = n - int(r * self.frontier_new_count)  # floor
            if idx_1based < 1:
                idx_1based = 1
        else:
            # Count = frontierCount*randomOne + 1.0 (1-based uniform)
            idx_1based = int(r * n) + 1

        idx = idx_1based - 1  # to 0-based
        # Swap-remove like Obj‑C does
        chosen = self.frontier[idx]
        self.frontier[idx] = self.frontier[-1]
        self.frontier.pop()

        self._curr = chosen

    # --- Carve from current frontier cell to a neighboring in-maze cell ---
    def _expand_maze_from_current(self):
        cx,cy,cz,cw = self._curr
        # Collect candidate directions that lead to an in-maze neighbor (>0)
        candidates: List[int] = []
        for d in range(1,9):
            nx = cx + DEL[1][d]
            ny = cy + DEL[2][d]
            nz = cz + DEL[3][d]
            nw = cw + DEL[4][d]
            if self.mazeXYZ[nx][ny][nz][nw] > 0:
                candidates.append(d)

        # Randomly choose one of the connecting walls to remove
        if not candidates:
            # This should not happen if the frontier expansion logic is correct.
            # But just in case, turn this cell into a fresh seed.
            self.mazeXYZ[cx][cy][cz][cw] = 1
            return

        d = candidates[int(self._rand() * len(candidates))]
        nx = cx + DEL[1][d]
        ny = cy + DEL[2][d]
        nz = cz + DEL[3][d]
        nw = cw + DEL[4][d]

        # Knock down the wall in both cells
        self.mazeWalls[cx][cy][cz][cw][d] = False
        self.mazeWalls[nx][ny][nz][nw][INVERSE[d]] = False

        # Mark current cell as in-maze with distance relative to its parent neighbor
        self.mazeXYZ[cx][cy][cz][cw] = self.mazeXYZ[nx][ny][nz][nw] + 1

    # --- After generation, compute BFS distances from the exit cell (x_size,y_size,z_size,w_size) ---
    def _complete_maze(self):
        # Reset interior distances to 0
        for x in range(1, self.x_size+1):
            for y in range(1, self.y_size+1):
                for z in range(1, self.z_size+1):
                    for w in range(1, self.w_size+1):
                        self.mazeXYZ[x][y][z][w] = 0

        ex,ey,ez,ew = self.x_size, self.y_size, self.z_size, self.w_size
        self.mazeXYZ[ex][ey][ez][ew] = 1

        q: deque[Tuple[int,int,int,int]] = deque()
        q.append((ex,ey,ez,ew))

        while q:
            x,y,z,w = q.popleft()
            base = self.mazeXYZ[x][y][z][w]
            for d in range(1,9):
                if not self.mazeWalls[x][y][z][w][d]:
                    nx = x + DEL[1][d]
                    ny = y + DEL[2][d]
                    nz = z + DEL[3][d]
                    nw = w + DEL[4][d]
                    if self.mazeXYZ[nx][ny][nz][nw] == 0:
                        self.mazeXYZ[nx][ny][nz][nw] = base + 1
                        q.append((nx,ny,nz,nw))

    # --- Optional helper: reconstruct shortest path from (1,1,1,1) to (x,y,z,w) ---
    def shortest_path(self) -> List[Tuple[int,int,int,int]]:
        sx,sy,sz,sw = 1,1,1,1
        ex,ey,ez,ew = self.x_size, self.y_size, self.z_size, self.w_size
        path = [(sx,sy,sz,sw)]
        # Walk greedily to any neighbor with strictly smaller distance (from exit)
        x,y,z,w = sx,sy,sz,sw
        seen = set([(x,y,z,w)])
        while (x,y,z,w) != (ex,ey,ez,ew):
            best = None
            best_val = self.mazeXYZ[x][y][z][w]
            found = False
            for d in range(1,9):
                if not self.mazeWalls[x][y][z][w][d]:
                    nx = x + DEL[1][d]
                    ny = y + DEL[2][d]
                    nz = z + DEL[3][d]
                    nw = w + DEL[4][d]
                    val = self.mazeXYZ[nx][ny][nz][nw]
                    if 0 < val < best_val and (nx,ny,nz,nw) not in seen:
                        best = (nx,ny,nz,nw)
                        best_val = val
                        found = True
            if not found:
                # If no strictly descending neighbor, allow equal (should not happen often)
                for d in range(1,9):
                    if not self.mazeWalls[x][y][z][w][d]:
                        nx = x + DEL[1][d]
                        ny = y + DEL[2][d]
                        nz = z + DEL[3][d]
                        nw = w + DEL[4][d]
                        if (nx,ny,nz,nw) not in seen:
                            best = (nx,ny,nz,nw)
                            break
            if best is None:
                # No progress; return what we have
                return path
            x,y,z,w = best
            seen.add(best)
            path.append(best)
        return path

    # --- Small textual renderer for an XY slice at fixed (z,w) ---
    def render_xy_slice(self, z:int, w:int) -> str:
        """Return an ASCII rendering of a 2‑D slice at fixed z,w (cells = 1..size)."""
        assert 1 <= z <= self.z_size and 1 <= w <= self.w_size
        lines = []
        # Top border
        lines.append('+' + '--+'*self.x_size)
        for y in range(1, self.y_size+1):
            # Left wall of the row
            row_cells = ['|']
            row_floor = ['+']
            for x in range(1, self.x_size+1):
                # Cell content: distance mod 36 as digit/letter
                val = self.mazeXYZ[x][y][z][w]
                if val == 0:
                    ch = ' '
                else:
                    v = val % 36
                    if v < 10: ch = str(v)
                    else: ch = chr(ord('A') + v - 10)
                row_cells.append(ch + ('|' if self.mazeWalls[x][y][z][w][2] else ' '))  # wall 2 = +Y (right side in row)
                # Floor/ceiling: wall 1 = +X (down in ASCII), but for grid we use bottom walls as 1? We'll mimic typical maze:
                row_floor.append(('--' if self.mazeWalls[x][y][z][w][1] else '  ') + '+')
            lines.append(''.join(row_cells))
            lines.append(''.join(row_floor))
        return '\n'.join(lines)


def demo():
    m = Maze4D(8, 6, 2, 1, hard=False, seed=1234)  # small demo; z=2, w=1 so we can render
    m.generate()
    print("Slice z=1,w=1:\n")
    print(m.render_xy_slice(1,1))
    if m.z_size >= 2:
        print("\nSlice z=2,w=1:\n")
        print(m.render_xy_slice(2,1))
    print("\nShortest path length (cells visited):", len(m.shortest_path()))

if __name__ == "__main__":
    demo()
