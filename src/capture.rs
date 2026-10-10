use eframe::{egui, icon_data::IconDataExt};
use std::{
    path::PathBuf,
    time::{Duration, Instant},
};

/// Captures the rendered framebuffer for native-platform verification.
pub struct Capture {
    path: PathBuf,
    ready: Instant,
    requested: bool,
}

impl Capture {
    pub fn from_env() -> Option<Self> {
        std::env::var_os("HYPERCUBE_MAZE_CAPTURE").map(|path| Self {
            path: path.into(),
            ready: Instant::now() + Duration::from_secs(1),
            requested: false,
        })
    }

    pub fn update(&mut self, ctx: &egui::Context) {
        if !self.requested && Instant::now() >= self.ready {
            ctx.send_viewport_cmd(egui::ViewportCommand::Screenshot(Default::default()));
            self.requested = true;
        }
        let image = ctx.input(|input| {
            input.events.iter().find_map(|event| {
                if let egui::Event::Screenshot { image, .. } = event {
                    Some(image.clone())
                } else {
                    None
                }
            })
        });
        if let Some(image) = image {
            let icon = egui::IconData {
                rgba: image
                    .pixels
                    .iter()
                    .flat_map(|pixel| pixel.to_array())
                    .collect(),
                width: image.width() as u32,
                height: image.height() as u32,
            };
            let result = icon.to_png_bytes().and_then(|bytes| {
                std::fs::write(&self.path, bytes).map_err(|error| error.to_string())
            });
            if let Err(error) = result {
                eprintln!("Cannot capture {}: {error}", self.path.display());
            }
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
        }
    }
}
