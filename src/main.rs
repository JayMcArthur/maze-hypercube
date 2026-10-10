#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]
mod app;
mod audio;
mod capture;
mod game;
mod hint;
mod maze;
mod view;

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        #[cfg(target_os = "windows")]
        unsafe {
            #[link(name = "user32")]
            unsafe extern "system" {
                fn MessageBoxW(
                    window: *mut std::ffi::c_void,
                    text: *const u16,
                    caption: *const u16,
                    flags: u32,
                ) -> i32;
            }
            let message: Vec<u16> = format!("Maze Hypercube could not start:\n{error}")
                .encode_utf16()
                .chain([0])
                .collect();
            let title: Vec<u16> = "Maze Hypercube".encode_utf16().chain([0]).collect();
            MessageBoxW(std::ptr::null_mut(), message.as_ptr(), title.as_ptr(), 0x10);
        }
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().is_some_and(|arg| arg == "--dump") {
        if args.len() != 7 {
            return Err("Usage: hypercube-maze --dump X Y Z W NUMBER COMPLEX(0|1)".into());
        }
        let spec = maze::MazeSpec {
            size: [
                args[1].parse()?,
                args[2].parse()?,
                args[3].parse()?,
                args[4].parse()?,
            ],
            number: args[5].parse()?,
            complex: match args[6].as_str() {
                "0" => false,
                "1" => true,
                _ => return Err("COMPLEX must be 0 or 1".into()),
            },
        };
        if !spec.valid() {
            return Err("Invalid dimensions or maze number".into());
        }
        let maze = maze::Maze::generate(spec);
        for (walls, distance) in maze.walls.iter().zip(&maze.distances) {
            println!("{walls} {distance}");
        }
        return Ok(());
    }
    if !args.is_empty() {
        return Err("Usage: hypercube-maze [--dump X Y Z W NUMBER COMPLEX(0|1)]".into());
    }
    let path = game::state_path()?;
    let game = game::Game::new(game::load(&path)?)?;
    let options = eframe::NativeOptions {
        viewport: eframe::egui::ViewportBuilder::default()
            .with_title("Maze Hypercube")
            .with_icon(eframe::icon_data::from_png_bytes(include_bytes!(
                "../assets/icon.png"
            ))?)
            .with_inner_size([750.0, 850.0])
            .with_min_inner_size([520.0, 620.0]),
        ..Default::default()
    };
    eframe::run_native(
        "hypercube-maze",
        options,
        Box::new(move |cc| Ok(Box::new(app::MazeApp::new(cc, game, path)))),
    )?;
    Ok(())
}
