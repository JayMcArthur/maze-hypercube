#[cfg(target_os = "linux")]
use std::ffi::{c_char, c_int, c_void};
use std::sync::mpsc;

pub struct Audio {
    sender: mpsc::SyncSender<()>,
}

impl Audio {
    pub fn new() -> Self {
        let (sender, receiver) = mpsc::sync_channel(4);
        std::thread::spawn(move || {
            if let Err(error) = play_clicks(receiver) {
                eprintln!("Move sound unavailable: {error}");
            }
        });
        Self { sender }
    }
    pub fn click(&self) {
        let _ = self.sender.try_send(());
    }
}

#[repr(C)]
#[cfg(target_os = "linux")]
struct SampleSpec {
    format: c_int,
    rate: u32,
    channels: u8,
}
#[repr(C)]
#[cfg(target_os = "linux")]
struct BufferAttr {
    maxlength: u32,
    tlength: u32,
    prebuf: u32,
    minreq: u32,
    fragsize: u32,
}

fn click_samples() -> Vec<i16> {
    // tap11.aiff was not supplied; use a short decaying click for local play.
    (0..2205)
        .map(|i| {
            let t = i as f64 / 44100.0;
            ((t * 1700.0 * std::f64::consts::TAU).sin() * (-t * 180.0).exp() * 9000.0) as i16
        })
        .collect()
}

#[cfg(target_os = "windows")]
fn play_clicks(receiver: mpsc::Receiver<()>) -> Result<(), Box<dyn std::error::Error>> {
    #[link(name = "winmm")]
    unsafe extern "system" {
        fn PlaySoundW(sound: *const u16, module: *mut std::ffi::c_void, flags: u32) -> i32;
    }
    let samples = click_samples();
    let length = (samples.len() * 2) as u32;
    let mut wave = Vec::new();
    wave.extend_from_slice(b"RIFF");
    wave.extend_from_slice(&(36 + length).to_le_bytes());
    wave.extend_from_slice(b"WAVEfmt ");
    wave.extend_from_slice(&16_u32.to_le_bytes());
    wave.extend_from_slice(&1_u16.to_le_bytes());
    wave.extend_from_slice(&1_u16.to_le_bytes());
    wave.extend_from_slice(&44100_u32.to_le_bytes());
    wave.extend_from_slice(&88200_u32.to_le_bytes());
    wave.extend_from_slice(&2_u16.to_le_bytes());
    wave.extend_from_slice(&16_u16.to_le_bytes());
    wave.extend_from_slice(b"data");
    wave.extend_from_slice(&length.to_le_bytes());
    for sample in samples {
        wave.extend_from_slice(&sample.to_le_bytes());
    }
    while receiver.recv().is_ok() {
        // SND_MEMORY | SND_NODEFAULT, synchronous: wave stays alive throughout playback.
        if unsafe { PlaySoundW(wave.as_ptr().cast(), std::ptr::null_mut(), 0x4 | 0x2) } == 0 {
            return Err("Windows could not play the move sound".into());
        }
    }
    Ok(())
}

#[cfg(target_os = "linux")]
fn play_clicks(receiver: mpsc::Receiver<()>) -> Result<(), Box<dyn std::error::Error>> {
    // Runtime loading keeps Linux/WSLg builds independent of PulseAudio headers.
    // Only this audio worker owns the stream and its library.
    unsafe {
        let library = libloading::Library::new("libpulse-simple.so.0")?;
        let new = library.get::<unsafe extern "C" fn(
            *const c_char,
            *const c_char,
            c_int,
            *const c_char,
            *const c_char,
            *const SampleSpec,
            *const c_void,
            *const BufferAttr,
            *mut c_int,
        ) -> *mut c_void>(b"pa_simple_new\0")?;
        let write = library.get::<unsafe extern "C" fn(
            *mut c_void,
            *const c_void,
            usize,
            *mut c_int,
        ) -> c_int>(b"pa_simple_write\0")?;
        let drain = library
            .get::<unsafe extern "C" fn(*mut c_void, *mut c_int) -> c_int>(b"pa_simple_drain\0")?;
        let free = library.get::<unsafe extern "C" fn(*mut c_void)>(b"pa_simple_free\0")?;
        let mut error = 0;
        let spec = SampleSpec {
            format: 3,
            rate: 44_100,
            channels: 1,
        }; // PA_SAMPLE_S16LE
        let buffer = BufferAttr {
            maxlength: u32::MAX,
            tlength: 2206,
            prebuf: 0,
            minreq: u32::MAX,
            fragsize: u32::MAX,
        };
        let stream = new(
            std::ptr::null(),
            c"Maze Hypercube".as_ptr(),
            1,
            std::ptr::null(),
            c"Move".as_ptr(),
            &spec,
            std::ptr::null(),
            &buffer,
            &mut error,
        );
        if stream.is_null() {
            return Err(format!("PulseAudio error {error}").into());
        }
        let samples = click_samples();
        while receiver.recv().is_ok() {
            if write(
                stream,
                samples.as_ptr().cast(),
                samples.len() * 2,
                &mut error,
            ) < 0
                || drain(stream, &mut error) < 0
            {
                free(stream);
                return Err(format!("PulseAudio playback error {error}").into());
            }
        }
        free(stream);
    }
    Ok(())
}
