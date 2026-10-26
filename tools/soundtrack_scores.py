"""Scene-specific 32-bar scores: introduction, theme, lift, break and return."""

from functools import partial

SECTIONS = [
    {"name": "intro", "start_bar": 0, "bars": 4},
    {"name": "theme", "start_bar": 4, "bars": 12},
    {"name": "lift", "start_bar": 16, "bars": 8},
    {"name": "break", "start_bar": 24, "bars": 4},
    {"name": "return", "start_bar": 28, "bars": 4},
]


def energy(bar):
    return .75 if bar < 4 else (1.3 if 16 <= bar < 24 or bar >= 28 else (.46 if bar >= 24 else 1))


def groove(s, beat, root, power, busy=False, style="pop"):
    """Bass and kit have room to grow; the break deliberately loses the kit."""
    for at, degree, duration in [(0, 0, .9), (2, 7, .65)]:
        s.note(root + degree, beat + at, duration, .12 * power, "bass")
    if power < .6:
        return
    if busy:
        for at, degree in [(.75, 12), (1.5, 0), (2.75, 12), (3.5, 7)]:
            s.note(root + degree, beat + at, .35, .09 * power, "bass")
    for at in ([0, 1.75, 2.5] if busy else [0, 2]):
        s.drum("kick", beat + at, .095 * power)
    for at in [1, 3]:
        s.drum("rim" if style == "wood" else ("snare" if busy else "clap"), beat + at, .06 * power, -.2)
    for i in range(8 if busy else 4):
        at = i * (.5 if busy else 1) + (.04 if i % 2 else 0)
        s.drum("hat", beat + at, (.026 if busy else .019) * power, .45)


def fill(s, bar, power):
    if bar in [3, 15, 23, 31]:
        for i, at in enumerate([2.5, 3, 3.5, 3.75]):
            s.drum("snare", bar * 4 + at, (.035 + i * .012) * power, -.2 + i * .12)
    if bar in [4, 16, 28]:
        s.drum("crash", bar * 4, .032 * power, -.45)


def neighborhood(Song, pitch):
    s = Song(112, seed=21)
    chords = ["C4 E4 G4 C5", "F3 A3 C4 F4", "C4 E4 G4 C5", "G3 B3 D4 G4",
              "F3 A3 C4 F4", "C4 E4 G4 C5", "D4 F#4 A4 D5", "G3 B3 D4 G4"]
    roots = ["C2", "F2", "C2", "G2", "F2", "C2", "D2", "G2"]
    theme = [
        [(0, "E5", .7), (1, "G5", 1.25), (2.5, "C5", .8)],
        [(.25, "A4", .65), (1.25, "C5", .65), (2.5, "F5", 1.2)],
        [(0, "E5", 1.3), (1.75, "D5", .6), (2.5, "C5", .8)],
        [(.5, "B4", .6), (1.5, "D5", 1.1), (3, "G4", .7)],
        [(0, "A4", .65), (1, "C5", .65), (2, "A5", 1.4)],
        [(.25, "G5", 1.1), (1.75, "E5", .7), (3, "C5", .7)],
        [(0, "F#5", 1.1), (1.5, "E5", .65), (2.5, "D5", 1.1)],
        [(0, "B4", .7), (1.25, "D5", .65), (2.5, "G5", 1)],
    ]
    lift = [
        [(0, "G5", .8), (1, "E5", .6), (2, "C6", 1.5)],
        [(.25, "C6", .65), (1.25, "A5", 1), (2.75, "F5", .8)],
        [(0, "G5", 1.8), (2.5, "E5", 1.1)],
        [(0, "D5", .5), (.75, "G5", .8), (2, "B5", 1.4)],
        [(0, "A5", 1), (1.5, "G5", .6), (2.5, "F5", 1.1)],
        [(.5, "E5", .7), (1.5, "G5", .8), (2.75, "C6", 1)],
        [(0, "A5", .7), (1, "F#5", .7), (2.25, "D5", 1.2)],
        [(0, "G5", 1), (1.5, "D5", .6), (2.5, "B4", 1)],
    ]
    for bar in range(32):
        b, c, power = bar * 4, bar % 8, energy(bar)
        busy = power > 1
        groove(s, b, pitch(roots[c]), power, busy)
        for at in [0, 1.5, 2.5]:
            s.chord(chords[c], b + at, .85, .038 * power, "guitar", .9)
        if busy:
            s.chord(chords[c], b, 3.6, .018, "strings", .9)
        score = lift[c] if busy else theme[c]
        for at, note, duration in score:
            s.note(note, b + at, duration, (.075 if busy else .065) * power,
                   "brass" if busy else "keys", .12, .10)
        if 24 <= bar < 28:
            s.note(chords[c].split()[0], b + 2, 1, .05, "wood", -.25)
        fill(s, bar, power)
    return s


def bedroom(Song, pitch):
    s = Song(104, seed=22)
    chords = ["F3 A3 C4 F4", "C4 E4 G4 C5", "Bb3 D4 F4 Bb4", "C4 E4 G4 C5",
              "F3 A3 C4 F4", "Bb3 D4 F4 Bb4", "G3 B3 D4 G4", "C4 E4 G4 C5"]
    roots = ["F2", "C3", "Bb2", "C3", "F2", "Bb2", "G2", "C3"]
    theme = [[(0, "A4", 1), (1.5, "C5", 1.5)], [(.5, "G4", 1), (2, "E4", 1.4)],
             [(0, "F4", .8), (1.25, "D5", .8), (2.5, "Bb4", 1)], [(0, "G4", 2.5)],
             [(0, "C5", .8), (1.5, "A4", .8), (2.5, "F4", 1)], [(.5, "F5", 1), (2, "D5", 1.4)],
             [(0, "B4", 1.2), (1.75, "D5", 1.2)], [(.5, "G4", 1), (2, "C5", 1.5)]]
    for bar in range(32):
        b, c, power = bar * 4, bar % 8, energy(bar)
        busy = power > 1
        groove(s, b, pitch(roots[c]), power * .82, busy, "wood")
        for at in [0, 1.5, 3]:
            s.chord(chords[c], b + at, 1.1, .048 * power, "guitar", .9)
        s.chord(chords[c], b + .1, 3.5, .02 * power, "keys", .5)
        for at, note, duration in theme[c]:
            s.note(pitch(note) + (12 if busy and bar % 2 else 0), b + at, duration,
                   .08 * power, "keys" if busy else "wood", .2, .15)
        if busy:
            notes = chords[c].split()
            for i in range(4):
                s.note(notes[i], b + i + .5, .55, .038, "guitar", -.4)
        fill(s, bar, power * .7)
    return s


def treehouse(Song, pitch):
    # Retain the wooden instruments, original opening pattern and 106 BPM pace.
    s = Song(106, seed=13)
    chords = ["D4 F#4 A4 B4", "G3 B3 D4 A4", "B3 D4 F#4 A4", "A3 C#4 E4 B4"]
    roots = ["D3", "G2", "B2", "A2"]
    for bar in range(32):
        b, c = bar * 4, (bar // 2) % 4
        power = 1 if bar < 16 else energy(bar)
        notes = [pitch(n) for n in chords[c].split()]
        s.chord(chords[c], b, 3.2, .028 * power, "pad")
        pattern = [0, 2, 1, 3, 2] if bar % 2 == 0 else [1, 3, 2, 0]
        times = [0, .75, 1.5, 2.5, 3.25] if bar % 2 == 0 else [.25, 1.25, 2, 3]
        for i, (degree, at) in enumerate(zip(pattern, times)):
            s.note(notes[degree], b + at, .65, (.12 if i == 0 else .075) * power,
                   "wood", -.35 if i % 2 else .35, .15)
        groove(s, b, pitch(roots[c]), power * .8, power > 1, "wood")
        if power > 1:
            # A new eight-bar chorus answers the marimba with longer guitar lines.
            answer = [notes[2], notes[3], notes[1], notes[0]]
            for i, note in enumerate(answer):
                s.note(note + 12, b + [.25, 1.25, 2, 3][i], [.7, .6, .8, .7][i],
                       .065, "guitar", .2, .12)
            s.chord(chords[c], b + .05, 3.7, .02, "strings")
        elif bar in [3, 7, 11]:
            for i, degree in enumerate([0, 1, 2]):
                s.note(notes[degree] + 12, b + 2 + i * .5, .5, .05, "pluck", .2, .18)
        fill(s, bar, power * .75)
    return s


def winter(Song, pitch):
    s = Song(112, seed=24)
    chords = ["G3 B3 D4 G4", "C4 E4 G4 C5", "D4 F#4 A4 D5", "G3 B3 D4 G4",
              "C4 E4 G4 C5", "G3 B3 D4 G4", "A3 C#4 E4 A4", "D4 F#4 A4 D5"]
    roots = ["G2", "C3", "D3", "G2", "C3", "G2", "A2", "D3"]
    phrases = [[(0, "B4", .65), (1, "D5", .65), (2.25, "G5", 1.2)],
               [(.25, "E5", .65), (1.5, "C5", 1.6)], [(0, "F#5", 1), (1.5, "E5", .6), (2.5, "D5", 1)],
               [(.5, "B4", .7), (1.75, "G4", 1.6)], [(0, "E5", 1), (1.5, "G5", 1.5)],
               [(.5, "D5", .7), (1.5, "B4", .7), (2.75, "G4", .9)],
               [(0, "C#5", .8), (1.25, "E5", .8), (2.5, "A5", 1)], [(0, "F#5", 1.4), (2, "D5", 1.5)]]
    for bar in range(32):
        b, c, power = bar * 4, bar % 8, energy(bar)
        groove(s, b, pitch(roots[c]), power, power > 1, "wood")
        for at in [0, 1.5, 2.5]:
            s.chord(chords[c], b + at, .9, .042 * power, "guitar", .8)
        for at, note, duration in phrases[c]:
            s.note(note, b + at, duration, .07 * power, "keys" if power > 1 else "wood", .15, .1)
        # Bells decorate the tune, rather than carrying a constant chime loop.
        if bar % 2 == 0:
            s.note(pitch(chords[c].split()[2]) + 12, b + 3, .6, .026, "bell", -.5, .25)
        if power > 1:
            s.chord(chords[c], b, 3.7, .025, "strings", .9)
            for i in range(4):
                s.note(chords[c].split()[i], b + i + .5, .45, .045, "wood", -.3)
        fill(s, bar, power * .8)
    return s


def phone(Song, pitch):
    s = Song(114, seed=25)
    chords = ["E3 G#3 B3 E4", "A3 C#4 E4 A4", "B3 D#4 F#4 B4", "E3 G#3 B3 E4",
              "A3 C#4 E4 A4", "E3 G#3 B3 E4", "F#3 A#3 C#4 F#4", "B3 D#4 F#4 B4"]
    roots = ["E2", "A2", "B2", "E2", "A2", "E2", "F#2", "B2"]
    contour = [[2, 1, 0], [1, 2, 3], [2, 3, 1], [0, 2, 1], [3, 2, 1], [1, 0, 2], [2, 1, 3], [1, 2, 0]]
    for bar in range(32):
        b, c, power = bar * 4, bar % 8, energy(bar)
        notes = [pitch(n) for n in chords[c].split()]
        groove(s, b, pitch(roots[c]), power * .85, power > 1, "wood")
        for at in [.5, 2.5]:
            s.chord(chords[c], b + at, 1.1, .045 * power, "guitar", .9)
        for i, degree in enumerate(contour[c]):
            s.note(notes[degree] + 12, b + [.25, 1.5, 2.75][i], [.8, .9, .8][i],
                   .07 * power, "keys" if power > 1 else "pluck", .15, .14)
        if power > 1:
            s.chord(chords[c], b, 3.5, .025, "strings")
            for i in range(4):
                s.note(notes[i], b + i * .75, .6, .045, "wood", -.4)
        fill(s, bar, power * .65)
    return s


def party(Song, pitch, snowman=False):
    s = Song(120 if snowman else 124, seed=27 if snowman else 26)
    chords = (["D4 F#4 A4 D5", "G3 B3 D4 G4", "E4 G#4 B4 E5", "A3 C#4 E4 A4"] if snowman else
              ["A3 C#4 E4 A4", "D4 F#4 A4 D5", "B3 D#4 F#4 B4", "E4 G#4 B4 E5"])
    roots = ["D2", "G2", "E2", "A2"] if snowman else ["A2", "D3", "B2", "E3"]
    for bar in range(32):
        b, c, power = bar * 4, (bar // 2) % 4, energy(bar)
        notes = [pitch(n) for n in chords[c].split()]
        groove(s, b, pitch(roots[c]), power * 1.12, power >= 1)
        for at in [.5, 1.75, 2.5, 3.5]:
            s.chord(chords[c], b + at, .4, .048 * power, "guitar", .85)
        sequence = [0, 2, 3, 1] if bar % 2 == 0 else [2, 1, 0]
        times = [.25, 1, 2.25, 3] if bar % 2 == 0 else [.5, 1.75, 2.75]
        for i, (degree, at) in enumerate(zip(sequence, times)):
            s.note(notes[degree] + (0 if snowman else 12), b + at, .65 if i < 2 else .8,
                   .08 * power, "wood" if snowman else "brass", .15, .10)
        if snowman and bar % 2 == 0:
            s.note(notes[2] + 12, b + 3.5, .55, .035, "bell", -.4)
        if power > 1:
            s.chord(chords[c], b, 3.5, .025, "strings", .9)
            for i in range(4):
                s.note(notes[(3 - i) % 4], b + i + .5, .4, .048, "wood", -.4)
        fill(s, bar, power)
    return s


def track_list(Song, pitch):
    return [
        ("neighborhood", "Hello, DigiWorld", "Sunny major-key guitar, electric keys and a full pop chorus.", partial(neighborhood, Song, pitch)),
        ("bedroom", "After School", "Cheerful guitar and wooden keys, a gentle beat and an energetic middle section.", partial(bedroom, Song, pitch)),
        ("treehouse", "Branch by Branch", "The familiar wooden theme, expanding into a guitar and percussion chorus.", partial(treehouse, Song, pitch)),
        ("winter", "Snowflakes and Secrets", "Playful major-key winter music with bell accents and a lively string-backed chorus.", partial(winter, Song, pitch)),
        ("phone", "Think Before You Tap", "Curious, upbeat plucks and keys throughout the phone investigation.", partial(phone, Song, pitch)),
        ("party", "Park Party", "Bright party groove with bass fills, synth brass, claps and a bigger chorus.", partial(party, Song, pitch)),
        ("snowman_party", "Snowman Shuffle", "A second full party arrangement with wooden melody, bells and a bouncing beat.", partial(party, Song, pitch, True)),
    ]
