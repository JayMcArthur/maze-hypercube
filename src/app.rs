use crate::{
    audio::Audio,
    capture::Capture,
    game::{self, Game, SHAPES},
    hint::{HeldHint, Tick},
    maze::AXIS,
    view::{self, Layout},
};
use eframe::egui::{self, Color32, Key, Pos2, RichText, Sense, Stroke, Vec2, vec2};
use std::{
    path::PathBuf,
    time::{Duration, Instant},
};

#[derive(Clone, Copy, PartialEq)]
enum Page {
    Home,
    Play,
    Select,
}

struct Drag {
    base: Pos2,
    xy: bool,
    moved: bool,
}

pub struct MazeApp {
    game: Game,
    page: Page,
    path: PathBuf,
    last_tick: Instant,
    last_save: Instant,
    held_hint: Option<HeldHint>,
    drag: Option<Drag>,
    shift: [f32; 4],
    error: Option<String>,
    audio: Audio,
    capture: Option<Capture>,
}

impl MazeApp {
    pub fn new(cc: &eframe::CreationContext<'_>, game: Game, path: PathBuf) -> Self {
        let mut fonts = egui::FontDefinitions::default();
        fonts.font_data.insert(
            "sans".into(),
            egui::FontData::from_static(include_bytes!(
                "../assets/fonts/LiberationSans-Regular.ttf"
            ))
            .into(),
        );
        fonts.font_data.insert(
            "bold".into(),
            egui::FontData::from_static(include_bytes!("../assets/fonts/LiberationSans-Bold.ttf"))
                .into(),
        );
        fonts
            .families
            .get_mut(&egui::FontFamily::Proportional)
            .unwrap()
            .insert(0, "sans".into());
        fonts
            .families
            .insert(egui::FontFamily::Name("bold".into()), vec!["bold".into()]);
        cc.egui_ctx.set_fonts(fonts);
        let mut style = (*cc.egui_ctx.style_of(egui::Theme::Light)).clone();
        style.visuals = egui::Visuals::light();
        style.visuals.panel_fill = view::BACKGROUND;
        style.visuals.window_fill = Color32::from_rgb(246, 244, 240);
        style.visuals.override_text_color = None;
        style.visuals.widgets.noninteractive.fg_stroke.color = Color32::BLACK;
        for widget in [
            &mut style.visuals.widgets.inactive,
            &mut style.visuals.widgets.hovered,
            &mut style.visuals.widgets.active,
        ] {
            widget.bg_fill = Color32::TRANSPARENT;
            widget.weak_bg_fill = Color32::TRANSPARENT;
            widget.bg_stroke = Stroke::new(1.0, Color32::WHITE);
            widget.fg_stroke = Stroke::new(1.0, Color32::WHITE);
            widget.corner_radius = 10.into();
        }
        style.spacing.button_padding = vec2(12.0, 7.0);
        cc.egui_ctx.set_theme(egui::Theme::Light);
        cc.egui_ctx.set_style_of(egui::Theme::Light, style);
        Self {
            game,
            page: Page::Play,
            path,
            last_tick: Instant::now(),
            last_save: Instant::now(),
            held_hint: None,
            drag: None,
            shift: [0.0; 4],
            error: None,
            audio: Audio::new(),
            capture: Capture::from_env(),
        }
    }

    fn save(&mut self) {
        if let Err(error) = game::save(&self.path, &self.game.snapshot()) {
            eprintln!("{error}");
            self.error = Some(error);
        }
        self.last_save = Instant::now();
    }

    fn move_direction(&mut self, direction: usize) {
        if self.game.move_direction(direction) && self.game.state.sound {
            self.audio.click();
        }
    }

    fn set_page(&mut self, page: Page) {
        self.page = page;
        self.held_hint = None;
        self.drag = None;
        self.shift = [0.0; 4];
        self.game.hint = None;
        self.save();
    }

    fn tick(&mut self, ctx: &egui::Context) {
        let now = Instant::now();
        let elapsed = now.duration_since(self.last_tick);
        self.last_tick = now;
        let focused = ctx.input(|input| input.focused);
        if self.page == Page::Play && focused {
            self.game.advance_time(elapsed);
        }
        if !focused {
            self.held_hint = None;
            self.drag = None;
            self.shift = [0.0; 4];
        }
        if let Some(held) = &mut self.held_hint {
            match held.tick(now, self.game.hint.is_some()) {
                Tick::Wait => {}
                Tick::Advance => {
                    if self.game.best_move() && self.game.state.sound {
                        self.audio.click();
                    }
                }
                Tick::Finished => self.held_hint = None,
            }
            if self.game.at_exit() {
                self.held_hint = None;
            }
        }
        if now.duration_since(self.last_save) >= Duration::from_secs(2) {
            self.save();
        }
        ctx.request_repaint_after(Duration::from_millis(16));
    }

    fn keyboard(&mut self, ctx: &egui::Context) {
        if self.page != Page::Play || self.game.completion_open || self.error.is_some() {
            return;
        }
        let movements = [
            (Key::ArrowRight, 6),
            (Key::ArrowDown, 2),
            (Key::ArrowLeft, 7),
            (Key::ArrowUp, 5),
            (Key::D, 0),
            (Key::S, 1),
            (Key::A, 3),
            (Key::W, 4),
        ];
        for (key, direction) in movements {
            if ctx.input(|input| input.key_pressed(key)) {
                self.held_hint = None;
                self.move_direction(direction);
            }
        }
        if ctx.input(|input| input.key_pressed(Key::Space)) {
            self.game.toggle_marker();
        }
        if ctx.input(|input| input.key_pressed(Key::R)) {
            self.held_hint = None;
            self.game.restart();
        }
        if ctx.input(|input| input.key_pressed(Key::N)) {
            self.held_hint = None;
            self.game.change_number(1);
        }
        if ctx.input(|input| input.key_pressed(Key::B)) {
            self.held_hint = None;
            if self.game.best_move() && self.game.state.sound {
                self.audio.click();
            }
        }
    }

    fn header(&self, ui: &mut egui::Ui) {
        let [x, y, z, w] = self.game.state.spec.size;
        ui.add_space(12.0);
        ui.vertical_centered(|ui| {
            ui.label(bold(format!("Maze Size {w}x{z}x{y}x{x}"), 32.0));
        });
        ui.add_space(4.0);
        let seconds = self.game.state.elapsed_ms / 1000;
        ui.columns(3, |columns| {
            columns[0].vertical_centered(|ui| {
                if self.game.state.show_moves {
                    ui.label(
                        bold(
                            format!(
                                "Moves: {}",
                                self.game.maze.remaining(self.game.state.position)
                            ),
                            16.0,
                        )
                        .color(Color32::from_rgb(112, 61, 0)),
                    );
                }
            });
            columns[1].vertical_centered(|ui| {
                ui.label(bold(
                    format!(
                        "{} #{}",
                        if self.game.state.spec.complex {
                            "Complex"
                        } else {
                            "Standard"
                        },
                        self.game.state.spec.number
                    ),
                    16.0,
                ));
            });
            columns[2].vertical_centered(|ui| {
                ui.label(
                    bold(format!("Time: {}:{:02}", seconds / 60, seconds % 60), 16.0)
                        .color(Color32::from_rgb(112, 61, 0)),
                );
            });
        });
    }

    fn controls(&mut self, ui: &mut egui::Ui) {
        let display_options = (
            self.game.state.porous,
            self.game.state.show_moves,
            self.game.state.portals,
            self.game.state.color,
        );
        ui.vertical_centered(|ui| {
            let automatic = self.held_hint.as_ref().is_some_and(|held| held.automatic);
            let label = if automatic {
                "Stop Best Move"
            } else if self.game.hint.is_some() {
                "Make Best Move"
            } else {
                "Show Best Move"
            };
            let button =
                egui::Button::new(RichText::new(label).color(Color32::WHITE)).fill(if automatic {
                    Color32::RED
                } else {
                    Color32::TRANSPARENT
                });
            let response = ui.add(button);
            if response.is_pointer_button_down_on() && ui.input(|input| input.pointer.any_pressed())
            {
                if automatic {
                    self.game.hint = self.game.maze.best_direction(self.game.state.position);
                }
                if self.game.best_move() && self.game.state.sound {
                    self.audio.click();
                }
                if let Some(held) = &mut self.held_hint {
                    held.repress();
                } else {
                    self.held_hint = Some(HeldHint::new(Instant::now()));
                }
            }
            if !response.is_pointer_button_down_on()
                && let Some(held) = &mut self.held_hint
            {
                held.release();
            }
        });
        ui.add_space(24.0);
        ui.horizontal_wrapped(|ui| {
            ui.add_space((ui.available_width() - 680.0).max(0.0) / 2.0);
            if ui
                .button(RichText::new("Next Maze").color(Color32::WHITE))
                .clicked()
            {
                self.held_hint = None;
                self.game.change_number(1);
            }
            if ui
                .button(RichText::new("Restart").color(Color32::WHITE))
                .clicked()
            {
                self.held_hint = None;
                self.game.restart();
            }
            choice(ui, &mut self.game.state.porous, true, "Porous Walls");
            choice(ui, &mut self.game.state.porous, false, "Normal Walls");
            toggle(ui, &mut self.game.state.show_moves, "Moves");
            if self.game.portals_available() {
                toggle(ui, &mut self.game.state.portals, "Portals");
            }
            if self.game.state.spec.size[0] + self.game.state.spec.size[1] == 2
                && ui
                    .button(RichText::new("Color").color(Color32::WHITE))
                    .clicked()
            {
                self.game.state.color = (self.game.state.color + 1) % 8;
            }
        });
        ui.add_space(24.0);
        ui.separator();
        if display_options
            != (
                self.game.state.porous,
                self.game.state.show_moves,
                self.game.state.portals,
                self.game.state.color,
            )
        {
            self.game.hint = None;
        }
        ui.columns(3, |columns| {
            for (column, label, page) in [
                (0, "Home", Page::Home),
                (1, "Play", Page::Play),
                (2, "Select", Page::Select),
            ] {
                columns[column].vertical_centered(|ui| {
                    if ui
                        .add(
                            egui::Button::new(RichText::new(label).color(if self.page == page {
                                Color32::WHITE
                            } else {
                                Color32::from_gray(90)
                            }))
                            .frame(false),
                        )
                        .clicked()
                    {
                        self.set_page(page);
                    }
                });
            }
        });
    }

    fn gestures(&mut self, response: &egui::Response, layout: &Layout) {
        if self.page != Page::Play || self.game.completion_open || self.error.is_some() {
            return;
        }
        let events = response.ctx.input(|input| input.events.clone());
        for event in events {
            match event {
                egui::Event::PointerButton {
                    pos,
                    button: egui::PointerButton::Primary,
                    pressed: true,
                    ..
                } if response.rect.contains(pos) => {
                    self.held_hint = None;
                    self.drag = Some(Drag {
                        base: pos,
                        xy: layout.plane_at(pos),
                        moved: false,
                    });
                }
                egui::Event::PointerMoved(point) => {
                    if let Some(drag) = &mut self.drag {
                        drag.moved = true;
                        self.drag_to(point, layout);
                    }
                }
                egui::Event::PointerButton {
                    button: egui::PointerButton::Primary,
                    pressed: false,
                    ..
                } => {
                    if self.drag.take().is_some_and(|drag| !drag.moved) {
                        self.game.toggle_marker();
                    }
                    self.shift = [0.0; 4];
                }
                egui::Event::PointerGone => {
                    self.drag = None;
                    self.shift = [0.0; 4];
                }
                _ => {}
            }
        }
    }

    fn drag_to(&mut self, point: Pos2, layout: &Layout) {
        let Some(drag) = &self.drag else {
            return;
        };
        let delta = point - drag.base;
        if delta.x.abs() == delta.y.abs() {
            return;
        }
        let horizontal = delta.x.abs() > delta.y.abs();
        let direction = match (
            drag.xy,
            horizontal,
            if horizontal {
                delta.x > 0.0
            } else {
                delta.y > 0.0
            },
        ) {
            (true, true, true) => 0,
            (true, true, false) => 3,
            (true, false, true) => 1,
            (true, false, false) => 4,
            (false, true, true) => 6,
            (false, true, false) => 7,
            (false, false, true) => 2,
            (false, false, false) => 5,
        };
        let movement = if horizontal { delta.x } else { delta.y };
        let touch_edge = layout.edge.max(20.0) * layout.scale;
        let can_move = self
            .game
            .maze
            .neighbor(self.game.state.position, direction)
            .is_some()
            && (self.game.state.porous
                || !self.game.maze.wall(self.game.state.position, direction));
        if movement.abs() > touch_edge / 2.0 && can_move {
            let drag = self.drag.as_mut().unwrap();
            if horizontal {
                drag.base.x += touch_edge * movement.signum();
                drag.base.y = point.y;
            } else {
                drag.base.y += touch_edge * movement.signum();
                drag.base.x = point.x;
            }
            self.move_direction(direction);
        }
        self.shift = [0.0; 4];
        if can_move && !self.game.at_exit() {
            let base = self.drag.as_ref().unwrap().base;
            let remaining = if horizontal {
                point.x - base.x
            } else {
                point.y - base.y
            };
            let shift_direction = if remaining >= 0.0 {
                direction
            } else {
                crate::maze::INVERSE[direction]
            };
            let shifted_cell = self
                .game
                .maze
                .neighbor(self.game.state.position, shift_direction);
            if shifted_cell.is_some()
                && (self.game.state.porous
                    || !self
                        .game
                        .maze
                        .wall(self.game.state.position, shift_direction))
            {
                self.shift[AXIS[direction]] = (remaining * layout.edge / touch_edge)
                    .clamp(-layout.edge / 2.0, layout.edge / 2.0);
            }
        }
        self.game.hint = None;
    }

    fn selection(&mut self, ctx: &egui::Context) {
        let mut close = false;
        let window = egui::Window::new("Select Maze")
            .title_bar(false)
            .id(egui::Id::new("selection"))
            .collapsible(false)
            .resizable(false)
            .anchor(egui::Align2::CENTER_CENTER, Vec2::ZERO)
            .default_width(350.0)
            .show(ctx, |ui| {
                ui.vertical_centered(|ui| {
                    ui.label(bold("Select Maze", 30.0));
                    let mut spec = self.game.state.spec;
                    egui::Frame::new()
                        .fill(view::BACKGROUND)
                        .inner_margin(8)
                        .show(ui, |ui| {
                            ui.horizontal(|ui| {
                                choice(ui, &mut self.game.state.sound, false, "Sound Off");
                                choice(ui, &mut self.game.state.sound, true, "Sound On");
                            });
                            ui.horizontal(|ui| {
                                choice(ui, &mut spec.complex, false, "Standard");
                                choice(ui, &mut spec.complex, true, "Complex");
                            });
                            ui.horizontal(|ui| {
                                if ui.button("Prior Maze").clicked() {
                                    spec.number = if spec.number == 1 {
                                        100
                                    } else {
                                        spec.number - 1
                                    };
                                }
                                if ui.button("Next Maze").clicked() {
                                    spec.number = spec.number % 100 + 1;
                                }
                                ui.label(format!("Maze Number {}", spec.number));
                            });
                            ui.add(
                                egui::Slider::new(&mut spec.number, 1..=100).text("Maze Number"),
                            );
                        });
                    let mut shape = self.game.state.shape;
                    ui.add_space(12.0);
                    egui::Grid::new("dimensions")
                        .num_columns(5)
                        .spacing([6.0, 0.0])
                        .show(ui, |ui| {
                            for label in ["Maze Type", "X", "Y", "Z", "W"] {
                                ui.label(RichText::new(label).color(Color32::BLACK));
                            }
                            ui.end_row();
                            if picker(ui, "shape", &SHAPES, &mut shape, 0..=7, 145.0, true) {
                                game::constrain_shape(&mut spec.size, shape);
                            }
                            for axis in [3, 2, 1, 0] {
                                let editable =
                                    matches!((shape, axis), (_, 3) | (7, _) | (1 | 3, 1) | (5, 0));
                                let min = if axis == 3 && shape != 7 { 2 } else { 1 };
                                let max = dimension_limit(spec.size, shape, axis);
                                if picker(
                                    ui,
                                    axis,
                                    &[],
                                    &mut spec.size[axis],
                                    min..=max,
                                    40.0,
                                    editable,
                                ) {
                                    game::constrain_shape(&mut spec.size, shape);
                                }
                            }
                            ui.end_row();
                        });
                    self.game.state.shape = shape;
                    self.game.apply_spec(spec);
                    if spec.cells() > 1000 {
                        ui.label("(too big)");
                    }
                    ui.add_space(16.0);
                    egui::Frame::new()
                        .fill(view::BACKGROUND)
                        .inner_margin(6)
                        .show(ui, |ui| {
                            if ui
                                .button(RichText::new("Play").color(Color32::WHITE))
                                .clicked()
                            {
                                close = true;
                            }
                        });
                });
            });
        let outside = window.is_some_and(|window| {
            ctx.input(|input| {
                input.pointer.any_pressed()
                    && input
                        .pointer
                        .interact_pos()
                        .is_some_and(|point| !window.response.rect.contains(point))
            })
        });
        if close || outside || ctx.input(|input| input.key_pressed(Key::Escape)) {
            self.set_page(Page::Play);
        }
    }

    fn home(&mut self, ui: &mut egui::Ui) {
        ui.vertical_centered(|ui| {
            ui.add_space(60.0);
            ui.label(bold("Maze HyperCube", 36.0));
            ui.add_space(24.0);
            ui.label("Find your way from the green entrance to the blue exit.");
            ui.label("Both views show your position in the same maze.");
            ui.add_space(16.0);
            ui.label("Drag in either view to move. Click to mark your current cell.");
            ui.label("Arrow keys move in the left view. WASD moves in the right view.");
            ui.label("Space marks a cell. B shows or makes the best move.");
            ui.label("R restarts. N advances to the next maze.");
            ui.add_space(16.0);
            ui.label("Hold Show Best Move to start automatic movement; press again to stop.");
            ui.label("Porous Walls lets you move through walls inside the maze.");
            ui.label("Portals shows passages to cells in the other view.");
            ui.label("Select chooses the maze shape, size, number, sound and complexity.");
            ui.add_space(24.0);
            if ui.button("Play").clicked() {
                self.set_page(Page::Play);
            }
        });
    }
}

fn dimension_limit(size: [usize; 4], shape: usize, axis: usize) -> usize {
    match (shape, axis) {
        (6, 3) => 10,
        (5, 3) => {
            if size[0] > 1 {
                40 - size[0]
            } else {
                40
            }
        }
        (5, 0) => 40_usize.saturating_sub(size[3]).max(1),
        (7, 3) => {
            if size[0] > 1 {
                40_usize.saturating_sub(size[0]).max(1)
            } else {
                40
            }
        }
        (7, 0) if size[3] > 1 => 40_usize.saturating_sub(size[3]).max(1),
        _ => 40,
    }
}

fn bold(text: impl Into<String>, size: f32) -> RichText {
    RichText::new(text)
        .family(egui::FontFamily::Name("bold".into()))
        .size(size)
        .color(Color32::BLACK)
}

fn picker(
    ui: &mut egui::Ui,
    id: impl std::hash::Hash + std::fmt::Debug,
    labels: &[&str],
    value: &mut usize,
    range: std::ops::RangeInclusive<usize>,
    width: f32,
    editable: bool,
) -> bool {
    let (min, max) = (*range.start(), *range.end());
    let old = *value;
    let (rect, response) = ui.allocate_exact_size(vec2(width, 200.0), Sense::click_and_drag());
    let painter = ui.painter_at(rect);
    painter.rect_filled(rect, 0.0, view::BACKGROUND);
    if editable {
        let id = ui.make_persistent_id(id);
        if response.drag_started() {
            ui.data_mut(|data| data.insert_temp(id, *value));
        }
        if response.dragged() {
            let base = ui.data(|data| data.get_temp::<usize>(id)).unwrap_or(*value);
            *value = (base as isize - (response.drag_delta().y / 40.0).round() as isize)
                .clamp(min as isize, max as isize) as usize;
        }
        if response.hovered() {
            let scroll: f32 = ui.input(|input| {
                input
                    .raw
                    .events
                    .iter()
                    .filter_map(|event| {
                        if let egui::Event::MouseWheel { delta, .. } = event {
                            Some(delta.y)
                        } else {
                            None
                        }
                    })
                    .sum()
            });
            if scroll.abs() > 0.0 {
                *value = (*value as isize - if scroll > 0.0 { 1 } else { -1 })
                    .clamp(min as isize, max as isize) as usize;
            }
        }
        if response.clicked()
            && let Some(pos) = response.interact_pointer_pos()
        {
            let delta = ((pos.y - rect.center().y) / 40.0).round() as isize;
            *value = (*value as isize + delta).clamp(min as isize, max as isize) as usize;
        }
    }
    for row in -2_isize..=2 {
        let index = *value as isize + row;
        if index < min as isize || index > max as isize || (!editable && row != 0) {
            continue;
        }
        let text = if labels.is_empty() {
            index.to_string()
        } else {
            labels[index as usize].to_owned()
        };
        let color = match row.abs() {
            0 => Color32::BLACK,
            1 => Color32::from_rgb(140, 119, 98),
            _ => Color32::from_rgb(166, 141, 116),
        };
        painter.text(
            rect.center() + vec2(0.0, row as f32 * 40.0),
            egui::Align2::CENTER_CENTER,
            text,
            egui::FontId::proportional(if row == 0 { 19.0 } else { 16.0 }),
            color,
        );
    }
    *value != old
}

fn choice(ui: &mut egui::Ui, value: &mut bool, target: bool, label: &str) {
    let selected = *value == target;
    let text = bold(label, 13.0).color(if selected {
        Color32::BLACK
    } else {
        Color32::WHITE
    });
    if ui
        .add(egui::Button::new(text).corner_radius(3).fill(if selected {
            Color32::WHITE
        } else {
            Color32::TRANSPARENT
        }))
        .clicked()
    {
        *value = target;
    }
}
fn toggle(ui: &mut egui::Ui, value: &mut bool, label: &str) {
    let text = RichText::new(label).color(if *value {
        view::BACKGROUND
    } else {
        Color32::WHITE
    });
    if ui
        .add(egui::Button::new(text).fill(if *value {
            Color32::WHITE
        } else {
            Color32::TRANSPARENT
        }))
        .clicked()
    {
        *value = !*value;
    }
}

impl eframe::App for MazeApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        let ctx = ui.ctx().clone();
        self.tick(&ctx);
        self.keyboard(&ctx);
        egui::Panel::bottom("controls").show(ui, |ui| self.controls(ui));
        egui::CentralPanel::default().show(ui, |ui| {
            if self.page == Page::Home {
                self.home(ui);
            } else {
                self.header(ui);
                let (rect, response) =
                    ui.allocate_exact_size(ui.available_size(), Sense::click_and_drag());
                let layout = Layout::new(rect, self.game.state.spec.size);
                self.gestures(&response, &layout);
                view::draw(ui, &self.game, rect, self.shift);
            }
        });
        if self.page == Page::Select {
            self.selection(&ctx);
        }
        if self.game.completion_open {
            egui::Modal::new(egui::Id::new("completed")).show(&ctx, |ui| {
                ui.label(bold("Maze Completed", 24.0));
                ui.label(game::completion_message(self.game.state.elapsed_ms));
                if ui.button("Ok").clicked() {
                    self.game.completion_open = false;
                    self.game.state.completed += 1;
                    self.save();
                }
            });
        }
        if let Some(capture) = &mut self.capture {
            capture.update(&ctx);
        }
        if let Some(error) = self.error.clone() {
            egui::Modal::new(egui::Id::new("save-error")).show(&ctx, |ui| {
                ui.heading("Saved game error");
                ui.label(error);
                if ui.button("Ok").clicked() {
                    self.error = None;
                }
            });
        }
    }
    fn on_exit(&mut self, _gl: Option<&eframe::glow::Context>) {
        self.save();
    }
}
