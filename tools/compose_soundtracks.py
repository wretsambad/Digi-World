"""Render DigiWorld's original scene music with NumPy and FFmpeg.

Run: python tools/compose_soundtracks.py
The WAV masters and listening sampler go in ignored work/music/. Game assets
are compact stereo Vorbis loops in audio/music/. No downloaded samples.
"""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "audio" / "music"
WORK = ROOT / "work" / "music"
RATE = 44100
TAU = 2 * np.pi


def pitch(note: str) -> int:
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    accidental = (1 if "#" in note else -1 if "b" in note else 0)
    return 12 * (int(note[-1]) + 1) + names[note[0]] + accidental


class Song:
    def __init__(self, bpm: int, bars: int = 32, meter: int = 4, seed: int = 10):
        self.bpm, self.bars, self.meter = bpm, bars, meter
        self.beat = 60 / bpm
        self.samples = round(bars * meter * self.beat * RATE)
        self.mix = np.zeros((self.samples, 2), dtype=np.float64)
        self.rng = np.random.default_rng(seed)

    def add(self, signal, beat: float, gain: float, pan: float = 0):
        # Wrap note/reverb tails into the start, preserving a continuous loop.
        start = round(beat * self.beat * RATE) % self.samples
        signal = np.asarray(signal) * gain
        stereo = signal[:, None] * np.array([
            np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        ])
        for offset in range(0, len(signal), self.samples):
            part = stereo[offset:offset + self.samples]
            first = min(len(part), self.samples - start)
            self.mix[start:start + first] += part[:first]
            if first < len(part):
                self.mix[:len(part) - first] += part[first:]

    def note(self, note, beat, length=1, gain=.1, voice="keys", pan=0, echo=.0):
        midi = pitch(note) if isinstance(note, str) else note
        freq = 440 * 2 ** ((midi - 69) / 12)
        seconds = length * self.beat
        tail = .45 if voice in {"keys", "pluck", "wood"} else 1.0
        t = np.arange(round((seconds + tail) * RATE)) / RATE
        if voice == "guitar":
            signal = sum(np.sin(TAU * freq * harmonic * t) * np.exp(-t * (.8 + harmonic * .65) / max(seconds, .3)) / harmonic ** 1.35
                         for harmonic in range(1, 9))
            signal += .035 * self.rng.uniform(-1, 1, len(t)) * np.exp(-t * 220)
            envelope = np.minimum(t / .006, 1)
        elif voice == "brass":
            signal = sum(np.sin(TAU * freq * harmonic * t + .006 * np.sin(TAU * 5 * t)) * level * np.exp(-t * harmonic * .18)
                         for harmonic, level in [(1, 1), (2, .33), (3, .15), (4, .07), (5, .025)])
            envelope = np.minimum(t / .035, 1) * np.minimum(np.maximum(seconds - t, 0) / .12, 1)
        elif voice == "strings":
            signal = sum(np.sin(TAU * freq * harmonic * t) * level for harmonic, level in
                         [(1, .65), (1.003, .25), (2, .20), (2.003, .08), (3, .08), (4, .035)])
            envelope = np.minimum(t / .15, 1) * np.minimum(np.maximum(seconds + .3 - t, 0) / .4, 1)
        elif voice == "pad":
            signal = sum(np.sin(TAU * freq * ratio * t) * level for ratio, level in
                         [(1, .65), (1.002, .16), (2, .12), (3, .035)])
            envelope = np.minimum(t / .24, 1) * np.exp(-t / (seconds + .3))
        elif voice == "bell":
            signal = sum(np.sin(TAU * freq * ratio * t) * level * np.exp(-t / decay)
                         for ratio, level, decay in [(1, 1, 1.3), (2.756, .17, .3), (4.1, .045, .16)])
            envelope = np.minimum(t / .008, 1)
        elif voice == "wood":
            signal = (np.sin(TAU * freq * t) * np.exp(-t / .22)
                      + .22 * np.sin(TAU * freq * 3.99 * t) * np.exp(-t / .045))
            envelope = np.minimum(t / .004, 1)
        elif voice == "pluck":
            signal = sum(np.sin(TAU * freq * harmonic * t) * np.exp(-t * (2 + harmonic) / max(seconds, .25)) / harmonic ** 1.7
                         for harmonic in range(1, 6))
            envelope = np.minimum(t / .007, 1)
        elif voice == "bass":
            signal = np.sin(TAU * freq * t) + .17 * np.sin(TAU * freq * 2 * t)
            envelope = np.minimum(t / .012, 1) * np.exp(-t / max(seconds * .65, .15))
        elif voice == "air":
            signal = np.sin(TAU * freq * t + .016 * np.sin(TAU * 4 * t)) + .08 * np.sin(TAU * 2 * freq * t)
            envelope = np.minimum(t / .07, 1) * np.exp(-t / max(seconds, .25))
        else:  # Soft electric/felt keys, with progressively shorter upper partials.
            signal = sum(np.sin(TAU * freq * harmonic * t) * level * np.exp(-t / decay)
                         for harmonic, level, decay in [(1, 1, seconds + .35), (2, .23, .35), (3, .075, .16), (4, .022, .08)])
            envelope = np.minimum(t / .014, 1)
        release = np.minimum(np.maximum(seconds + tail - t, 0) / tail, 1) ** 2
        signal *= envelope * release
        self.add(signal, beat, gain, pan)
        if echo:
            self.add(signal, beat + .75, gain * echo, -pan * .8)
            self.add(signal, beat + 1.5, gain * echo * .3, pan * .6)

    def chord(self, notes, beat, length=2, gain=.05, voice="keys", spread=.55):
        for i, note in enumerate(notes.split()):
            self.note(note, beat + i * .018, length, gain, voice,
                      (i - 1.5) * spread / 2)

    def drum(self, kind, beat, gain=.06, pan=0):
        seconds = {"kick": .26, "rim": .085, "hat": .11, "clap": .18, "snare": .2, "crash": .65}[kind]
        t = np.arange(round(seconds * RATE)) / RATE
        noise = self.rng.uniform(-1, 1, len(t))
        high = np.concatenate(([0], np.diff(noise))) * .5
        if kind == "kick":
            phase = TAU * (48 * t + 58 * .025 * (1 - np.exp(-t / .025)))
            signal = np.sin(phase) * np.exp(-t * 19)
        elif kind == "rim":
            signal = (.7 * np.sin(TAU * 1250 * t) + .2 * high) * np.exp(-t * 90)
        elif kind == "clap":
            signal = high * np.exp(-t * 32) * (.4 + .6 * np.sin(TAU * 95 * t) ** 2)
        elif kind == "snare":
            signal = (.6 * high + .25 * np.sin(TAU * 185 * t)) * np.exp(-t * 23)
        elif kind == "crash":
            signal = high * np.exp(-t * 8)
        else:
            signal = high * np.exp(-t * 55)
        signal *= np.minimum(t / .002, 1) * np.minimum((seconds - t) / .008, 1)
        self.add(signal, beat, gain, pan)

    def finish(self):
        # Circular stereo room reflections also carry across the loop boundary.
        dry = self.mix.copy()
        for delay, level in [(.061, .075), (.113, .06), (.193, .04)]:
            self.mix += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * level
        self.mix -= self.mix.mean(axis=0)
        rms = np.sqrt(np.mean(self.mix ** 2))
        self.mix *= min(.135 / max(rms, 1e-9), .72 / max(np.max(np.abs(self.mix)), 1e-9))
        return self.mix


from soundtrack_scores import SECTIONS, track_list

TRACKS = track_list(Song, pitch)


def save_wav(path: Path, samples):
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(2)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(np.rint(np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())


def main():
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("FFmpeg is required to encode the game loops.")
    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    manifest, previews = [], []
    for name, title, description, composer in TRACKS:
        song = composer()
        samples = song.finish()
        master = WORK / f"{name}.wav"
        save_wav(master, samples)
        subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-i", str(master),
                        "-c:a", "libvorbis", "-q:a", "5", "-metadata", f"title={title}",
                        "-metadata", "artist=DigiWorld", str(OUT / f"{name}.ogg")], check=True)
        # Measure the decoded file as well as the master, including the seam.
        decoded = subprocess.run([ffmpeg, "-v", "error", "-i", str(OUT / f"{name}.ogg"),
                                  "-f", "f32le", "-acodec", "pcm_f32le", "-"], check=True, capture_output=True)
        pcm = np.frombuffer(decoded.stdout, dtype="<f4").reshape(-1, 2)
        seam = float(np.max(np.abs(pcm[-1] - pcm[0])))
        peak = float(np.max(np.abs(pcm)))
        assert np.isfinite(pcm).all() and peak < .99, f"Clipped or invalid track: {name}"
        assert abs(len(pcm) - len(samples)) < 512, f"Incorrect loop length: {name}"
        assert seam < .035, f"Discontinuous loop: {name} ({seam})"
        sections = []
        for section in SECTIONS:
            start = round(section["start_bar"] * song.meter * song.beat * RATE)
            stop = round((section["start_bar"] + section["bars"]) * song.meter * song.beat * RATE)
            rms = float(np.sqrt(np.mean(samples[start:stop] ** 2)))
            sections.append({**section, "start_seconds": round(start / RATE, 3),
                             "rms_dbfs": round(20 * np.log10(max(rms, 1e-9)), 2)})
        levels = {section["name"]: section["rms_dbfs"] for section in sections}
        assert levels["lift"] > levels["break"] + 3, f"Insufficient energy contrast: {name}"
        manifest.append({"file": f"{name}.ogg", "title": title, "scene": description,
                         "bpm": song.bpm, "meter": f"{song.meter}/4", "bars": song.bars,
                         "seconds": round(len(samples) / RATE, 3), "decoded_peak_dbfs": round(20 * np.log10(peak), 2),
                         "decoded_seam_step": round(seam, 6), "sections": sections})
        # Let the listener hear the actual contrast, not just the introduction.
        for start, length in [(0, 7), (round(16 * song.meter * song.beat * RATE), 9)]:
            excerpt = samples[start:start + RATE * length].copy()
            fade = np.linspace(0, 1, RATE // 4)
            excerpt[:len(fade)] *= fade[:, None]
            excerpt[-len(fade):] *= fade[::-1, None]
            previews.append(excerpt)
        previews.append(np.zeros((RATE // 2, 2)))
        print(f"Rendered {title}: {manifest[-1]['seconds']}s, {song.bpm} BPM, seam {seam:.5f}")
    (OUT / "tracks.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    sampler = WORK / "digiworld_sampler.wav"
    save_wav(sampler, np.concatenate(previews))
    subprocess.run([ffmpeg, "-v", "error", "-y", "-i", str(sampler), "-c:a", "libmp3lame", "-q:a", "3",
                    str(WORK / "digiworld_sampler.mp3")], check=True)


if __name__ == "__main__":
    main()
