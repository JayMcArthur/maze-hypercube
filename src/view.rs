use crate::{game::Game, maze::Position};
use eframe::egui::{self, Color32, Pos2, Rect, Stroke, StrokeKind, Vec2, pos2, vec2};

const COLORS: [[f32; 3]; 8] = [
    [1.0; 3],
    [0.76, 0.66, 0.56],
    [1.0, 0.0, 0.0],
    [1.0, 0.5, 0.0],
    [0.95, 0.95, 0.0],
    [0.0, 1.0, 0.0],
    [0.0, 1.0, 1.0],
    [1.0, 0.5, 1.0],
];
const BLUE: Color32 = Color32::from_rgb(51, 102, 179);
pub const BACKGROUND: Color32 = Color32::from_rgb(195, 166, 137);

pub struct Layout {
    pub edge: f32,
    pub zw: Pos2,
    pub xy: Pos2,
    pub scale: f32,
    pub offset: Vec2,
    divider: f32,
}

impl Layout {
    pub fn new(rect: Rect, size: Position) -> Self {
        let [x, y, z, w] = size.map(|n| n as f32);
        let edge = ((675.0 / (w + x + 2.0)).min(540.0 / z).min(540.0 / y) / 2.0).floor() * 2.0;
        let zx = (edge - 1.0 + 0.25 * (695.0 - edge * (w + x + 2.0))).trunc();
        let zy = (20.0 + edge * 0.5 + 0.5 * (540.0 - edge * z)).trunc() + 10.0;
        let xx = (zx + edge * (w + 1.0) + 0.5 * (695.0 - edge * (w + x + 2.0))).trunc();
        let yy = (20.0 + edge * 0.5 + 0.5 * (540.0 - edge * y)).trunc() + 10.0;
        let scale = (rect.width() / 695.0).min(rect.height() / 600.0);
        let offset = rect.min.to_vec2() + (rect.size() - vec2(695.0, 600.0) * scale) / 2.0;
        let divider = 30.0 + xx - edge - 0.25 * (675.0 - edge * (w + x + 2.0));
        Self {
            edge,
            zw: pos2(zx, zy),
            xy: pos2(xx, yy),
            scale,
            offset,
            divider,
        }
    }

    pub fn screen(&self, p: Pos2) -> Pos2 {
        (self.offset + p.to_vec2() * self.scale).to_pos2()
    }
    pub fn local(&self, p: Pos2) -> Pos2 {
        ((p.to_vec2() - self.offset) / self.scale).to_pos2()
    }
    pub fn center(&self, p: Position, xy: bool) -> Pos2 {
        let (origin, a, b) = if xy {
            (self.xy, p[0], p[1])
        } else {
            (self.zw, p[3], p[2])
        };
        origin + vec2(a as f32 * self.edge, b as f32 * self.edge)
    }
    pub fn plane_at(&self, point: Pos2) -> bool {
        // Original gesture split between the two planes, even outside the grid bounds.
        self.local(point).x > self.divider
    }
}

fn palette(index: usize, light: bool) -> Color32 {
    let mut rgb = COLORS[index];
    if light {
        if index == 0 {
            rgb = [0.75; 3];
        } else {
            let ratio = match index {
                4 => 0.2,
                5 => 0.35,
                6 => 0.25,
                7 => 0.45,
                _ => 0.55,
            };
            rgb = rgb.map(|value| value * ratio + 1.0 - ratio);
        }
    } else {
        // Original backgrounds use .75 opacity on the graph background.
        rgb = std::array::from_fn(|i| rgb[i] * 0.75 + [195.0, 166.0, 137.0][i] / 255.0 * 0.25);
    }
    Color32::from_rgb(
        (rgb[0] * 255.0).round() as u8,
        (rgb[1] * 255.0).round() as u8,
        (rgb[2] * 255.0).round() as u8,
    )
}

fn color_index(game: &Game, p: Position) -> usize {
    let [x, y, _, _] = game.state.spec.size;
    if x + y == 2 {
        game.state.color
    } else {
        let mut index = if x > 1 { p[0] + 1 } else { p[1] + 1 };
        while index > 7 {
            index -= 6;
        }
        index
    }
}

pub fn draw(ui: &mut egui::Ui, game: &Game, rect: Rect, shift: [f32; 4]) -> Layout {
    let layout = Layout::new(rect, game.state.spec.size);
    let painter = ui.painter_at(rect);
    painter.rect_filled(rect, 0.0, BACKGROUND);
    draw_plane(&painter, &layout, game, false);
    draw_plane(&painter, &layout, game, true);
    for xy in [false, true] {
        let offset = if xy {
            vec2(shift[0], shift[1])
        } else {
            vec2(shift[3], shift[2])
        };
        let center =
            layout.screen(layout.center(game.state.position, xy) + offset + vec2(1.0, 1.0));
        painter.circle_filled(center, layout.edge * 0.3 * layout.scale, BLUE);
        let index = game.maze.index(game.state.position);
        if game.marked[index] {
            marker(&painter, &layout, game.state.position, xy);
        }
    }
    if let Some(direction) = game.hint {
        let next = game.maze.neighbor(game.state.position, direction).unwrap();
        let xy = next[2] == game.state.position[2] && next[3] == game.state.position[3];
        painter.line_segment(
            [
                layout.screen(layout.center(game.state.position, xy) + vec2(1.0, 1.0)),
                layout.screen(layout.center(next, xy) + vec2(1.0, 1.0)),
            ],
            Stroke::new(5.0 * layout.scale, BLUE),
        );
    }
    layout
}

fn marker(painter: &egui::Painter, layout: &Layout, p: Position, xy: bool) {
    painter.circle_filled(
        layout.screen(layout.center(p, xy) + vec2(1.0, 1.0)),
        (layout.edge * 0.06 + 1.0) * layout.scale,
        Color32::WHITE,
    );
}

fn draw_plane(painter: &egui::Painter, layout: &Layout, game: &Game, xy: bool) {
    let (horizontal, vertical, positive_h, positive_v) =
        if xy { (0, 1, 0, 1) } else { (3, 2, 6, 2) };
    let size = game.state.spec.size;
    let origin = if xy { layout.xy } else { layout.zw };
    // All backgrounds precede walls, as in drawMazeXY/drawMazeZ. Painting a
    // neighboring cell after its wall would cover half the wall's stroke.
    for a in 0..size[horizontal] {
        for b in 0..size[vertical] {
            let mut p = game.state.position;
            p[horizontal] = a;
            p[vertical] = b;
            let cell = Rect::from_center_size(layout.center(p, xy), Vec2::splat(layout.edge));
            painter.rect_filled(
                Rect::from_min_max(layout.screen(cell.min), layout.screen(cell.max)),
                0.0,
                palette(color_index(game, p), false),
            );
        }
    }
    for a in 0..size[horizontal] {
        for b in 0..size[vertical] {
            let mut p = game.state.position;
            p[horizontal] = a;
            p[vertical] = b;
            let center = layout.center(p, xy);
            let cell = Rect::from_center_size(center, Vec2::splat(layout.edge));
            let screen_cell = Rect::from_min_max(layout.screen(cell.min), layout.screen(cell.max));
            if p == game.maze.exit() {
                painter.rect_filled(
                    screen_cell.shrink(layout.scale),
                    0.0,
                    Color32::from_rgb(102, 153, 230),
                );
            }
            if p == [0; 4] {
                painter.rect_filled(
                    screen_cell.shrink(layout.scale),
                    0.0,
                    Color32::from_rgb(77, 204, 128),
                );
            }
            if game.state.portals && game.portals_available() {
                let portal_dirs = if xy { [7, 6, 5, 2] } else { [3, 0, 4, 1] };
                draw_portals(painter, layout, game, p, cell, portal_dirs);
            }
            if game.maze.wall(p, positive_h) || (!xy && (size[2] == 1 || size[3] == 1)) {
                let color = if game.maze.wall(p, positive_h) {
                    Color32::BLACK
                } else {
                    Color32::from_black_alpha(26)
                };
                painter.line_segment(
                    [
                        layout.screen(cell.right_top()),
                        layout.screen(cell.right_bottom()),
                    ],
                    Stroke::new(2.0 * layout.scale, color),
                );
            }
            if game.maze.wall(p, positive_v) || (!xy && (size[2] == 1 || size[3] == 1)) {
                let color = if game.maze.wall(p, positive_v) {
                    Color32::BLACK
                } else {
                    Color32::from_black_alpha(26)
                };
                painter.line_segment(
                    [
                        layout.screen(cell.left_bottom()),
                        layout.screen(cell.right_bottom()),
                    ],
                    Stroke::new(2.0 * layout.scale, color),
                );
            }
            if game.marked[game.maze.index(p)] {
                marker(painter, layout, p, xy);
            }
        }
    }
    let bounds = Rect::from_min_size(
        origin - Vec2::splat(layout.edge / 2.0),
        vec2(
            size[horizontal] as f32 * layout.edge,
            size[vertical] as f32 * layout.edge,
        ),
    );
    painter.rect_stroke(
        Rect::from_min_max(layout.screen(bounds.min), layout.screen(bounds.max)),
        0.0,
        Stroke::new(2.0 * layout.scale, Color32::BLACK),
        StrokeKind::Middle,
    );
    draw_symbols(painter, layout, bounds, xy);
}

fn draw_portals(
    painter: &egui::Painter,
    layout: &Layout,
    game: &Game,
    p: Position,
    cell: Rect,
    directions: [usize; 4],
) {
    let width = layout.edge / 4.0;
    let color = palette(color_index(game, p), true);
    let inset = 2.0;
    let bars = [
        Rect::from_min_max(
            cell.min + vec2(inset - width / 2.0, inset),
            pos2(cell.left() + inset + width / 2.0, cell.bottom()),
        ),
        Rect::from_min_max(
            pos2(cell.right() - width * 1.5, cell.top() + inset),
            pos2(cell.right() - width * 0.5, cell.bottom()),
        ),
        Rect::from_min_max(
            cell.min + vec2(inset, inset - width / 2.0),
            pos2(cell.right(), cell.top() + inset + width / 2.0),
        ),
        Rect::from_min_max(
            pos2(cell.left() + inset, cell.bottom() - width * 1.5),
            pos2(cell.right(), cell.bottom() - width * 0.5),
        ),
    ];
    for (direction, bar) in directions.into_iter().zip(bars) {
        if !game.maze.wall(p, direction) {
            painter.rect_filled(
                Rect::from_min_max(layout.screen(bar.min), layout.screen(bar.max)),
                0.0,
                color,
            );
        }
    }
}

fn draw_symbols(painter: &egui::Painter, layout: &Layout, bounds: Rect, xy: bool) {
    let edge = layout.edge.min(20.0);
    let top = pos2(bounds.center().x - edge * 0.4, bounds.top() - edge * 1.5);
    let side = pos2(bounds.left() - edge - 2.0, bounds.center().y - edge * 0.6);
    let (top_lines, side_lines): (&[[f32; 4]], &[[f32; 4]]) = if xy {
        (
            &[
                [0., 0., 0.25, 1.],
                [0.25, 1., 0.5, 0.],
                [0.5, 0., 0.75, 1.],
                [0.75, 1., 1., 0.],
            ],
            &[[0., 0., 0.8, 0.], [0.8, 0., 0., 1.], [0., 1., 0.8, 1.]],
        )
    } else {
        (
            &[[0., 0., 0.8, 1.], [0., 1., 0.8, 0.]],
            &[
                [0., 0., 0.4, 0.5],
                [0.4, 0.5, 0.8, 0.],
                [0.4, 0.5, 0.4, 1.2],
            ],
        )
    };
    for (origin, lines) in [(top, top_lines), (side, side_lines)] {
        for [x1, y1, x2, y2] in lines {
            painter.line_segment(
                [
                    layout.screen(origin + vec2(*x1, *y1) * edge),
                    layout.screen(origin + vec2(*x2, *y2) * edge),
                ],
                Stroke::new(3.0 * layout.scale, Color32::BLACK),
            );
        }
    }
}
