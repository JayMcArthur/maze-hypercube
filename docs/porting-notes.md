# Porting notes

The supplied `reference/ios/Play Page - Objective C.m` is the version-6.2 behavioral reference. The Python files are historical conversion attempts. They are not dependencies of the Rust application.

## Behavioral mapping

| Original behavior | Rust implementation |
| --- | --- |
| Version-620 seed, Darwin random sequence, ordered frontier, Standard/Complex bias and exit distances | `src/maze.rs` |
| Position, eight moves, porous walls, markers, restart, maze numbers 1–100, shape constraints, timer and persistence | `src/game.rs` |
| Best-move show/move alternation, released callback, quick repress and accelerating hold | `src/hint.rs` |
| Two plane views, cell colors, walls, portals, player, markers and hints | `src/view.rs` |
| Play, Select, wheel pickers, strict diagonal gestures, stationary taps and keyboard controls | `src/app.rs` |
| Local move click | `src/audio.rs` |
| Optional native framebuffer capture | `src/capture.rs` |

Displayed X/Y/Z/W correspond to controller W/Z/Y/X. Gesture direction uses the controller's strict comparisons: an exact diagonal does not move, and any pointer motion cancels a stationary tap. The timer carries fractional milliseconds and pauses outside Play, when unfocused and at the exit. Restart retains markers; changing the maze clears them.

## Verification

- The parity test compiles generation functions extracted from the actual Objective-C controller as C and compares every wall and exit distance in 104 cases: 13 shapes/sizes, maze numbers 1/2/37/100 and Standard/Complex. The largest case contains 640,000 cells.
- Model tests cover movement, boundaries, solving, markers, shape constraints, number wrapping, persistence, timer accuracy and hint scheduling.
- The native X11 smoke test exercises real pointer/keyboard input, tiny and diagonal drags, settings, wheel selection, Select 1→100→1 without a purchase, timer pause, hint hold/stop, save/resume and completion.
- Native Windows checks cover input, save/resume and framebuffer capture. Windows and Linux maze dumps matched in 18 additional cases. One posted-key run missed its keys; an unchanged rerun passed, so automated Windows injection does not replace interactive owner review.
- Both platforms' rendered framebuffers were inspected. Font/driver rasterization differs; cross-platform pixel equality is not claimed.

## Original references and remaining fidelity limits

[Apple's listing](https://apps.apple.com/us/app/maze-hypercube-lite/id378658863) and [lookup metadata](https://itunes.apple.com/lookup?id=378658863&country=us) identify Peter Kramer's version 6.2, bundle `com.domainname.mazehypercubeliteipad`. All five iPhone and five iPad screenshots were retrieved for comparison. The pictured 4D maze matches the older `210` seed noted in the controller comments; the port preserves the supplied controller's active `620` seed.

The supplied project lacks `QuartzFunView`, nib/storyboard files, other controllers and the active `tap11.aiff`. Play and Select appearance are reconstructed from source coordinates and official still images. Home supplies local play instructions, and audio uses a synthesized click. Complete pixel, sound and Home identity remain unverified.

The commented historical audio filename leads to [FreeSound sound 62708](https://freesound.org/people/hanstimm/sounds/62708/), tick91ED.aiff. Its public preview does not establish the identity or modifications of the active `tap11.aiff`, and is not shipped.

Online recovery checked exact app names, IDs, bundle identity and publisher, plus file indexes from 578 Internet Archive iOS collections (123,668 listed file entries). No matching original app bundle was identified. This checked filenames, not every compressed collection's contents. Unrelated candidates were identified by bundle ID and no downloaded executable was run. The [publisher site](https://www.kramerandkramersoftware.com/) and [its 2016 archive](https://web.archive.org/web/20160516190223/http://www.kramerandkramersoftware.com/) direct to Apple's store without the missing source or assets. No matching official Android release or gameplay recording was identified.

The user explicitly requested all 100 maze numbers per size and complexity. The desktop app implements that availability directly; iOS commerce is omitted. No open-source license is inferred for the owner's code. The bundled fonts retain their license in `assets/fonts/LICENSE.txt`.
