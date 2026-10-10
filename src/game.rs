use crate::maze::{Maze, MazeSpec, Position};
use serde::{Deserialize, Serialize};
use std::{fs, io, path::PathBuf, time::Duration};

pub const SHAPES: [&str; 8] = [
    "1D Line",
    "2D Lines",
    "2D Square",
    "3D Squares",
    "3D Cube",
    "4D Cubes",
    "4D Tesseract",
    "Free Form",
];

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SavedGame {
    pub spec: MazeSpec,
    pub position: Position,
    pub markers: Vec<usize>,
    pub elapsed_ms: u64,
    pub shape: usize,
    pub porous: bool,
    pub portals: bool,
    pub show_moves: bool,
    pub color: usize,
    pub sound: bool,
    pub completed: u32,
}

impl Default for SavedGame {
    fn default() -> Self {
        Self {
            spec: MazeSpec::default(),
            position: [0; 4],
            markers: vec![],
            elapsed_ms: 0,
            shape: 7,
            porous: false,
            portals: false,
            show_moves: true,
            color: 1,
            sound: true,
            completed: 0,
        }
    }
}

pub struct Game {
    pub state: SavedGame,
    pub maze: Maze,
    pub marked: Vec<bool>,
    pub hint: Option<usize>,
    pub completion_open: bool,
    elapsed_remainder: Duration,
}

impl Game {
    pub fn new(state: SavedGame) -> Result<Self, String> {
        if !state.spec.valid()
            || state.shape > 7
            || state.color > 7
            || state
                .position
                .iter()
                .zip(state.spec.size)
                .any(|(&p, n)| p >= n)
            || state
                .markers
                .iter()
                .any(|&index| index >= state.spec.cells())
        {
            return Err(
                "The saved game contains invalid dimensions, position, or settings.".into(),
            );
        }
        let maze = Maze::generate(state.spec);
        let mut marked = vec![false; state.spec.cells()];
        for &index in &state.markers {
            marked[index] = true;
        }
        Ok(Self {
            state,
            maze,
            marked,
            hint: None,
            completion_open: false,
            elapsed_remainder: Duration::ZERO,
        })
    }

    pub fn at_exit(&self) -> bool {
        self.state.position == self.maze.exit()
    }

    pub fn advance_time(&mut self, elapsed: Duration) {
        if !self.at_exit() {
            self.elapsed_remainder += elapsed;
            let milliseconds = self.elapsed_remainder.as_millis() as u64;
            self.state.elapsed_ms += milliseconds;
            self.elapsed_remainder -= Duration::from_millis(milliseconds);
        }
    }
    pub fn portals_available(&self) -> bool {
        let [x, y, z, w] = self.state.spec.size;
        x + y > 2 && z + w > 2
    }

    pub fn move_direction(&mut self, direction: usize) -> bool {
        if let Some(next) = self.maze.neighbor(self.state.position, direction)
            && (self.state.porous || !self.maze.wall(self.state.position, direction))
        {
            let was_exit = self.at_exit();
            self.state.position = next;
            self.hint = None;
            self.completion_open = !was_exit && self.at_exit();
            return true;
        }
        false
    }

    pub fn toggle_marker(&mut self) {
        let index = self.maze.index(self.state.position);
        self.marked[index] = !self.marked[index];
        self.hint = None;
    }

    pub fn restart(&mut self) {
        self.state.position = [0; 4];
        self.state.elapsed_ms = 0;
        self.elapsed_remainder = Duration::ZERO;
        self.hint = None;
        self.completion_open = false;
    }

    pub fn apply_spec(&mut self, spec: MazeSpec) {
        if spec == self.state.spec {
            return;
        }
        self.maze = Maze::generate(spec);
        self.state.spec = spec;
        self.marked = vec![false; spec.cells()];
        if !self.portals_available() {
            self.state.portals = false;
        }
        self.restart();
    }

    pub fn change_number(&mut self, delta: i32) {
        let mut spec = self.state.spec;
        spec.number = (spec.number as i32 - 1 + delta).rem_euclid(100) as u32 + 1;
        self.apply_spec(spec);
    }

    // The original alternates showing the pointer and taking the suggested step.
    pub fn best_move(&mut self) -> bool {
        if let Some(direction) = self.hint {
            self.move_direction(direction)
        } else {
            self.hint = self.maze.best_direction(self.state.position);
            false
        }
    }

    pub fn snapshot(&self) -> SavedGame {
        let mut state = self.state.clone();
        state.markers = self
            .marked
            .iter()
            .enumerate()
            .filter_map(|(index, &marked)| marked.then_some(index))
            .collect();
        state
    }
}

pub fn constrain_shape(size: &mut Position, shape: usize) {
    if shape != 7 && size[3] == 1 {
        size[3] = 2;
    }
    match shape {
        0 => {
            size[0] = 1;
            size[1] = 1;
            size[2] = 1;
        }
        1 => {
            size[0] = 1;
            size[2] = 1;
        }
        2 => {
            size[0] = 1;
            size[1] = 1;
            size[2] = size[3];
        }
        3 => {
            size[0] = 1;
            size[2] = size[3];
        }
        4 => {
            size[0] = 1;
            size[1] = size[3];
            size[2] = size[3];
        }
        5 => {
            size[1] = size[3];
            size[2] = size[3];
            size[0] = size[0].min(40_usize.saturating_sub(size[3]).max(1));
        }
        6 => {
            let side = size[3].min(10);
            size.fill(side);
        }
        _ => {}
    }
}

pub fn completion_message(elapsed_ms: u64) -> String {
    let minutes = elapsed_ms / 60_000;
    let seconds = elapsed_ms / 1000 % 60;
    let plural = if seconds == 1 { "" } else { "s" };
    match minutes {
        0 => format!("in {seconds} second{plural}"),
        1 => format!("in 1 minute and {seconds} second{plural}"),
        _ => format!("In {minutes} minutes and {seconds} second{plural}"),
    }
}

pub fn state_path() -> Result<PathBuf, String> {
    if let Some(path) = std::env::var_os("HYPERCUBE_MAZE_STATE") {
        return Ok(path.into());
    }
    #[cfg(target_os = "windows")]
    let base = PathBuf::from(std::env::var_os("LOCALAPPDATA").ok_or("LOCALAPPDATA is not set")?);
    #[cfg(target_os = "linux")]
    let base = std::env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".local/share")
        });
    Ok(base.join("hypercube-maze/game.json"))
}

pub fn load(path: &std::path::Path) -> Result<SavedGame, String> {
    match fs::read(path) {
        Ok(bytes) => serde_json::from_slice(&bytes)
            .map_err(|e| format!("Cannot read saved game {}: {e}", path.display())),
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(SavedGame::default()),
        Err(e) => Err(format!("Cannot open saved game {}: {e}", path.display())),
    }
}

pub fn save(path: &std::path::Path, state: &SavedGame) -> Result<(), String> {
    let write = || -> Result<(), Box<dyn std::error::Error>> {
        if let Some(parent) = path.parent()
            && !parent.as_os_str().is_empty()
        {
            fs::create_dir_all(parent)?;
        }
        let temporary = path.with_extension("json.tmp");
        fs::write(&temporary, serde_json::to_vec_pretty(state)?)?;
        fs::rename(temporary, path)?;
        Ok(())
    };
    write().map_err(|e| format!("Cannot save game {}: {e}", path.display()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn timer_keeps_fractional_frames_stops_at_exit_and_restarts() {
        let mut game = Game::new(SavedGame::default()).unwrap();
        for _ in 0..600 {
            game.advance_time(Duration::from_nanos(16_666_667));
        }
        assert_eq!(game.snapshot().elapsed_ms, 10_000);
        game.state.position = game.maze.exit();
        game.advance_time(Duration::from_secs(2));
        assert_eq!(game.snapshot().elapsed_ms, 10_000);
        game.restart();
        game.advance_time(Duration::from_nanos(999_900));
        assert_eq!(game.snapshot().elapsed_ms, 0);
        game.advance_time(Duration::from_nanos(100));
        assert_eq!(game.snapshot().elapsed_ms, 1);
    }

    #[test]
    fn walls_porous_boundaries_hints_and_completion() {
        let mut state = SavedGame::default();
        state.spec.number = 2;
        let mut game = Game::new(state).unwrap();
        let blocked = (0..8)
            .find(|&d| game.maze.neighbor([0; 4], d).is_some() && game.maze.wall([0; 4], d))
            .unwrap();
        assert!(!game.move_direction(blocked));
        game.state.porous = true;
        assert!(game.move_direction(blocked));
        game.restart();
        assert!(!game.move_direction(3));
        game.state.porous = false;
        let distance = game.maze.remaining([0; 4]);
        for remaining in (1..=distance).rev() {
            assert!(!game.best_move());
            assert!(game.hint.is_some());
            assert!(game.best_move());
            assert_eq!(game.maze.remaining(game.state.position), remaining - 1);
        }
        assert!(game.completion_open);
        assert!(game.at_exit());
        assert!(!game.best_move());
    }

    #[test]
    fn restart_keeps_markers_new_maze_clears_them_and_save_resumes() {
        let mut game = Game::new(SavedGame::default()).unwrap();
        game.toggle_marker();
        let direction = game.maze.best_direction(game.state.position).unwrap();
        game.move_direction(direction);
        game.state.elapsed_ms = 12_000;
        game.toggle_marker();
        let snapshot = game.snapshot();
        let restored =
            Game::new(serde_json::from_str(&serde_json::to_string(&snapshot).unwrap()).unwrap())
                .unwrap();
        assert_eq!(restored.state.position, game.state.position);
        assert_eq!(restored.state.elapsed_ms, 12_000);
        assert_eq!(restored.marked, game.marked);
        game.restart();
        assert_eq!(game.marked.iter().filter(|&&v| v).count(), 2);
        game.change_number(-1);
        assert_eq!(game.state.spec.number, 100);
        assert!(!game.marked.iter().any(|&v| v));
        game.change_number(1);
        assert_eq!(game.state.spec.number, 1);
    }

    #[test]
    fn all_shape_rules_and_large_sizes() {
        let expected = [
            [1, 1, 1, 4],
            [1, 3, 1, 4],
            [1, 1, 4, 4],
            [1, 3, 4, 4],
            [1, 4, 4, 4],
            [2, 4, 4, 4],
            [4; 4],
            [2, 3, 5, 4],
        ];
        for (shape, wanted) in expected.iter().enumerate() {
            let mut size = [2, 3, 5, 4];
            constrain_shape(&mut size, shape);
            assert_eq!(&size, wanted);
        }
        let mut size = [40; 4];
        constrain_shape(&mut size, 6);
        assert_eq!(size, [10; 4]);
        constrain_shape(&mut size, 5);
        assert!(
            MazeSpec {
                size,
                ..MazeSpec::default()
            }
            .valid()
        );
    }

    #[test]
    fn disk_save_round_trip_and_invalid_save_rejected() {
        let path =
            std::env::temp_dir().join(format!("hypercube-save-test-{}.json", std::process::id()));
        let mut game = Game::new(SavedGame::default()).unwrap();
        game.toggle_marker();
        game.state.elapsed_ms = 12_345;
        save(&path, &game.snapshot()).unwrap();
        let restored = Game::new(load(&path).unwrap()).unwrap();
        assert_eq!(restored.state.elapsed_ms, 12_345);
        assert!(restored.marked[0]);
        fs::remove_file(&path).unwrap();
        let mut invalid = SavedGame {
            position: [100; 4],
            ..SavedGame::default()
        };
        assert!(Game::new(invalid).is_err());
        invalid = SavedGame::default();
        invalid.markers.push(100_000);
        assert!(Game::new(invalid).is_err());
    }
}
