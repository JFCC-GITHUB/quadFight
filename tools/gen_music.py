#!/usr/bin/env python3
"""Compose and render QuadFight's background music (all original, MIT licensed).

Usage:  python3 tools/gen_music.py        (needs numpy + soundfile)
Writes assets/music/<style>.ogg (seamless loops) and assets/music/styles.json.

Songs are written as bars of 16th-note steps, e.g. "A4:2 C5:2 r:4":
note name + octave : length in 16ths ("r" = rest).  Every style is its own function below.
"""
import json
import math
import os

import numpy as np
import soundfile as sf

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "music")

PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
CHORDS = {  # name: (root pitch class, intervals)
    "Am": (9, [0, 3, 7]), "F": (5, [0, 4, 7]), "G": (7, [0, 4, 7]), "C": (0, [0, 4, 7]),
    "E": (4, [0, 4, 7]), "Dm": (2, [0, 3, 7]), "Em": (4, [0, 3, 7]),
    "Cmaj7": (0, [0, 4, 7, 11]), "Am7": (9, [0, 3, 7, 10]), "Fmaj7": (5, [0, 4, 7, 11]),
    "Em7": (4, [0, 3, 7, 10]), "Dm7": (2, [0, 3, 7, 10]),
}


def midi(name):
    acc, rest = 0, name[1:]
    while rest and rest[0] in "#b":
        acc += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + PC[name[0]] + acc


def hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def chord(name, octave):
    pc, iv = CHORDS[name]
    root = 12 * (octave + 1) + pc
    return [root + i for i in iv]


def root_midi(name, octave):
    return 12 * (octave + 1) + CHORDS[name][0]


def parse_bar(text, bar):
    """'A4:2 r:2' -> [(step, midi, length)] with absolute step = bar*16 + offset."""
    out, pos = [], 0
    for tok in text.split():
        n, ln = tok.split(":")
        ln = int(ln)
        if n != "r":
            out.append((bar * 16 + pos, midi(n), ln))
        pos += ln
    assert pos == 16, f"bar {bar} has {pos} steps: {text}"
    return out


def parse(bars, start=0):
    notes = []
    for i, b in enumerate(bars):
        notes += parse_bar(b, start + i)
    return notes


# ------------------------------------------------------------------ DSP helpers

def tvec(n):
    return np.arange(n) / SR


def env(n, a=0.01, r=0.05):
    e = np.ones(n)
    na, nr = min(int(a * SR), n), min(int(r * SR), n)
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def additive(f, n, amps, vib=None, detune=0.0):
    """Sum of harmonics (band-limited). amps: list/array of per-harmonic gains."""
    t = tvec(n)
    fm = f * (1 + detune)
    if vib is not None:
        phase = 2 * np.pi * np.cumsum(fm * vib) / SR
    else:
        phase = 2 * np.pi * fm * t
    sig = np.zeros(n)
    for k, a in enumerate(amps, start=1):
        if fm * k > SR * 0.45:
            break
        sig += a * np.sin(k * phase)
    return sig


def saw_amps(k=14, p=1.0):
    return [1.0 / (i ** p) for i in range(1, k + 1)]


def square_amps(k=15):
    return [1.0 / i if i % 2 else 0.0 for i in range(1, k + 1)]


def brass(f, dur, level=1.0):
    n = int((dur + 0.06) * SR)
    t = tvec(n)
    vib = 1 + 0.005 * np.sin(2 * np.pi * 5.6 * t) * np.clip((t - 0.15) / 0.25, 0, 1)
    phase = 2 * np.pi * np.cumsum(f * vib) / SR
    sig = np.zeros(n)
    for k in range(1, 16):
        if f * k > SR * 0.45:
            break
        # brassy "blat": upper harmonics bloom after the attack
        bloom = np.clip(t / (0.025 + 0.012 * k), 0, 1)
        sig += (1.0 / k ** 0.85) * bloom * np.sin(k * phase)
    sig += 0.5 * np.roll(sig, 17)  # thicken a little
    return level * sig * env(n, 0.018, 0.06) * 0.35


def guitar(root_m, dur, mute=False, level=1.0):
    n = int((dur + 0.05) * SR)
    t = tvec(n)
    x = np.zeros(n)
    for m, g in ((root_m, 1.0), (root_m + 7, 0.9), (root_m + 12, 0.7)):
        x += g * additive(hz(m), n, saw_amps(12, 0.9))
    x = np.tanh(x * 0.9)  # power-chord distortion
    x = np.tanh(x * 3.0)
    x = np.convolve(x, np.ones(3) / 3, mode="same")
    if mute:
        e = np.exp(-t * 16) * env(n, 0.002, 0.02)
    else:
        e = np.exp(-t * 1.4) * env(n, 0.004, 0.08)
    return level * x * e * 0.3


def bass_note(f, dur, level=1.0):
    n = int((dur + 0.03) * SR)
    t = tvec(n)
    x = additive(f, n, [1.0, 0.55, 0.35, 0.2, 0.1])
    x += 0.5 * np.sin(2 * np.pi * f * 0.5 * t)
    x = np.tanh(x * 1.2)
    return level * x * (0.6 + 0.4 * np.exp(-t * 6)) * env(n, 0.004, 0.03) * 0.5


def pad_chord(freqs, dur, level=1.0, bright=6):
    n = int((dur + 0.4) * SR)
    sig = np.zeros(n)
    for f in freqs:
        for d in (-0.004, 0.004):
            sig += additive(f, n, saw_amps(bright, 1.2), detune=d)
    return level * sig * env(n, 0.35, 0.4) * 0.07


def kick(level=1.0, depth=40.0, length=0.28):
    n = int(length * SR)
    t = tvec(n)
    f = depth + 120 * np.exp(-t * 32)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return level * (np.sin(ph) * np.exp(-t * 11) + 0.25 * np.exp(-t * 400) * np.random.uniform(-1, 1, n))


def snare(level=1.0, tone=190.0, length=0.22, noise=0.8):
    n = int(length * SR)
    t = tvec(n)
    nz = np.random.uniform(-1, 1, n)
    nz = nz - np.roll(nz, 1) * 0.6  # brighten
    return level * (noise * nz * np.exp(-t * 20) + 0.5 * np.sin(2 * np.pi * tone * t) * np.exp(-t * 28))


def hat(level=1.0, length=0.05, decay=70.0):
    n = int(length * SR)
    t = tvec(n)
    nz = np.random.uniform(-1, 1, n)
    nz = nz - np.roll(nz, 1)
    nz = nz - np.roll(nz, 1)
    return level * 0.5 * nz * np.exp(-t * decay)


def crash(level=1.0, length=1.8):
    return hat(level * 0.9, length, 2.6)


def tom(f0, level=1.0, length=0.3):
    n = int(length * SR)
    t = tvec(n)
    f = f0 * (1 + 0.5 * np.exp(-t * 18))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return level * np.sin(ph) * np.exp(-t * 9)


def orch_hit(root_m, level=1.0):
    n = int(0.9 * SR)
    t = tvec(n)
    sig = np.zeros(n)
    for m in (root_m, root_m + 7, root_m + 12, root_m + 19, root_m + 24):
        sig += additive(hz(m), n, saw_amps(10, 0.9))
    return level * 0.12 * sig * np.exp(-t * 4.5) * env(n, 0.004, 0.1)


def fft_conv(x, ir):
    n = 1
    while n < len(x) + len(ir):
        n *= 2
    return np.fft.irfft(np.fft.rfft(x, n) * np.fft.rfft(ir, n), n)[:len(x)]


class Song:
    def __init__(self, bpm, bars, tail=3.0):
        self.step = 60.0 / bpm / 4.0
        self.bars = bars
        self.n = int(round(bars * 16 * self.step * SR))
        self.tail = int(tail * SR)
        self.L = np.zeros(self.n + self.tail)
        self.R = np.zeros(self.n + self.tail)

    def dur(self, steps):
        return steps * self.step

    def add(self, step, sig, gain=1.0, pan=0.0):
        s = int(round(step * self.step * SR))
        if s >= len(self.L):
            return
        e = min(s + len(sig), len(self.L))
        sig = sig[:e - s] * gain
        a = (pan + 1.0) * math.pi / 4.0
        self.L[s:e] += sig * math.cos(a)
        self.R[s:e] += sig * math.sin(a)

    def render(self, reverb=0.14, rv_time=0.45, seed=1):
        rng = np.random.default_rng(seed)
        L, R = self.L, self.R
        m = int(1.6 * SR)
        decay = np.exp(-tvec(m) / rv_time)
        for_l = rng.uniform(-1, 1, m) * decay
        for_r = rng.uniform(-1, 1, m) * decay
        norm = 1.0 / math.sqrt(np.sum(decay ** 2) / 3)
        L = L + reverb * fft_conv(L, for_l) * norm * 0.12
        R = R + reverb * fft_conv(R, for_r) * norm * 0.12
        n = self.n
        tl = min(self.tail, len(L) - n)
        L[:tl] += L[n:n + tl]  # fold the tail onto the start: seamless loop
        R[:tl] += R[n:n + tl]
        out = np.stack([L[:n], R[:n]], axis=1)
        out = np.tanh(out * 1.15)
        peak = np.max(np.abs(out))
        return (out / peak * 0.7).astype(np.float32)


def melody_voice(song, notes, fn, gain=1.0, pan=0.0, shift=0, legato=0.92):
    for step, m, ln in notes:
        song.add(step, fn(hz(m + shift), song.dur(ln * legato)), gain, pan)


# ================================================================== SUPER ROBOT
# Original heroic "mecha anime" theme: brass fanfare, hard rock drums, pounding bass.
# A minor, 160 BPM, 24 bars (~36 s).

ROBOT_CHORDS = (["Am"] * 2 + ["Am", "Am", "F", "G", "Am", "Am", "F", "E"]
                + ["F", "G", "Am", "C", "F", "G", "E", "Am"]
                + ["Dm", "G", "C", "E"] + ["F", "G"])

ROBOT_LEAD = [
    # intro fanfare (2)
    "A4:4 A4:2 E5:6 A5:4", "C6:4 B5:4 A5:8",
    # verse (8)
    "r:2 A4:2 C5:2 E5:4 D5:2 C5:2 r:2", "B4:4 A4:4 r:2 A4:2 B4:2 C5:2",
    "r:2 C5:2 F5:2 A5:4 G5:2 F5:2 r:2", "G5:4 D5:4 r:2 D5:2 E5:2 F5:2",
    "r:2 A4:2 C5:2 E5:4 D5:2 C5:2 r:2", "B4:4 C5:4 D5:4 E5:4",
    "r:2 C5:2 F5:2 A5:4 G5:2 F5:2 r:2", "E5:4 B4:2 G#4:2 B4:4 E5:4",
    # chorus (8)
    "A5:4 A5:2 G5:2 F5:4 C5:4", "D5:4 D5:2 E5:2 G5:4 B5:4",
    "A5:6 E5:2 A5:4 C6:4", "B5:4 G5:4 E5:4 G5:4",
    "A5:4 A5:2 G5:2 F5:4 C5:4", "D5:4 D5:2 E5:2 G5:4 B5:4",
    "E6:8 B5:4 G#5:4", "A5:12 r:4",
    # bridge (4)
    "D5:2 F5:2 A5:2 D6:6 C6:2 A5:2", "B5:2 D6:2 G5:2 B5:6 A5:2 G5:2",
    "C6:2 E6:2 G5:2 C6:6 B5:2 G5:2", "E6:2 D6:2 C6:2 B5:6 G#5:2 E5:2",
    # turnaround (2)
    "A5:4 C6:4 F6:4 C6:4", "D6:4 B5:4 G5:4 r:4",
]


def robot_drums(song, bar, kind):
    b = bar * 16
    K, S, H = kick(1.0), snare(0.9), hat(0.55)
    if kind == "intro":
        song.add(b, crash(0.8))
        for s in (0, 4, 8, 12):
            song.add(b + s, tom(95, 0.9))
        if bar == 1:
            for i in range(8, 16):
                song.add(b + i, snare(0.25 + 0.08 * (i - 8)), 1.0)
        return
    if kind == "verse":
        for s in (0, 6, 8, 10):
            song.add(b + s, K, 0.95)
        for s in (4, 12):
            song.add(b + s, S)
        for s in range(0, 16, 2):
            song.add(b + s, H, 0.7 if s % 4 else 1.0)
    elif kind == "chorus":
        for s in (0, 4, 8, 12):
            song.add(b + s, K, 1.0)
        for s in (4, 12):
            song.add(b + s, S)
        for s in (2, 6, 10, 14):
            song.add(b + s, hat(0.7, 0.18, 20), 0.8)
        for s in (0, 8):
            song.add(b + s, H, 0.7)
    elif kind == "bridge":
        for s in (0, 8):
            song.add(b + s, K, 1.0)
        for s in (4, 12):
            song.add(b + s, S)
        for s in range(0, 16):
            song.add(b + s, H, 0.45 + 0.02 * s)
    elif kind == "turn":
        for s in (0, 4, 8, 12):
            song.add(b + s, K, 1.0)
        for s in (4, 12):
            song.add(b + s, S)


def robot_fill(song, bar):
    b = bar * 16
    seq = [(12, 190, 0.8), (13, 160, 0.85), (14, 130, 0.9), (15, 100, 1.0)]
    for s, f, g in seq:
        song.add(b + s, tom(f, g))


def make_robot():
    song = Song(160, 24)
    kinds = ["intro"] * 2 + ["verse"] * 8 + ["chorus"] * 8 + ["bridge"] * 4 + ["turn"] * 2
    # --- lead (brass) + octave-below doubling in chorus/bridge
    lead = parse(ROBOT_LEAD)
    melody_voice(song, lead, lambda f, d: brass(f, d), 1.0, 0.0)
    thick = [x for x in lead if 10 <= x[0] // 16 < 22 or x[0] // 16 < 2]
    melody_voice(song, thick, lambda f, d: brass(f, d), 0.55, -0.35, shift=-12)
    melody_voice(song, [x for x in lead if 10 <= x[0] // 16 < 18], lambda f, d: brass(f, d), 0.4, 0.4, shift=-5)
    # --- per-bar accompaniment
    for bar in range(24):
        name, kind, b = ROBOT_CHORDS[bar], kinds[bar], bar * 16
        root = root_midi(name, 2)
        # drums
        robot_drums(song, bar, kind)
        if bar in (9, 17, 21):
            robot_fill(song, bar)
        if bar == 23:
            for s in range(8, 16):
                song.add(b + s, tom(260 - (s - 8) * 20, 0.8))
        # hits
        if bar in (0, 10, 14, 18):
            song.add(b, orch_hit(root + 12, 1.0))
        if bar in (10, 14):
            song.add(b, crash(0.9))
        # bass
        if kind == "intro":
            for s in (0, 4, 8, 12):
                song.add(b + s, bass_note(hz(root), song.dur(3.5)), 0.9)
        elif kind == "verse":
            for i, s in enumerate(range(0, 16, 2)):
                m = root + (12 if i % 4 == 3 else 0)
                song.add(b + s, bass_note(hz(m), song.dur(1.7)))
        else:
            for i, s in enumerate(range(0, 16, 2)):
                m = root + (12 if i % 2 else 0)
                song.add(b + s, bass_note(hz(m), song.dur(1.7)), 1.05)
        # rhythm guitar
        gl = 0.0
        if kind == "verse":
            for s in range(0, 16, 2):
                song.add(b + s, guitar(root + 12, song.dur(1.5), mute=True, level=0.55 if s % 4 else 0.85), 1.0, -0.3)
        elif kind in ("chorus", "bridge"):
            song.add(b, guitar(root + 12, song.dur(7.5), level=1.0), 1.0, -0.4)
            song.add(b + 8, guitar(root + 12, song.dur(7.5), level=0.95), 1.0, -0.4)
            song.add(b, guitar(root + 12, song.dur(7.5), level=0.7), 1.0, 0.4)
            song.add(b + 8, guitar(root + 12, song.dur(7.5), level=0.7), 1.0, 0.4)
        elif kind == "turn":
            song.add(b, guitar(root + 12, song.dur(7.5)), 1.0, -0.3)
            song.add(b + 8, guitar(root + 12, song.dur(7.5)), 1.0, -0.3)
        # string pad
        if kind in ("chorus", "bridge", "turn"):
            song.add(b, pad_chord([hz(m) for m in chord(name, 3)], song.dur(16), 1.0, bright=8), 0.9, 0.0)
    return song.render(reverb=0.16)


# ================================================================== CHIPTUNE

CHIP_CHORDS = (["C", "G", "Am", "F", "C", "G", "F", "G"]
               + ["C", "Em", "Am", "F", "Dm", "G", "C", "G"])
CHIP_LEAD = [
    "E5:2 G5:2 C6:4 B5:2 G5:2 E5:4", "D5:2 G5:2 B5:4 A5:2 G5:2 D5:4",
    "C5:2 E5:2 A5:4 G5:2 E5:2 C5:4", "F5:4 E5:2 D5:2 C5:4 A4:4",
    "G5:4 E5:2 G5:2 C6:8", "B5:4 G5:2 B5:2 D6:8",
    "A5:4 F5:2 A5:2 C6:4 A5:4", "G5:2 A5:2 B5:2 D6:2 G6:8",
    "E5:1 G5:1 C6:1 G5:1 E5:1 G5:1 C6:1 G5:1 E5:1 G5:1 C6:1 G5:1 E5:1 G5:1 C6:1 G5:1",
    "E5:1 G5:1 B5:1 G5:1 E5:1 G5:1 B5:1 G5:1 E5:1 G5:1 B5:1 G5:1 E5:1 G5:1 B5:1 G5:1",
    "E5:1 A5:1 C6:1 A5:1 E5:1 A5:1 C6:1 A5:1 E5:1 A5:1 C6:1 A5:1 E5:1 A5:1 C6:1 A5:1",
    "F5:1 A5:1 C6:1 A5:1 F5:1 A5:1 C6:1 A5:1 F5:1 A5:1 C6:1 A5:1 F5:1 A5:1 C6:1 A5:1",
    "D5:4 F5:4 A5:4 D6:4", "D5:4 G5:4 B5:4 D6:4",
    "E5:2 G5:2 C6:4 E6:8", "B5:4 A5:4 G5:8",
]


def square_note(f, dur, duty=0.5, level=1.0):
    n = int((dur + 0.02) * SR)
    t = tvec(n)
    x = np.where(fposmod(f * t, 1.0) < duty, 1.0, -1.0)
    return level * x * env(n, 0.003, 0.02) * 0.22


def fposmod(a, b):
    return a - np.floor(a / b) * b


def tri_note(f, dur, level=1.0):
    n = int((dur + 0.02) * SR)
    t = tvec(n)
    x = 4 * np.abs(fposmod(f * t, 1.0) - 0.5) - 1
    return level * x * env(n, 0.003, 0.02) * 0.5


def make_chip():
    song = Song(150, 16)
    lead = parse(CHIP_LEAD)
    melody_voice(song, lead, lambda f, d: square_note(f, d, 0.25), 1.0, -0.15)
    # echo voice: same notes a 16th later, quieter (classic chip trick)
    echo = [(s + 3, m, ln) for s, m, ln in lead]
    melody_voice(song, echo, lambda f, d: square_note(f, d, 0.125), 0.35, 0.3)
    for bar in range(16):
        name, b = CHIP_CHORDS[bar], bar * 16
        root = root_midi(name, 2)
        notes = chord(name, 4)
        for i, s in enumerate(range(0, 16, 2)):
            m = root + (12 if i % 2 else 0)
            song.add(b + s, tri_note(hz(m), song.dur(1.8)), 1.0, 0.0)
        for i, s in enumerate(range(0, 16, 1)):  # quiet arpeggio under the A theme
            if bar < 8:
                m = notes[i % 3]
                song.add(b + s, square_note(hz(m), song.dur(0.9), 0.125, 0.4), 1.0, 0.35)
        for s in (0, 8):
            song.add(b + s, kick(0.9, 55, 0.18))
        for s in (4, 12):
            song.add(b + s, snare(0.55, 220, 0.12, 1.0))
        for s in range(0, 16, 2):
            song.add(b + s, hat(0.5, 0.03, 120), 0.7)
    return song.render(reverb=0.06, rv_time=0.25)


# ================================================================== SYNTHWAVE

SYN_CHORDS = (["Am", "F", "C", "G"] * 2 + ["F", "G", "Am", "Am", "F", "G", "E", "E"])
SYN_LEAD = [
    "E5:6 D5:2 C5:4 A4:4", "C5:6 A4:2 F5:4 E5:4", "G5:6 E5:2 C5:4 E5:4", "D5:6 B4:2 G4:4 D5:4",
    "A5:6 G5:2 E5:4 C5:4", "A5:6 F5:2 C6:4 A5:4", "G5:6 E5:2 G5:2 C6:6", "B5:6 G5:2 D5:4 B4:4",
    "C6:8 A5:4 F5:4", "B5:8 G5:4 D5:4", "A5:6 C6:2 E6:8", "E6:4 D6:4 C6:4 A5:4",
    "C6:8 A5:4 F5:4", "D6:8 B5:4 G5:4", "G#5:4 B5:4 E6:8", "D6:4 B5:4 G#5:4 E5:4",
]


def saw_pluck(f, dur, decay=9.0, level=1.0):
    n = int((dur + 0.05) * SR)
    t = tvec(n)
    x = additive(f, n, saw_amps(10, 1.0)) + additive(f, n, saw_amps(10, 1.0), detune=0.006)
    return level * x * np.exp(-t * decay) * env(n, 0.002, 0.03) * 0.14


def synth_lead(f, dur, level=1.0):
    n = int((dur + 0.08) * SR)
    t = tvec(n)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.0 * t) * np.clip((t - 0.1) / 0.3, 0, 1)
    x = additive(f, n, saw_amps(12, 0.9), vib=vib) + additive(f, n, saw_amps(12, 0.9), vib=vib, detune=0.005)
    return level * x * env(n, 0.012, 0.09) * 0.16


def make_synth():
    song = Song(118, 16)
    lead = parse(SYN_LEAD)
    melody_voice(song, lead, synth_lead, 1.0, 0.0)
    melody_voice(song, [(s + 3, m, ln) for s, m, ln in lead], synth_lead, 0.28, 0.45)  # dotted echo
    for bar in range(16):
        name, b = SYN_CHORDS[bar], bar * 16
        root = root_midi(name, 2)
        notes = chord(name, 4)
        song.add(b, pad_chord([hz(m) for m in chord(name, 3)], song.dur(16), 1.0, 6), 1.0, 0.0)
        for s in range(0, 16, 2):  # pulsing 8th bass
            song.add(b + s, bass_note(hz(root + (12 if s % 8 == 6 else 0)), song.dur(1.8)), 1.0)
        seq = [notes[0], notes[1], notes[2], notes[1] + 12]
        for i, s in enumerate(range(0, 16)):  # 16th arpeggio, panned
            song.add(b + s, saw_pluck(hz(seq[i % 4]), song.dur(0.9)), 0.8, -0.4 if i % 2 else 0.4)
        for s in (0, 4, 8, 12):
            song.add(b + s, kick(1.0, 45, 0.3))
        for s in (4, 12):
            song.add(b + s, snare(0.8, 200, 0.3, 1.0))
        for s in range(0, 16, 2):
            song.add(b + s, hat(0.55, 0.04, 90), 0.8)
        song.add(b + 2, hat(0.7, 0.2, 18), 0.8)
        song.add(b + 10, hat(0.7, 0.2, 18), 0.8)
    return song.render(reverb=0.24, rv_time=0.6)


# ================================================================== CHILL

CALM_CHORDS = ["Cmaj7", "Am7", "Fmaj7", "G", "Cmaj7", "Am7", "Fmaj7", "G",
               "Em7", "Am7", "Dm7", "G", "Fmaj7", "Em7", "Dm7", "Cmaj7"]
CALM_LEAD = [
    "E5:6 D5:2 C5:4 r:4", "A4:4 C5:4 E5:8", "F5:6 E5:2 C5:4 A4:4", "D5:8 B4:4 r:4",
    "G5:6 E5:2 D5:4 C5:4", "C5:4 E5:4 A5:8", "A5:6 G5:2 F5:4 C5:4", "B4:4 D5:4 G5:8",
    "G5:8 E5:4 B4:4", "E5:6 C5:2 A4:8", "F5:8 D5:4 A4:4", "G4:4 B4:4 D5:8",
    "A5:6 C6:2 A5:8", "G5:6 E5:2 B4:8", "F5:4 A5:4 D6:8", "E6:8 C6:4 G5:4",
]


def epiano(f, dur, level=1.0):
    n = int((dur + 0.3) * SR)
    t = tvec(n)
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 5)
    x += 0.12 * np.sin(2 * np.pi * 4 * f * t) * np.exp(-t * 14)
    return level * x * np.exp(-t * 2.4) * env(n, 0.006, 0.25) * 0.3


def soft_pad(freqs, dur, level=1.0):
    n = int((dur + 0.6) * SR)
    t = tvec(n)
    sig = np.zeros(n)
    for f in freqs:
        for d in (-0.003, 0.003):
            sig += np.sin(2 * np.pi * f * (1 + d) * t) + 0.3 * np.sin(2 * np.pi * 2 * f * (1 + d) * t)
    return level * sig * env(n, 0.7, 0.7) * 0.05


def make_calm():
    song = Song(84, 16, tail=3.5)
    melody_voice(song, parse(CALM_LEAD), epiano, 1.0, 0.1, legato=1.0)
    for bar in range(16):
        name, b = CALM_CHORDS[bar], bar * 16
        root = root_midi(name, 2)
        song.add(b, soft_pad([hz(m) for m in chord(name, 3)], song.dur(16)), 1.0, 0.0)
        for s in (0, 8):
            song.add(b + s, tri_note(hz(root), song.dur(7.5), 1.0), 1.0)
        for i, m in enumerate(chord(name, 4)):  # gentle rolled chord
            song.add(b + 2 + i * 0.6, epiano(hz(m), song.dur(5), 0.35), 1.0, -0.3)
        song.add(b, kick(0.6, 50, 0.3))
        song.add(b + 6, kick(0.45, 50, 0.3))
        song.add(b + 10, kick(0.5, 50, 0.3))
        for s in (4, 12):
            song.add(b + s, snare(0.35, 180, 0.25, 1.2))
        for s in range(0, 16, 2):
            song.add(b + s, hat(0.4, 0.05, 60), 0.5 if s % 4 else 0.7)
    return song.render(reverb=0.3, rv_time=0.8)


# ================================================================== main

STYLES = [
    {"id": "robot", "name": "Super Robot", "desc": "Heroic mecha-anime rock (default)", "fn": make_robot},
    {"id": "chip", "name": "Chiptune", "desc": "Bouncy 8-bit adventure", "fn": make_chip},
    {"id": "synth", "name": "Synthwave", "desc": "Neon 80s night drive", "fn": make_synth},
    {"id": "calm", "name": "Chill", "desc": "Soft and relaxed", "fn": make_calm},
]


def main(only=None):
    os.makedirs(OUT, exist_ok=True)
    np.random.seed(7)
    for s in STYLES:
        if only and s["id"] not in only:
            continue
        audio = s["fn"]()
        path = os.path.join(OUT, s["id"] + ".ogg")
        sf.write(path, audio, SR, format="OGG", subtype="VORBIS")
        print(f"{s['id']:6s} {len(audio) / SR:5.1f}s  {os.path.getsize(path) / 1024:6.0f} KB")
    with open(os.path.join(OUT, "styles.json"), "w") as f:
        json.dump({"styles": [{k: v for k, v in s.items() if k != "fn"} for s in STYLES]}, f, indent=1)


if __name__ == "__main__":
    import sys
    main(sys.argv[1:] or None)
