use serde::{Deserialize, Serialize};

pub type Position = [usize; 4]; // X, Y, Z, W; zero-based internally.
pub const INVERSE: [usize; 8] = [3, 4, 5, 0, 1, 2, 7, 6];
pub const AXIS: [usize; 8] = [0, 1, 2, 0, 1, 2, 3, 3];
pub const POSITIVE: [bool; 8] = [true, true, true, false, false, false, true, false];

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct MazeSpec {
    pub size: Position,
    pub number: u32,
    pub complex: bool,
}

impl Default for MazeSpec {
    fn default() -> Self {
        Self {
            size: [2; 4],
            number: 1,
            complex: false,
        }
    }
}

impl MazeSpec {
    pub fn valid(self) -> bool {
        (1..=100).contains(&self.number)
            && self.size.iter().all(|n| (1..=40).contains(n))
            && (self.size[0] == 1 || self.size[3] == 1 || self.size[0] + self.size[3] <= 40)
    }

    pub fn cells(self) -> usize {
        self.size.iter().product()
    }

    pub fn seed(self) -> u32 {
        (620 + self.number) * 5_120_000
            + u32::from(self.complex) * 2_560_000
            + self.size[0] as u32 * 64_000
            + self.size[1] as u32 * 1_600
            + self.size[2] as u32 * 40
            + self.size[3] as u32
    }
}

// Apple libc's Park–Miller sequence, independent of the host platform's rand().
struct DarwinRandom {
    state: i64,
}
impl DarwinRandom {
    fn next(&mut self) -> f32 {
        if self.state == 0 {
            self.state = 123_459_876;
        }
        let next = 16_807 * (self.state % 127_773) - 2_836 * (self.state / 127_773);
        self.state = if next < 0 { next + 2_147_483_647 } else { next };
        let value = (self.state as f64 / 2_148_000_000.0) as f32;
        if value as f64 > 0.99 { 0.99 } else { value }
    }
}

pub struct Maze {
    pub spec: MazeSpec,
    pub walls: Vec<u8>,
    pub distances: Vec<u32>,
}

impl Maze {
    pub fn generate(spec: MazeSpec) -> Self {
        assert!(spec.valid(), "invalid maze dimensions or number");
        let mut maze = Self {
            spec,
            walls: vec![255; spec.cells()],
            distances: vec![0; spec.cells()],
        };
        let mut rng = DarwinRandom {
            state: spec.seed() as i64,
        };
        rng.next();
        rng.next();
        let mut membership = vec![0_i32; spec.cells()];
        membership[0] = 1;
        let mut frontier = Vec::new();
        let mut current = [0; 4];
        loop {
            let old_length = frontier.len();
            for direction in 0..8 {
                if let Some(next) = maze.neighbor(current, direction) {
                    let index = maze.index(next);
                    if membership[index] == 0 {
                        membership[index] = -1;
                        frontier.push(next);
                    }
                }
            }
            let added = frontier.len() - old_length;
            if frontier.is_empty() {
                break;
            }
            let random = rng.next();
            // Preserve the controller's float arithmetic before promotion to double.
            let choice = if spec.complex {
                ((frontier.len() as f32 - random * added as f32) as f64 + 0.999) as usize
            } else {
                ((frontier.len() as f32 * random) as f64 + 1.0) as usize
            };
            current = frontier.swap_remove(choice - 1);
            let mut candidates = [0; 8];
            let mut count = 0;
            for direction in 0..8 {
                if let Some(next) = maze.neighbor(current, direction)
                    && membership[maze.index(next)] > 0
                {
                    candidates[count] = direction;
                    count += 1;
                }
            }
            let choice = ((count as f32 * rng.next()) as f64 + 1.0) as usize;
            let direction = candidates[choice - 1];
            let next = maze.neighbor(current, direction).unwrap();
            let index = maze.index(current);
            let next_index = maze.index(next);
            maze.walls[index] &= !(1 << direction);
            maze.walls[next_index] &= !(1 << INVERSE[direction]);
            membership[index] = membership[next_index] + 1;
        }
        maze.complete();
        maze
    }

    pub fn index(&self, p: Position) -> usize {
        ((p[0] * self.spec.size[1] + p[1]) * self.spec.size[2] + p[2]) * self.spec.size[3] + p[3]
    }

    pub fn neighbor(&self, p: Position, direction: usize) -> Option<Position> {
        let mut next = p;
        let axis = AXIS[direction];
        next[axis] = if POSITIVE[direction] {
            p[axis].checked_add(1)?
        } else {
            p[axis].checked_sub(1)?
        };
        (next[axis] < self.spec.size[axis]).then_some(next)
    }

    pub fn wall(&self, p: Position, direction: usize) -> bool {
        self.walls[self.index(p)] & (1 << direction) != 0
    }
    pub fn remaining(&self, p: Position) -> u32 {
        self.distances[self.index(p)] - 1
    }
    pub fn exit(&self) -> Position {
        self.spec.size.map(|n| n - 1)
    }

    pub fn best_direction(&self, p: Position) -> Option<usize> {
        (0..8).find(|&direction| {
            !self.wall(p, direction)
                && self.remaining(self.neighbor(p, direction).unwrap()) < self.remaining(p)
        })
    }

    fn complete(&mut self) {
        let exit = self.exit();
        let index = self.index(exit);
        self.distances[index] = 1;
        let mut stack = vec![exit];
        while let Some(p) = stack.pop() {
            for direction in 0..8 {
                if !self.wall(p, direction) {
                    let next = self.neighbor(p, direction).unwrap();
                    let index = self.index(next);
                    if self.distances[index] == 0 {
                        self.distances[index] = self.distances[self.index(p)] + 1;
                        stack.push(next);
                    }
                }
            }
        }
    }
}
