"""Exercise the built native app on an isolated X server with real X11 input.

Run: DISPLAY=:99 python3 tests/ui_smoke.py target/debug/hypercube-maze
Needs Xvfb (or an isolated X display), libXtst, and Pillow.
"""
import ctypes
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from PIL import ImageGrab

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / 'target/debug/hypercube-maze').resolve()
DISPLAY = os.environ.get('DISPLAY', ':99')
OUTPUT = ROOT / 'verification'
OUTPUT.mkdir(exist_ok=True)
STATE = OUTPUT / 'ui-smoke-state.json'
STATE.unlink(missing_ok=True)
x = ctypes.CDLL('libX11.so.6')
t = ctypes.CDLL('libXtst.so.6')
x.XOpenDisplay.argtypes = [ctypes.c_char_p]
x.XOpenDisplay.restype = ctypes.c_void_p
display = x.XOpenDisplay(DISPLAY.encode())
assert display, f'Cannot open {DISPLAY}'
x.XFlush.argtypes = [ctypes.c_void_p]
x.XSetInputFocus.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
x.XStringToKeysym.argtypes = [ctypes.c_char_p]
x.XStringToKeysym.restype = ctypes.c_ulong
x.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x.XKeysymToKeycode.restype = ctypes.c_uint
t.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
t.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
t.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]

def move(a, b):
    t.XTestFakeMotionEvent(display, -1, a, b, 0)
    x.XFlush(display)
    time.sleep(.08)

def button(down):
    t.XTestFakeButtonEvent(display, 1, down, 0)
    x.XFlush(display)
    time.sleep(.09)

def click(a, b):
    move(a, b)
    button(1)
    button(0)

def key(name):
    code = x.XKeysymToKeycode(display, x.XStringToKeysym(name.encode()))
    for down in (1, 0):
        t.XTestFakeKeyEvent(display, code, down, 0)
        x.XFlush(display)
        time.sleep(.09)

def state_matches(check, description):
    deadline = time.monotonic() + 4
    state = None
    while time.monotonic() < deadline:
        assert process.poll() is None, 'Native app exited unexpectedly'
        if STATE.exists():
            state = json.loads(STATE.read_text())
            if check(state):
                print(f'PASS: {description}', flush=True)
                return state
        time.sleep(.1)
    raise AssertionError(f'{description}: {state}')

def screenshot(name):
    time.sleep(.25)
    ImageGrab.grab(xdisplay=DISPLAY).crop((0, 0, 750, 850)).save(OUTPUT / f'{name}.png')

def launch():
    env = dict(os.environ, DISPLAY=DISPLAY, HYPERCUBE_MAZE_STATE=str(STATE))
    env.pop('WAYLAND_DISPLAY', None)
    log = open(OUTPUT / 'ui-smoke.log', 'a')
    app = subprocess.Popen([str(BINARY)], cwd=ROOT, env=env, stdout=log, stderr=log)
    for _ in range(50):
        tree = subprocess.check_output(['xwininfo', '-root', '-tree'], env=env, text=True)
        window = re.search(r'(0x[0-9a-f]+) "Maze Hypercube"', tree)
        if window:
            time.sleep(.8)
            x.XSetInputFocus(display, int(window[1], 16), 1, 0)
            x.XFlush(display)
            time.sleep(.6)
            return app
        assert app.poll() is None, (OUTPUT / 'ui-smoke.log').read_text()
        time.sleep(.1)
    raise AssertionError('Native window did not open')

process = launch()
try:
    baseline = state_matches(lambda s: s['spec']['number'] == 1, 'native startup and autosave')
    screenshot('desktop-play')
    key('space')
    state_matches(lambda s: s['markers'] == [0], 'keyboard marks cell')
    click(250, 780)
    state_matches(lambda s: s['porous'], 'porous walls control')
    key('Right')
    state_matches(lambda s: s['position'] == [0, 0, 0, 1], 'arrow keys move left view')
    key('d')
    state_matches(lambda s: s['position'] == [1, 0, 0, 1], 'WASD moves right view')
    key('r')
    state_matches(lambda s: s['position'] == [0]*4 and s['markers'] == [0], 'restart retains markers')
    # Any motion cancels a tap, even below the framework's drag threshold.
    move(140, 334)
    button(1)
    move(142, 334)
    button(0)
    time.sleep(2.2)
    state_matches(lambda s: s['position'] == [0]*4 and s['markers'] == [0], 'tiny drag leaves no marker')
    # The controller uses strict axis comparisons: equal deltas do nothing.
    move(140, 334)
    button(1)
    move(260, 454)
    button(0)
    time.sleep(2.2)
    state_matches(lambda s: s['position'] == [0]*4 and s['markers'] == [0], 'exact diagonal drag does not move or mark')
    click(140, 334)
    state_matches(lambda s: s['markers'] == [], 'stationary click toggles marker')
    click(140, 334)
    state_matches(lambda s: s['markers'] == [0], 'stationary click restores marker')
    move(140, 334)
    button(1)
    move(260, 334)
    button(0)
    state_matches(lambda s: s['position'] == [0, 0, 0, 1], 'drag left view')
    move(495, 334)
    button(1)
    move(495, 455)
    button(0)
    state_matches(lambda s: s['position'] == [0, 1, 0, 1], 'drag right view')
    click(350, 780)
    state_matches(lambda s: not s['porous'], 'normal walls control')
    click(515, 780)
    state_matches(lambda s: s['portals'], 'portals control')
    screenshot('desktop-portals')
    click(620, 839)
    paused = state_matches(lambda s: s['portals'], 'select opens')
    screenshot('desktop-selection')
    time.sleep(2.4)
    after = json.loads(STATE.read_text())
    assert after['elapsed_ms'] == paused['elapsed_ms'], 'Timer advanced in Select'
    print('PASS: timer pauses in Select', flush=True)
    click(260, 314)
    state_matches(lambda s: s['spec']['number'] == 100, 'Select exposes maze 100 without a purchase')
    screenshot('desktop-maze-100')
    click(351, 314)
    state_matches(lambda s: s['spec']['number'] == 1, 'Select wraps maze 100 to 1')
    # Standard/Complex and number changes in the Select panel.
    click(335, 282)
    state_matches(lambda s: s['spec']['complex'], 'complexity selection')
    click(351, 314)
    state_matches(lambda s: s['spec']['number'] == 2, 'next maze in Select')
    # Free Form -> Tesseract and change X from 2 to 3 in the wheel picker.
    click(280, 460)
    state_matches(lambda s: s['shape'] == 6, 'shape wheel selects Tesseract')
    click(380, 540)
    state_matches(lambda s: s['spec']['size'] == [3]*4, 'size wheel keeps Tesseract sides equal')
    key('Escape')
    state_matches(lambda s: s['position'] == [0]*4, 'selection resets generated maze')
    click(78, 780)
    state_matches(lambda s: s['spec']['number'] == 3, 'next maze clears previous game')
    # Hold until automatic movement latches, then release and stop it.
    move(375, 723)
    button(1)
    time.sleep(1.8)
    button(0)
    before = state_matches(lambda s: s['position'] != [0]*4, 'hold starts automatic best moves')
    click(375, 723)
    time.sleep(2.2)
    stopped = json.loads(STATE.read_text())
    time.sleep(2.2)
    assert json.loads(STATE.read_text())['position'] == stopped['position'], 'Automatic movement did not stop'
    print('PASS: stop automatic best moves', flush=True)
    key('space')
    snapshot = state_matches(lambda s: bool(s['markers']), 'saved progress contains markers')
    process.terminate()
    process.wait(timeout=5)
    process = launch()
    restored = state_matches(lambda s: s['position'] == snapshot['position'] and s['markers'] == snapshot['markers'], 'restart restores saved position and markers')
    assert restored['spec'] == snapshot['spec']
    screenshot('desktop-resumed')
    # Follow the real keyboard hint action to the exit, then acknowledge the modal.
    for _ in range(400):
        current = json.loads(STATE.read_text())
        if current['position'] == [n-1 for n in current['spec']['size']]:
            break
        key('b')
        key('b')
    else:
        raise AssertionError('Best move did not finish the maze')
    screenshot('desktop-completed')
    key('Tab')
    key('Return')
    state_matches(lambda s: s['completed'] == 1, 'completion dialog acknowledges solved maze')
    print('Native UI smoke test passed.', flush=True)
finally:
    process.terminate()
    process.wait(timeout=5)
