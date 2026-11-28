#!/usr/bin/env python3
"""The fighter themes (original; PolyForm Noncommercial licensed): assets/music/theme_<fighter>.ogg, seamless loops.

Played while you fight that fighter in the TOURNAMENT. Built from the voices and helpers of gen_music.py.
Usage:  python3 tools/gen_themes.py [fighter ...]
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_music as gm  # noqa: E402
from gen_music import (Song, bass_note, bell, brass, chord, crash, epiano, flute, guitar, hat, hz, kick,  # noqa: E402
                       melody_voice, nylon, orch_hit, pad_chord, parse, rim, root_midi, saw_pluck, snare,
                       soft_pad, square_note, synth_lead, tom, tri_note, upright)

gm.CHORDS.update({
    "Bb": (10, [0, 4, 7]), "Gm": (7, [0, 3, 7]), "A": (9, [0, 4, 7]), "D": (2, [0, 4, 7]), "B": (11, [0, 4, 7]),
    "Cm": (0, [0, 3, 7]), "Ab": (8, [0, 4, 7]), "Eb": (3, [0, 4, 7]), "Fm": (5, [0, 3, 7]),
})


def bar_loop(song, chords, fn):
    for bar, name in enumerate(chords):
        fn(bar, name, bar * 16)


# ------------------------------------------------------------------ BASTION: a steady fortress march (D minor, 112)
BASTION_CHORDS = ["Dm", "Dm", "Bb", "C", "Dm", "Dm", "Bb", "A", "Gm", "Dm", "Bb", "C", "Gm", "Dm", "A", "A"]
BASTION_LEAD = [
    "D4:4 r:2 D4:2 F4:4 A4:4", "D5:6 C5:2 A4:4 F4:4", "Bb4:4 r:2 Bb4:2 D5:4 F5:4", "E5:6 D5:2 C5:4 G4:4",
    "D4:4 r:2 D4:2 F4:4 A4:4", "D5:4 E5:4 F5:4 A5:4", "G5:6 F5:2 D5:4 Bb4:4", "A4:8 C#5:4 E5:4",
    "G5:4 G5:2 F5:2 D5:4 Bb4:4", "A5:4 A5:2 G5:2 F5:4 D5:4", "D6:4 C6:2 Bb5:2 A5:4 F5:4", "G5:4 E5:4 C5:4 E5:4",
    "G5:4 G5:2 F5:2 D5:4 Bb4:4", "A5:4 A5:2 G5:2 F5:4 A5:4", "C#6:4 E6:4 A5:4 E5:4", "A5:12 r:4",
]


def make_bastion():
    song = Song(112, 16)
    lead = parse(BASTION_LEAD)
    melody_voice(song, lead, lambda f, d: brass(f, d), 1.0, 0.0)
    melody_voice(song, lead, lambda f, d: brass(f, d), 0.5, -0.4, shift=-12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        for s in (0, 4, 8, 12):
            song.add(b + s, bass_note(hz(root + (7 if s == 8 else 0)), song.dur(3.5)), 1.0)
        song.add(b, pad_chord([hz(m) for m in chord(name, 3)], song.dur(16), 1.0, 7), 0.9)
        for s in (0, 8):
            song.add(b + s, kick(1.0, 45, 0.3))
        for s in (4, 12):
            song.add(b + s, snare(0.85, 180, 0.25, 0.8))
        for s in (6, 14):
            song.add(b + s, tom(85, 0.8))
        if i in (0, 8):
            song.add(b, crash(0.8))
            song.add(b, orch_hit(root + 12, 0.9))
    bar_loop(song, BASTION_CHORDS, bar)
    return song.render(reverb=0.2, rv_time=0.55)


# ------------------------------------------------------------------ BLAZE: a fast ninja dash (E minor, 168)
BLAZE_CHORDS = ["Em", "Em", "C", "D", "Em", "Em", "C", "B", "C", "D", "Em", "Em", "C", "D", "B", "B"]
BLAZE_LEAD = [
    "E5:2 G5:2 B5:2 E6:2 D6:2 B5:2 G5:2 B5:2", "A5:2 B5:2 G5:4 E5:2 G5:2 B5:4",
    "G5:2 C6:2 E6:2 C6:2 G5:2 E5:2 C5:4", "F#5:2 A5:2 D6:2 A5:2 F#5:2 A5:2 D6:4",
    "E5:2 G5:2 B5:2 E6:2 D6:2 B5:2 G5:2 B5:2", "G5:2 B5:2 E6:2 G6:2 F#6:4 E6:4",
    "E6:2 D6:2 C6:2 B5:2 C6:4 G5:4", "D#6:2 F#6:2 B6:4 F#6:2 D#6:2 B5:4",
    "E6:4 E6:2 D6:2 C6:4 G5:4", "F#6:4 F#6:2 E6:2 D6:4 A5:4", "G6:4 G6:2 F#6:2 E6:4 B5:4", "E6:8 B5:4 G5:4",
    "E6:4 E6:2 D6:2 C6:4 G5:4", "F#6:4 F#6:2 E6:2 D6:4 F#6:4", "G#6:4 F#6:4 D#6:4 B5:4", "B5:4 D#6:4 F#6:4 B6:4",
]


def make_blaze():
    song = Song(168, 16)
    lead = parse(BLAZE_LEAD)
    melody_voice(song, lead, synth_lead, 1.0, 0.0)
    melody_voice(song, [(s + 2, m, ln) for s, m, ln in lead], synth_lead, 0.25, 0.4)

    def bar(i, name, b):
        root = root_midi(name, 2)
        for s in range(0, 16, 2):  # driving eighths
            song.add(b + s, bass_note(hz(root + (12 if s % 8 == 6 else 0)), song.dur(1.7)), 1.05)
            song.add(b + s, guitar(root + 12, song.dur(1.5), mute=True, level=0.9 if s % 4 == 0 else 0.55), 1.0, -0.35)
        if i >= 8:
            song.add(b, guitar(root + 12, song.dur(7.5), level=0.9), 1.0, 0.4)
            song.add(b + 8, guitar(root + 12, song.dur(7.5), level=0.9), 1.0, 0.4)
        for s in (0, 6, 8, 10):
            song.add(b + s, kick(1.0, 50, 0.22))
        for s in (4, 12):
            song.add(b + s, snare(0.9, 200, 0.2, 0.9))
        for s in range(16):
            song.add(b + s, hat(0.45, 0.03, 100), 0.7)
        song.add(b, tom(70, 0.9))  # taiko on the downbeat
        if i in (7, 15):
            for s in range(12, 16):
                song.add(b + s, tom(240 - (s - 12) * 40, 0.85))
    bar_loop(song, BLAZE_CHORDS, bar)
    return song.render(reverb=0.14, rv_time=0.4)


# ------------------------------------------------------------------ FROST: cold bells and air (A minor, 96)
FROST_CHORDS = ["Am", "F", "C", "G", "Am", "F", "Dm", "E", "F", "G", "Am", "Am", "F", "G", "E", "E"]
FROST_LEAD = [
    "E5:4 A5:4 C6:4 B5:4", "A5:4 C6:4 F6:4 E6:4", "G5:4 C6:4 E6:4 D6:4", "B5:4 D6:4 G6:4 D6:4",
    "C6:4 E6:4 A6:4 G6:4", "F6:4 E6:4 C6:4 A5:4", "D6:4 F6:4 A6:4 F6:4", "G#5:4 B5:4 E6:4 B5:4",
    "A5:6 C6:2 F6:8", "G6:4 F6:4 D6:4 B5:4", "C6:4 E6:8 A5:4", "A5:4 B5:4 C6:4 E6:4",
    "F6:6 E6:2 C6:4 A5:4", "D6:4 G6:4 B5:4 D6:4", "E6:4 G#5:4 B5:4 E6:4", "E6:12 r:4",
]


def make_frost():
    song = Song(96, 16, tail=3.5)
    lead = parse(FROST_LEAD)
    melody_voice(song, lead, bell, 1.0, 0.1, legato=1.0)
    melody_voice(song, [(s, m, ln) for s, m, ln in lead if (s // 16) % 2 == 1], flute, 0.35, -0.3, shift=-12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        notes = chord(name, 4)
        song.add(b, soft_pad([hz(m) for m in chord(name, 3)], song.dur(16), 1.3), 1.0, 0.0)
        song.add(b, tri_note(hz(root), song.dur(15.5), 1.0), 1.0)
        for k, s in enumerate(range(0, 16, 2)):  # icy eighth-note shimmer
            song.add(b + s, bell(hz(notes[k % 3] + 12), song.dur(2), 0.22), 1.0, 0.5 if k % 2 else -0.5)
        song.add(b, kick(0.55, 48, 0.3))
        song.add(b + 8, kick(0.4, 48, 0.3))
        for s in (4, 12):
            song.add(b + s, rim(0.5))
        for s in range(0, 16, 4):
            song.add(b + s + 2, hat(0.4, 0.06, 55), 0.7)
    bar_loop(song, FROST_CHORDS, bar)
    return song.render(reverb=0.38, rv_time=0.9)


# ------------------------------------------------------------------ VOLT: overcharged electro (C minor, 150)
VOLT_CHORDS = ["Cm", "Ab", "Eb", "Bb", "Cm", "Ab", "Fm", "G", "Ab", "Eb", "Bb", "Cm", "Ab", "Eb", "Fm", "G"]
VOLT_LEAD = [
    "C5:2 Eb5:2 G5:2 C6:2 G5:2 Eb5:2 G5:4", "Ab4:2 C5:2 Eb5:2 Ab5:2 Eb5:2 C5:2 Eb5:4",
    "Eb5:2 G5:2 Bb5:2 Eb6:2 Bb5:2 G5:2 Bb5:4", "Bb4:2 D5:2 F5:2 Bb5:2 F5:2 D5:2 F5:4",
    "C5:2 Eb5:2 G5:2 C6:2 G5:2 Eb5:2 G5:4", "Ab5:2 G5:2 Eb5:2 C5:2 Ab4:4 C5:4",
    "F5:2 Ab5:2 C6:2 F6:2 C6:2 Ab5:2 F5:4", "G5:2 B5:2 D6:2 G6:6 F6:2 D6:2",
    "C6:4 C6:2 Bb5:2 Ab5:4 Eb5:4", "G5:4 G5:2 Ab5:2 Bb5:4 G5:4", "D6:4 D6:2 C6:2 Bb5:4 F5:4", "C6:8 G5:4 Eb5:4",
    "C6:4 C6:2 Bb5:2 Ab5:4 Eb5:4", "G5:4 Bb5:4 Eb6:8", "F6:4 Eb6:4 C6:4 Ab5:4", "G5:4 B5:4 D6:4 G6:4",
]


def make_volt():
    song = Song(150, 16)
    lead = parse(VOLT_LEAD)
    melody_voice(song, lead, lambda f, d: square_note(f, d, 0.25), 1.0, 0.0)
    melody_voice(song, [(s + 3, m, ln) for s, m, ln in lead], lambda f, d: square_note(f, d, 0.125), 0.3, 0.35)

    def bar(i, name, b):
        root = root_midi(name, 2)
        notes = chord(name, 4)
        seq = [notes[0], notes[1], notes[2], notes[1]]
        for s in range(16):  # 16th arpeggio, ping-ponging left and right
            song.add(b + s, saw_pluck(hz(seq[s % 4]), song.dur(0.9)), 0.7 if i < 8 else 0.9, -0.45 if s % 2 else 0.45)
        for s in range(0, 16, 2):
            song.add(b + s, bass_note(hz(root + (12 if s % 4 == 2 else 0)), song.dur(1.7)), 1.0)
        for s in (0, 4, 8, 12):
            song.add(b + s, kick(1.0, 45, 0.2))
        for s in (4, 12):
            song.add(b + s, snare(0.8, 220, 0.2, 1.1))
        for s in (2, 6, 10, 14):
            song.add(b + s, hat(0.7, 0.12, 30), 0.8)
        if i in (7, 15):
            for s in range(12, 16):
                song.add(b + s, snare(0.4 + 0.15 * (s - 12), 220, 0.12, 1.1))
    bar_loop(song, VOLT_CHORDS, bar)
    return song.render(reverb=0.2, rv_time=0.45)


# ------------------------------------------------------------------ SHADE: creeping stealth (E phrygian, 108)
SHADE_CHORDS = ["Em", "F", "Em", "F", "Am", "Em", "F", "B", "Em", "F", "G", "F", "Am", "F", "B", "B"]
SHADE_LEAD = [
    "E4:2 r:2 G4:2 r:2 B4:4 A4:2 G4:2", "F4:2 r:2 A4:2 r:2 C5:4 B4:2 A4:2",
    "E4:2 G4:2 B4:2 E5:4 D5:2 B4:2 r:2", "C5:4 A4:2 F4:2 E4:8",
    "A4:2 C5:2 E5:4 D5:2 C5:2 B4:4", "G4:4 B4:4 E5:8", "F5:4 E5:4 C5:4 A4:4", "D#5:4 F#5:4 B5:8",
    "E5:4 B4:2 G4:2 E5:4 G5:4", "A5:4 F5:4 C6:4 A5:4", "G5:4 D5:4 B4:4 D5:4", "F5:4 A5:4 C6:4 A5:4",
    "C6:4 B5:2 A5:2 E5:8", "A5:4 F5:4 C5:4 F5:4", "F#5:4 D#5:4 B4:4 D#5:4", "B4:8 r:8",
]


def make_shade():
    song = Song(108, 16, tail=3.5)
    lead = parse(SHADE_LEAD)
    melody_voice(song, lead, nylon, 1.0, -0.1, legato=0.9)
    melody_voice(song, [(s, m, ln) for s, m, ln in lead if s // 16 >= 8], flute, 0.3, 0.3, shift=12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        song.add(b, soft_pad([hz(m) for m in chord(name, 3)[:2]] + [hz(root + 24)], song.dur(16), 1.0), 0.9)
        for s, m in ((0, 0), (6, 7), (8, 0), (14, 5)):  # a stalking bass line
            song.add(b + s, upright(hz(root + m), song.dur(4)), 1.0)
        for s in (4, 12):
            song.add(b + s, rim(0.6))
        for s in (2, 6, 10, 14):
            song.add(b + s, hat(0.35, 0.05, 80), 0.6)
        song.add(b, kick(0.6, 42, 0.3))
        song.add(b + 10, kick(0.45, 42, 0.3))
    bar_loop(song, SHADE_CHORDS, bar)
    return song.render(reverb=0.36, rv_time=0.8)


# ------------------------------------------------------------------ TITAN: a heavy stone stomp (G minor, 84)
TITAN_CHORDS = ["Gm", "Gm", "Eb", "F", "Gm", "Gm", "Eb", "D", "Cm", "Gm", "Eb", "F", "Cm", "Gm", "D", "D"]
TITAN_LEAD = [
    "G3:4 r:2 G3:2 Bb3:4 D4:4", "G4:6 F4:2 D4:4 Bb3:4", "Eb4:4 r:2 Eb4:2 G4:4 Bb4:4", "A4:6 G4:2 F4:4 C4:4",
    "G3:4 r:2 G3:2 Bb3:4 D4:4", "G4:4 A4:4 Bb4:4 D5:4", "C5:6 Bb4:2 G4:4 Eb4:4", "D4:8 F#4:4 A4:4",
    "C5:4 C5:2 Bb4:2 G4:4 Eb4:4", "D5:4 D5:2 C5:2 Bb4:4 G4:4", "G5:4 F5:2 Eb5:2 D5:4 Bb4:4", "A4:4 C5:4 F5:8",
    "C5:4 C5:2 Bb4:2 G4:4 Eb4:4", "D5:4 D5:2 C5:2 Bb4:4 D5:4", "F#5:4 A5:4 D6:4 A5:4", "D5:12 r:4",
]


def make_titan():
    song = Song(84, 16)
    lead = parse(TITAN_LEAD)
    melody_voice(song, lead, lambda f, d: brass(f, d), 1.0, 0.0)
    melody_voice(song, lead, lambda f, d: brass(f, d), 0.6, -0.3, shift=-12)

    def bar(i, name, b):
        root = root_midi(name, 1)
        song.add(b, bass_note(hz(root), song.dur(7.5)), 1.1)
        song.add(b + 8, bass_note(hz(root + (7 if i % 2 else 0)), song.dur(7.5)), 1.1)
        song.add(b, guitar(root + 24, song.dur(7.5), level=1.0), 1.0, -0.4)
        song.add(b + 8, guitar(root + 24, song.dur(7.5), level=0.9), 1.0, 0.4)
        for s in (0, 10):
            song.add(b + s, kick(1.1, 38, 0.4))
        song.add(b + 8, snare(1.0, 150, 0.35, 0.7))
        song.add(b + 4, tom(60, 0.9))
        song.add(b + 12, tom(78, 0.9))
        song.add(b + 14, tom(95, 0.7))
        if i in (0, 8):
            song.add(b, crash(0.9))
            song.add(b, orch_hit(root + 24, 1.0))
        song.add(b, pad_chord([hz(m) for m in chord(name, 2)], song.dur(16), 0.8, 5), 0.8)
    bar_loop(song, TITAN_CHORDS, bar)
    return song.render(reverb=0.24, rv_time=0.7)


# ------------------------------------------------------------------ IRONPAW: a heavy brawler groove (D minor, 100)
IRONPAW_CHORDS = ["Dm", "Dm", "Gm", "A", "Dm", "Dm", "Bb", "A", "Gm", "Gm", "Dm", "Dm", "Bb", "C", "A", "A"]
IRONPAW_LEAD = [
    "D4:3 D4:1 F4:4 E4:2 D4:2 A3:4", "D4:2 F4:2 A4:4 G4:4 F4:4", "G4:3 G4:1 Bb4:4 A4:2 G4:2 D4:4", "E4:4 C#4:4 A3:4 E4:4",
    "D4:3 D4:1 F4:4 E4:2 D4:2 A3:4", "D4:2 F4:2 A4:4 D5:4 C5:4", "Bb4:4 A4:2 G4:2 F4:4 D4:4", "E4:6 F4:2 E4:4 C#4:4",
    "G4:4 Bb4:4 D5:4 C5:2 Bb4:2", "A4:4 G4:4 F4:4 G4:4", "A4:4 F4:4 D4:4 F4:4", "A4:6 G4:2 F4:4 E4:4",
    "F4:4 Bb4:4 D5:4 Bb4:4", "C5:4 G4:4 E4:4 G4:4", "A4:4 C#5:4 E5:4 C#5:4", "A4:12 r:4",
]


def make_ironpaw():
    song = Song(100, 16)
    lead = parse(IRONPAW_LEAD)
    melody_voice(song, lead, lambda f, d: brass(f, d), 1.0, 0.0)
    melody_voice(song, lead, lambda f, d: brass(f, d), 0.5, 0.3, shift=12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        for s in range(0, 16, 2):
            song.add(b + s, bass_note(hz(root + (7 if s == 10 else 0)), song.dur(1.8)), 1.0)
        song.add(b, guitar(root + 12, song.dur(5.5), level=0.9), 1.0, -0.4)
        song.add(b + 6, guitar(root + 12, song.dur(9.5), level=0.8), 1.0, 0.4)
        for s in (0, 6, 8):
            song.add(b + s, kick(1.1, 42, 0.3))
        for s in (4, 12):
            song.add(b + s, snare(0.95, 170, 0.25, 0.8))
        song.add(b + 14, tom(90, 0.8))
        if i in (0, 8):
            song.add(b, crash(0.8))
    bar_loop(song, IRONPAW_CHORDS, bar)
    return song.render(reverb=0.18, rv_time=0.5)


# ------------------------------------------------------------------ MOONFANG: a lone run under the moon (E minor, 132)
MOONFANG_CHORDS = ["Em", "Em", "C", "D", "Em", "Em", "C", "B", "Am", "C", "Em", "Em", "Am", "D", "B", "B"]
MOONFANG_LEAD = [
    "B4:6 E5:2 G5:4 F#5:4", "E5:8 B4:4 r:4", "C5:4 E5:4 G5:4 E5:4", "F#5:6 E5:2 D5:4 A4:4",
    "B4:6 E5:2 G5:4 B5:4", "A5:4 G5:4 F#5:4 E5:4", "G5:4 E5:4 C5:4 E5:4", "D#5:8 F#5:4 B4:4",
    "A5:6 G5:2 E5:4 C5:4", "G5:6 E5:2 C5:4 G4:4", "B4:4 E5:4 G5:4 B5:4", "E6:12 r:4",
    "C6:6 B5:2 A5:4 E5:4", "F#5:6 A5:2 D6:4 A5:4", "B5:4 F#5:4 D#5:4 F#5:4", "B5:12 r:4",
]


def make_moonfang():
    song = Song(132, 16)
    lead = parse(MOONFANG_LEAD)
    melody_voice(song, lead, synth_lead, 1.0, 0.0)
    melody_voice(song, lead, flute, 0.35, -0.3, shift=-12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        song.add(b, soft_pad([hz(m) for m in chord(name, 3)], song.dur(16), 0.9), 0.8)
        for s in range(0, 16, 2):
            song.add(b + s, bass_note(hz(root + (12 if s % 8 == 4 else 0)), song.dur(1.7)), 1.0)
        for s in (0, 8, 10):
            song.add(b + s, kick(1.0, 46, 0.24))
        for s in (4, 12):
            song.add(b + s, snare(0.85, 200, 0.22, 0.9))
        for s in range(16):
            song.add(b + s, hat(0.4 if s % 2 else 0.6, 0.04, 90), 0.7, 0.3)
    bar_loop(song, MOONFANG_CHORDS, bar)
    return song.render(reverb=0.3, rv_time=0.7)


# ------------------------------------------------------------------ NIGHTOWL: a clockwork library at night (A minor, 92)
NIGHTOWL_CHORDS = ["Am", "F", "Dm", "E", "Am", "F", "G", "C", "F", "G", "Am", "Em", "F", "Dm", "E", "E"]
NIGHTOWL_LEAD = [
    "A4:4 C5:4 E5:4 A5:4", "A5:6 G5:2 F5:4 C5:4", "D5:4 F5:4 A5:4 F5:4", "E5:6 D5:2 B4:4 G#4:4",
    "A4:4 C5:4 E5:4 A5:4", "C6:6 B5:2 A5:4 F5:4", "G5:4 B5:4 D6:4 B5:4", "C6:8 G5:4 E5:4",
    "F5:4 A5:4 C6:4 A5:4", "G5:4 B5:4 D6:4 G5:4", "A5:6 B5:2 C6:4 E6:4", "B5:6 G5:2 E5:4 B4:4",
    "A5:4 C6:4 F6:4 C6:4", "F5:4 A5:4 D6:4 A5:4", "E5:4 G#5:4 B5:4 E6:4", "E6:12 r:4",
]


def make_nightowl():
    song = Song(92, 16, tail=3.0)
    lead = parse(NIGHTOWL_LEAD)
    melody_voice(song, lead, bell, 0.9, 0.2)
    melody_voice(song, lead, epiano, 0.5, -0.2, shift=-12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        for s in (0, 8):
            for m in chord(name, 4):
                song.add(b + s, epiano(hz(m), song.dur(7)), 0.35, -0.3)
            song.add(b + s, upright(hz(root + (7 if s == 8 else 0)), song.dur(7)), 1.0)
        for s in range(0, 16, 4):                      # a ticking clock
            song.add(b + s, rim(0.5 if s % 8 else 0.7), 0.8, 0.4)
        song.add(b, kick(0.6, 42, 0.3))
        song.add(b + 12, hat(0.4, 0.08, 40), 0.7)
    bar_loop(song, NIGHTOWL_CHORDS, bar)
    return song.render(reverb=0.4, rv_time=0.9)


# ------------------------------------------------------------------ OLDSHELL: a calm mountain temple (F major, 80)
OLDSHELL_CHORDS = ["F", "C", "Dm", "Bb", "F", "C", "Bb", "C", "Dm", "Bb", "F", "C", "Dm", "Bb", "C", "C"]
OLDSHELL_LEAD = [
    "A4:6 C5:2 F5:8", "E5:4 D5:4 C5:8", "D5:4 F5:4 A5:4 F5:4", "D5:8 Bb4:8",
    "A4:6 C5:2 F5:4 G5:4", "E5:8 G5:4 C6:4", "D6:4 C6:4 Bb5:4 F5:4", "G5:12 r:4",
    "A5:6 F5:2 D5:8", "Bb5:4 A5:4 F5:8", "C6:6 A5:2 F5:4 A5:4", "G5:4 E5:4 C5:8",
    "D5:4 F5:4 A5:4 D6:4", "C6:4 Bb5:4 F5:8", "G5:4 C6:4 E6:4 G5:4", "F5:12 r:4",
]


def make_oldshell():
    song = Song(80, 16, tail=3.5)
    lead = parse(OLDSHELL_LEAD)
    melody_voice(song, lead, flute, 1.0, 0.1, legato=0.95)

    def bar(i, name, b):
        root = root_midi(name, 2)
        song.add(b, soft_pad([hz(m) for m in chord(name, 3)], song.dur(16), 0.9), 0.9)
        notes = chord(name, 3)
        for k, s in enumerate((0, 4, 8, 12)):
            song.add(b + s, nylon(hz(notes[k % 3] + 12), song.dur(4)), 0.55, -0.3)
        song.add(b, upright(hz(root), song.dur(8)), 0.9)
        if i % 4 == 0:
            song.add(b, bell(hz(root + 36), song.dur(12)), 0.4, 0.4)  # temple bell
        song.add(b + 8, tom(110, 0.35))
    bar_loop(song, OLDSHELL_CHORDS, bar)
    return song.render(reverb=0.42, rv_time=1.0)


# ------------------------------------------------------------------ LILYHOP: a bouncy pond hop (C major, 140)
LILYHOP_CHORDS = ["C", "C", "F", "G", "C", "Am", "F", "G", "F", "G", "Em", "Am", "F", "G", "C", "C"]
LILYHOP_LEAD = [
    "C5:2 E5:2 G5:2 r:2 E5:2 G5:2 C6:4", "B5:2 G5:2 E5:2 G5:2 D5:4 r:4", "F5:2 A5:2 C6:2 r:2 A5:2 F5:2 A5:4",
    "G5:2 B5:2 D6:2 B5:2 G5:4 r:4", "C5:2 E5:2 G5:2 r:2 E5:2 G5:2 C6:4", "A5:2 C6:2 E6:2 C6:2 A5:4 r:4",
    "F5:2 G5:2 A5:2 C6:2 F6:4 E6:4", "D6:2 C6:2 B5:2 G5:2 D5:4 r:4",
    "A5:4 F5:2 A5:2 C6:4 A5:4", "B5:4 G5:2 B5:2 D6:4 B5:4", "G5:2 B5:2 E6:2 B5:2 G5:4 E5:4", "A5:2 C6:2 E6:2 C6:2 A5:8",
    "F5:2 A5:2 C6:2 F6:2 E6:2 C6:2 A5:4", "G5:2 B5:2 D6:2 G6:2 F6:2 D6:2 B5:4", "C6:4 G5:4 E5:4 G5:4", "C6:8 r:8",
]


def make_lilyhop():
    song = Song(140, 16)
    lead = parse(LILYHOP_LEAD)
    melody_voice(song, lead, lambda f, d: square_note(f, d, 0.5), 0.9, 0.0)
    melody_voice(song, lead, tri_note, 0.4, -0.3, shift=-12)

    def bar(i, name, b):
        root = root_midi(name, 2)
        for s, m in ((0, 0), (4, 7), (8, 12), (12, 7)):  # hopping bass
            song.add(b + s, tri_note(hz(root + m), song.dur(2)), 1.0)
        notes = chord(name, 4)
        for s in (2, 6, 10, 14):
            for m in notes:
                song.add(b + s, saw_pluck(hz(m), song.dur(1)), 0.25, 0.3)
        for s in (0, 8):
            song.add(b + s, kick(0.9, 50, 0.2))
        for s in (4, 12):
            song.add(b + s, rim(0.8))
        if i in (7, 15):
            song.add(b + 14, tom(180, 0.6))
    bar_loop(song, LILYHOP_CHORDS, bar)
    return song.render(reverb=0.16, rv_time=0.4)


# ------------------------------------------------------------------ MASKCAT: a sneaky rooftop heist (D minor, 116)
MASKCAT_CHORDS = ["Dm", "Dm", "Gm", "A", "Dm", "Dm", "Bb", "A", "Gm", "C", "F", "Dm", "Gm", "A", "Dm", "A"]
MASKCAT_LEAD = [
    "D5:2 r:2 F5:2 r:2 A5:2 G#5:2 A5:4", "r:4 D5:2 E5:2 F5:2 A5:2 D6:4", "Bb5:2 r:2 G5:2 r:2 D5:2 C#5:2 D5:4",
    "E5:2 G5:2 C#6:4 A5:4 r:4", "D5:2 r:2 F5:2 r:2 A5:2 G#5:2 A5:4", "r:4 F5:2 A5:2 D6:2 C6:2 A5:4",
    "Bb5:4 A5:2 G5:2 F5:4 D5:4", "C#5:4 E5:4 A5:4 r:4",
    "G5:2 Bb5:2 D6:4 C6:2 Bb5:2 G5:4", "E5:2 G5:2 C6:4 Bb5:2 G5:2 E5:4", "F5:2 A5:2 C6:4 A5:2 F5:2 C5:4",
    "D5:4 F5:4 A5:4 r:4", "G5:2 r:2 Bb5:2 r:2 D6:4 C6:4", "C#6:2 r:2 E6:2 r:2 A5:8", "D6:4 A5:4 F5:4 D5:4",
    "C#5:4 E5:4 A5:4 r:4",
]


def make_maskcat():
    song = Song(116, 16, tail=2.5)
    lead = parse(MASKCAT_LEAD)
    melody_voice(song, lead, epiano, 1.0, 0.15, legato=0.6)
    melody_voice(song, lead, flute, 0.3, -0.3, shift=12, legato=0.6)

    def bar(i, name, b):
        root = root_midi(name, 2)
        walk = [0, 3, 7, 10] if name.endswith("m") else [0, 4, 7, 10]
        for k, s in enumerate((0, 4, 8, 12)):         # tiptoeing walking bass
            song.add(b + s, upright(hz(root + walk[k]), song.dur(3)), 1.0)
        for s in (2, 10):
            song.add(b + s, rim(0.55), 0.8, 0.3)
        for s in (0, 4, 8, 12):
            song.add(b + s, hat(0.5, 0.06, 70), 0.7, -0.3)
            song.add(b + s + 3, hat(0.3, 0.04, 90), 0.6, -0.3)
        song.add(b, kick(0.6, 44, 0.25))
    bar_loop(song, MASKCAT_CHORDS, bar)
    return song.render(reverb=0.28, rv_time=0.6)


THEMES = {"bastion": make_bastion, "blaze": make_blaze, "frost": make_frost, "volt": make_volt, "shade": make_shade,
          "titan": make_titan, "ironpaw": make_ironpaw, "moonfang": make_moonfang, "nightowl": make_nightowl,
          "oldshell": make_oldshell, "lilyhop": make_lilyhop, "maskcat": make_maskcat}


def main(only=None):
    os.makedirs(gm.OUT, exist_ok=True)
    np.random.seed(7)
    for fid, fn in THEMES.items():
        if only and fid not in only:
            continue
        audio = fn()
        path = os.path.join(gm.OUT, "theme_%s.ogg" % fid)
        gm.write_ogg(path, audio)
        print(f"{fid:8s} {len(audio) / gm.SR:5.1f}s  peak {np.max(np.abs(audio)):.2f}  {os.path.getsize(path) / 1024:6.0f} KB")


if __name__ == "__main__":
    main(sys.argv[1:] or None)
