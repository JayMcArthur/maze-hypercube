
import tkinter as tk
from tkinter import ttk, messagebox
from dataclasses import dataclass
from typing import Tuple, Optional, List
import random
import time

# local module from the port
from maze4d import Maze4D, INVERSE, DEL
from maze4d import Maze4DFast

CELL_PX = 26   # base cell size in pixels
PAD = 20       # outer padding

PALETTE = [
    "#f94144","#f3722c","#f8961e","#f9844a","#f9c74f",
    "#90be6d","#43aa8b","#4d908e","#577590","#277da1",
    "#c77dff","#b8c0ff","#80ffdb","#64dfdf","#72efdd",
    "#56cfe1","#48bfe3","#5390d9","#5e60ce","#7400b8"
]

@dataclass
class Player:
    x:int=1; y:int=1; z:int=1; w:int=1
    moves:int=0

class MazeApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("4D Maze")
        self.configure(bg="#c4a489")

        # Controls panel (top)
        top = tk.Frame(self, bg="#c4a489")
        top.pack(side=tk.TOP, fill=tk.X, padx=10, pady=8)

        tk.Label(top, text="Maze Size", font=("Helvetica", 18, "bold"), bg="#c4a489").pack(side=tk.LEFT, padx=(0,20))

        self.size_x = tk.IntVar(value=10)
        self.size_y = tk.IntVar(value=10)
        self.size_z = tk.IntVar(value=1)
        self.size_w = tk.IntVar(value=1)
        self.hard = tk.BooleanVar(value=False)
        self.porous = tk.BooleanVar(value=False)
        self.show_portals = tk.BooleanVar(value=False)
        self.seed = tk.StringVar(value="")

        size_frame = tk.Frame(top, bg="#c4a489")
        size_frame.pack(side=tk.LEFT)
        for lbl, var in [("X",self.size_x),("Y",self.size_y),("Z",self.size_z),("W",self.size_w)]:
            tk.Label(size_frame, text=lbl, bg="#c4a489").pack(side=tk.LEFT)
            tk.Spinbox(size_frame, from_=1, to=40, width=3, textvariable=var).pack(side=tk.LEFT, padx=(0,10))

        tk.Checkbutton(top, text="Hard frontier bias", variable=self.hard, bg="#c4a489").pack(side=tk.LEFT, padx=8)
        tk.Label(top, text="Seed:", bg="#c4a489").pack(side=tk.LEFT, padx=(12,2))
        tk.Entry(top, width=8, textvariable=self.seed).pack(side=tk.LEFT)
        ttk.Button(top, text="New Maze", command=self.new_maze).pack(side=tk.LEFT, padx=10)

        # Display row (center)
        center = tk.Frame(self, bg="#c4a489")
        center.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=10, pady=6)

        self.canvas = tk.Canvas(center, width=600, height=600, bg="#e59b5a", highlightthickness=0)
        self.canvas.pack(side=tk.LEFT, padx=(0,20))

        self.zw_canvas = tk.Canvas(center, width=260, height=260, bg="#d8c4af", highlightthickness=0)
        self.zw_canvas.pack(side=tk.LEFT)

        # Bottom controls
        bottom = tk.Frame(self, bg="#c4a489")
        bottom.pack(side=tk.TOP, pady=10)

        ttk.Button(bottom, text="Show Best Move", command=self.show_best_move).pack(side=tk.LEFT, padx=6)
        ttk.Button(bottom, text="Make Best Move", command=self.make_best_move).pack(side=tk.LEFT, padx=6)
        ttk.Button(bottom, text="Restart", command=self.restart).pack(side=tk.LEFT, padx=6)
        ttk.Button(bottom, text="Next Maze", command=self.new_maze).pack(side=tk.LEFT, padx=6)
        ttk.Checkbutton(bottom, text="Porous Walls", variable=self.porous).pack(side=tk.LEFT, padx=10)
        ttk.Checkbutton(bottom, text="Portals (visual only)", variable=self.show_portals, command=self.draw).pack(side=tk.LEFT, padx=10)

        self.moves_var = tk.StringVar(value="Moves: 0    Time: 0:00")
        self.complexity_var = tk.StringVar(value="Complex #1")
        lab = tk.Label(self, textvariable=self.moves_var, bg="#c4a489", font=("Helvetica", 12, "bold"))
        lab.pack(side=tk.TOP)
        lab2 = tk.Label(self, textvariable=self.complexity_var, bg="#c4a489", font=("Helvetica", 12))
        lab2.pack(side=tk.TOP)

        # Keyboard
        self.bind("<Up>", lambda e:self.try_move(2, -1))   # -Y
        self.bind("<Down>", lambda e:self.try_move(2, +1)) # +Y
        self.bind("<Left>", lambda e:self.try_move(1, -1)) # -X
        self.bind("<Right>", lambda e:self.try_move(1, +1))# +X
        # WASD on W/Z plane
        self.bind("w", lambda e:self.try_move(3, +1))      # +Z
        self.bind("s", lambda e:self.try_move(3, -1))      # -Z
        self.bind("a", lambda e:self.try_move(4, -1))      # -W
        self.bind("d", lambda e:self.try_move(4, +1))      # +W

        self.maze: Optional[Maze4D] = None
        self.canvas.bind("<Configure>", lambda e: self.draw())
        self.zw_canvas.bind("<Configure>", lambda e: self.draw())
        self.player = Player()
        self.t0 = time.time()
        self.new_maze()
        self.after(250, self._tick)

    # --- Maze lifecycle ---------------------------------------------------
    def new_maze(self):
        seed = None
        s = self.seed.get().strip()
        if s:
            try: seed = int(s)
            except: seed = random.randint(0, 10**9)
        X,Y,Z,W = self.size_x.get(), self.size_y.get(), self.size_z.get(), self.size_w.get()
        cells = X*Y*Z*W
        if cells > 400_000:
            try:
                from tkinter import messagebox
                messagebox.showinfo('Large Maze', f'This size ({cells:,} cells) may take a while to generate in Python.')
            except Exception:
                pass
        if cells > 200_000:
            self.maze = Maze4DFast(X, Y, Z, W, hard=self.hard.get(), seed=seed)
        else:
            self.maze = Maze4D(X, Y, Z, W, hard=self.hard.get(), seed=seed)
        self.maze.generate()
        self.player = Player(1,1,1,1,0)
        self.t0 = time.time()
        self.draw()
        self.update_hud()

    def restart(self):
        if not self.maze: return
        self.player = Player(1,1,1,1,0)
        self.t0 = time.time()
        self.draw()
        self.update_hud()

    # --- Movement ---------------------------------------------------------
    def try_move(self, dim:int, delta:int):
        if not self.maze: return
        x,y,z,w = self.player.x, self.player.y, self.player.z, self.player.w
        # map movement to direction index expected by mazeWalls
        # For dim 1..4 and delta +1/-1, find dir index 1..8
        if dim==1 and delta==+1: d=1
        elif dim==1 and delta==-1: d=4
        elif dim==2 and delta==+1: d=2
        elif dim==2 and delta==-1: d=5
        elif dim==3 and delta==+1: d=3
        elif dim==3 and delta==-1: d=6
        elif dim==4 and delta==+1: d=7
        elif dim==4 and delta==-1: d=8
        else: return

        nx = x + DEL[1][d]
        ny = y + DEL[2][d]
        nz = z + DEL[3][d]
        nw = w + DEL[4][d]

        if not (1 <= nx <= self.maze.x_size and 1 <= ny <= self.maze.y_size and 1 <= nz <= self.maze.z_size and 1 <= nw <= self.maze.w_size):
            return

        wall = self.maze.mazeWalls[x][y][z][w][d]
        if wall and not self.porous.get():
            return
        # if porous, allow the step regardless of wall

        self.player = Player(nx,ny,nz,nw,self.player.moves+1)
        self.draw()
        self.update_hud()

    # --- Best move helpers ------------------------------------------------
    def _best_move_dir(self) -> Optional[int]:
        x,y,z,w = self.player.x, self.player.y, self.player.z, self.player.w
        best_d = None
        best_val = (self.maze.get_dist(x,y,z,w) if getattr(self.maze,'get_dist',None) else self.maze.mazeXYZ[x][y][z][w])
        for d in range(1,9):
            nx = x + DEL[1][d]; ny = y + DEL[2][d]; nz = z + DEL[3][d]; nw = w + DEL[4][d]
            if not (1 <= nx <= self.maze.x_size and 1 <= ny <= self.maze.y_size and 1 <= nz <= self.maze.z_size and 1 <= nw <= self.maze.w_size):
                continue
            if self.maze.mazeWalls[x][y][z][w][d] and not self.porous.get():
                continue
            val = (self.maze.get_dist(nx,ny,nz,nw) if getattr(self.maze,'get_dist',None) else self.maze.mazeXYZ[nx][ny][nz][nw])
            if 0 < val < best_val:
                best_val = val; best_d = d
        return best_d

    def show_best_move(self):
        d = self._best_move_dir()
        if d is None:
            messagebox.showinfo("Best Move", "No improving neighbor found.")
            return
        self.draw(highlight_dir=d)

    def make_best_move(self):
        d = self._best_move_dir()
        if d is None:
            return
        dim = 1 if d in (1,4) else 2 if d in (2,5) else 3 if d in (3,6) else 4
        delta = +1 if d in (1,2,3,7) else -1
        self.try_move(dim, delta)

    # --- Render -----------------------------------------------------------
    def _cell_px(self):
        # compute dynamic px size to fit in canvas
        self.update_idletasks()
        max_w = max(1, self.maze.x_size)
        max_h = max(1, self.maze.y_size)
        usable_w = max(200, self.canvas.winfo_width()-PAD*2)
        usable_h = max(200, self.canvas.winfo_height()-PAD*2)
        px = int(min(usable_w/max_w, usable_h/max_h))
        return max(4, min(40, px))

    def draw(self, highlight_dir:Optional[int]=None):
        if not self.maze: return
        self.canvas.delete("all")
        self.zw_canvas.delete("all")

        px = self._cell_px()
        x0 = PAD; y0 = PAD
        # background
        self.canvas.create_rectangle(x0-2, y0-2, x0 + self.maze.x_size*px + 2, y0 + self.maze.y_size*px + 2, fill="#f3a24a", width=0)

        # draw grid walls (XY slice for current z,w)
        z = self.player.z; w = self.player.w
        for y in range(1, self.maze.y_size+1):
            for x in range(1, self.maze.x_size+1):
                cx = x0 + (x-1)*px
                cy = y0 + (y-1)*px
                # cell rect
                self.canvas.create_rectangle(cx, cy, cx+px, cy+px, outline="", fill="")

                # portal badges (visual only)
                if self.show_portals.get():
                    s = max(3, int(px*0.18))
                    # -W top-left (red)
                    if not self.maze.mazeWalls[x][y][z][w][8]:
                        self.canvas.create_rectangle(cx+3, cy+3, cx+3+s, cy+3+s, outline="", fill="#e63946")
                    # +W bottom-right (cyan)
                    if not self.maze.mazeWalls[x][y][z][w][7]:
                        self.canvas.create_rectangle(cx+px-3-s, cy+px-3-s, cx+px-3, cy+px-3, outline="", fill="#2ec4b6")
                    # -Z bottom-left (magenta)
                    if not self.maze.mazeWalls[x][y][z][w][6]:
                        self.canvas.create_rectangle(cx+3, cy+px-3-s, cx+3+s, cy+px-3, outline="", fill="#b5179e")
                    # +Z top-right (green)
                    if not self.maze.mazeWalls[x][y][z][w][3]:
                        self.canvas.create_rectangle(cx+px-3-s, cy+3, cx+px-3, cy+3+s, outline="", fill="#43aa8b")

                # draw walls
                if (getattr(self.maze,'get_wall',None) and self.maze.get_wall(x,y,z,w,4)) or (hasattr(self.maze,'mazeWalls') and self.maze.mazeWalls[x][y][z][w][4]):
                    self.canvas.create_line(cx, cy, cx, cy+px, width=2)
                if (getattr(self.maze,'get_wall',None) and self.maze.get_wall(x,y,z,w,1)) or (hasattr(self.maze,'mazeWalls') and self.maze.mazeWalls[x][y][z][w][1]):
                    self.canvas.create_line(cx+px, cy, cx+px, cy+px, width=2)
                if (getattr(self.maze,'get_wall',None) and self.maze.get_wall(x,y,z,w,5)) or (hasattr(self.maze,'mazeWalls') and self.maze.mazeWalls[x][y][z][w][5]):
                    self.canvas.create_line(cx, cy, cx+px, cy, width=2)
                if (getattr(self.maze,'get_wall',None) and self.maze.get_wall(x,y,z,w,2)) or (hasattr(self.maze,'mazeWalls') and self.maze.mazeWalls[x][y][z][w][2]):
                    self.canvas.create_line(cx, cy+px, cx+px, cy+px, width=2)

        # start and exit markers
        sx,sy,sz,sw = 1,1,1,1
        ex,ey,ez,ew = self.maze.x_size, self.maze.y_size, self.maze.z_size, self.maze.w_size
        if (z,w)==(sz,sw):
            self._dot(sx,sy,px, x0,y0, color="#41b3a3")
        if (z,w)==(ez,ew):
            self._dot(ex,ey,px, x0,y0, color="#277da1")

        # player
        self._dot(self.player.x, self.player.y, px, x0,y0, color="#1f77b4")

        # best move arrow highlight
        if highlight_dir:
            x,y = self.player.x, self.player.y
            nx = x + DEL[1][highlight_dir]
            ny = y + DEL[2][highlight_dir]
            if 1 <= nx <= self.maze.x_size and 1 <= ny <= self.maze.y_size:
                cx = x0 + (x-1)*px + px/2
                cy = y0 + (y-1)*px + px/2
                nxp = x0 + (nx-1)*px + px/2
                nyp = y0 + (ny-1)*px + px/2
                self.canvas.create_line(cx,cy,nxp,nyp, fill="#2ca02c", width=4, arrow=tk.LAST)

        # Z/W bars
        self._draw_bar()

    def _dot(self, x,y,px,x0,y0,color="#1f77b4"):
        cx = x0 + (x-1)*px + px/2
        cy = y0 + (y-1)*px + px/2
        r = px*0.3
        self.canvas.create_oval(cx-r, cy-r, cx+r, cy+r, fill=color, outline="")

    
    def _draw_bar(self):
        # Draw ZxW grid for the current (x,y) slice.
        self.zw_canvas.delete("all")
        zN, wN = self.maze.z_size, self.maze.w_size
        if zN == 1 and wN == 1:
            return  # nothing to show

        pad = 10
        # pick pixel size that fits canvas
        cw = max(160, self.zw_canvas.winfo_width() or 260)
        ch = max(160, self.zw_canvas.winfo_height() or 260)
        px = int(min((cw-2*pad)/max(1,wN), (ch-2*pad)/max(1,zN)))
        px = max(4, min(40, px))
        x0 = (cw - wN*px)/2
        y0 = (ch - zN*px)/2

        x_cur, y_cur = self.player.x, self.player.y

        for zi in range(1, zN+1):
            for wi in range(1, wN+1):
                cx = x0 + (wi-1)*px
                cy = y0 + (zi-1)*px
                # cell bg
                self.zw_canvas.create_rectangle(cx, cy, cx+px, cy+px, outline="", fill="#f0e4d7")

                # walls for this (z,w) at current (x,y)
                if getattr(self.maze,'get_wall',None):
                    wL = self.maze.get_wall(x_cur,y_cur,zi,wi,8)
                    wR = self.maze.get_wall(x_cur,y_cur,zi,wi,7)
                    wT = self.maze.get_wall(x_cur,y_cur,zi,wi,6)
                    wB = self.maze.get_wall(x_cur,y_cur,zi,wi,3)
                else:
                    wL = self.maze.mazeWalls[x_cur][y_cur][zi][wi][8]
                    wR = self.maze.mazeWalls[x_cur][y_cur][zi][wi][7]
                    wT = self.maze.mazeWalls[x_cur][y_cur][zi][wi][6]
                    wB = self.maze.mazeWalls[x_cur][y_cur][zi][wi][3]

                if wL: self.zw_canvas.create_line(cx, cy, cx, cy+px, width=2)
                if wR: self.zw_canvas.create_line(cx+px, cy, cx+px, cy+px, width=2)
                if wT: self.zw_canvas.create_line(cx, cy, cx+px, cy, width=2)
                if wB: self.zw_canvas.create_line(cx, cy+px, cx+px, cy+px, width=2)

        # markers
        def dot(wi, zi, color):
            cx = x0 + (wi-1)*px + px/2
            cy = y0 + (zi-1)*px + px/2
            r = px*0.28
            self.zw_canvas.create_oval(cx-r, cy-r, cx+r, cy+r, fill=color, outline="")

        # current Z,W
        dot(self.player.w, self.player.z, "#1f77b4")
        # exit level only if x,y at exit
        if (x_cur, y_cur) == (self.maze.x_size, self.maze.y_size):
            dot(self.maze.w_size, self.maze.z_size, "#277da1")
        # entry level only if x,y at start
        if (x_cur, y_cur) == (1, 1):
            dot(1,1,"#41b3a3")


    # --- Timer tick to refresh HUD ---
    def _tick(self):
        self.update_hud()
        self.after(250, self._tick)
    # --- HUD --------------------------------------------------------------
    def update_hud(self):
        if not self.maze: return
        x,y,z,w = self.player.x, self.player.y, self.player.z, self.player.w
        dist = (self.maze.get_dist(x,y,z,w) if getattr(self.maze,'get_dist',None) else self.maze.mazeXYZ[x][y][z][w])
        moves_left = dist-1 if dist>0 else 0
        t = int(time.time()-self.t0)
        self.moves_var.set(f"Moves: {self.player.moves}    Remaining (best): {moves_left}    Time: {t//60}:{t%60:02d}")

        # crude complexity tag by size
        cells = self.maze.x_size*self.maze.y_size*self.maze.z_size*self.maze.w_size
        cidx = 1 if cells<=100 else 2 if cells<=1000 else 3 if cells<=10000 else 4
        self.complexity_var.set(f"Complex #{cidx}")

if __name__ == "__main__":
    app = MazeApp()
    app.mainloop()
