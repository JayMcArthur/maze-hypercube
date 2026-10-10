use std::time::{Duration, Instant};

pub enum Tick {
    Wait,
    Advance,
    Finished,
}

/// The controller keeps a scheduled callback alive after release. Repressing
/// before it fires restarts the hold timer from that callback, not the press.
pub struct HeldHint {
    deadline: Instant,
    interval: f32,
    pub automatic: bool,
    active: bool,
    again: bool,
}

impl HeldHint {
    pub fn new(now: Instant) -> Self {
        Self {
            deadline: now + Duration::from_millis(500),
            interval: 0.5,
            automatic: false,
            active: true,
            again: false,
        }
    }

    pub fn repress(&mut self) {
        self.interval = 0.5;
        self.automatic = false;
        self.again = true;
        self.active = false;
    }

    pub fn release(&mut self) {
        if !self.automatic {
            self.again = false;
            self.active = false;
        }
    }

    pub fn tick(&mut self, now: Instant, pointer_shown: bool) -> Tick {
        if now < self.deadline {
            return Tick::Wait;
        }
        if self.active {
            self.interval *= 0.9;
            if self.interval < 0.4 {
                self.interval = if pointer_shown { 0.3 } else { 0.2 };
                self.automatic = true;
            }
            self.deadline = now + Duration::from_secs_f64(self.interval as f64);
            Tick::Advance
        } else if self.again {
            self.again = false;
            self.active = true;
            self.deadline = now + Duration::from_millis(500);
            Tick::Wait
        } else {
            Tick::Finished
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn release_cancels_hold_but_repress_waits_for_the_pending_callback() {
        let start = Instant::now();
        let mut hint = HeldHint::new(start);
        hint.release();
        assert!(matches!(
            hint.tick(start + Duration::from_millis(500), true),
            Tick::Finished
        ));
        let mut hint = HeldHint::new(start);
        hint.release();
        hint.repress();
        assert!(matches!(
            hint.tick(start + Duration::from_millis(500), false),
            Tick::Wait
        ));
        assert!(matches!(
            hint.tick(start + Duration::from_millis(999), false),
            Tick::Wait
        ));
        assert!(matches!(
            hint.tick(start + Duration::from_secs(1), false),
            Tick::Advance
        ));
    }

    #[test]
    fn accelerating_hold_latches_after_release_and_repress_stops_it() {
        let start = Instant::now();
        let mut hint = HeldHint::new(start);
        let first = start + Duration::from_millis(500);
        assert!(matches!(hint.tick(first, true), Tick::Advance));
        let second = hint.deadline;
        assert!(matches!(hint.tick(second, false), Tick::Advance));
        assert!(!hint.automatic);
        let third = hint.deadline;
        assert!(matches!(hint.tick(third, true), Tick::Advance));
        assert!(hint.automatic);
        hint.release();
        let next = hint.deadline;
        assert!(matches!(hint.tick(next, false), Tick::Advance));
        hint.repress();
        assert!(!hint.automatic);
        hint.release();
        assert!(matches!(hint.tick(hint.deadline, true), Tick::Finished));
    }
}
