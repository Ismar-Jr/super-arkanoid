#!/usr/bin/env python3
"""Trilhas e efeitos originais. Síntese determinística, somente Python 3."""
from array import array
from pathlib import Path
import hashlib
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "Audio"
RATE = 22050
TAU = math.tau
STATS = []


def frequency(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def buffer(seconds):
    return array("f", [0.0]) * round(seconds * RATE)


def voice(track, at, note, duration, gain=0.1, kind="pearl", circular=False):
    """Envelopes curtos e harmônicos limitados suavizam a estética de chip."""
    start = round(at * RATE)
    length = max(1, round(duration * RATE))
    attack = max(1, round(min(.006, duration / 8) * RATE))
    release = max(1, round(min(.07, duration / 3) * RATE))
    omega = TAU * frequency(note) / RATE
    for i in range(length):
        t = i / RATE
        phase = i * omega
        if kind == "pearl":
            sample = (math.sin(phase) + .24 * math.sin(phase * 2) + .13 * math.sin(phase * 3)) / 1.37
            envelope = (.22 + .78 * math.exp(-t * 7.0))
        elif kind == "pulse":
            sample = (math.sin(phase) + .27 * math.sin(phase * 2) + .20 * math.sin(phase * 3) + .08 * math.sin(phase * 5)) / 1.55
            envelope = .42 + .58 * math.exp(-t * 9.0)
        elif kind == "pad":
            sample = (math.sin(phase) + .12 * math.sin(phase * 2.003) + .05 * math.sin(phase * 3)) / 1.17
            envelope = .70 + .30 * math.sin(math.pi * i / length)
            attack = round(.045 * RATE)
            release = round(.11 * RATE)
        else:
            sample = (math.sin(phase) - math.sin(phase * 3) / 9 + math.sin(phase * 5) / 25) / 1.15
            envelope = .74 + .26 * math.exp(-t * 10)
        envelope *= min(1.0, i / attack) * min(1.0, (length - 1 - i) / release)
        dest = (start + i) % len(track) if circular else start + i
        if 0 <= dest < len(track):
            track[dest] += sample * envelope * gain


def drum(track, at, kind, gain, seed=0, circular=True):
    rng = random.Random(seed)
    duration = {"kick": .18, "snare": .12, "hat": .045, "open": .13}[kind]
    length = round(duration * RATE)
    start = round(at * RATE)
    previous = 0.0
    phase = 0.0
    for i in range(length):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        if kind == "kick":
            phase += TAU * (48 + 82 * math.exp(-t * 37)) / RATE
            sample = math.sin(phase) * math.exp(-t * 23) + noise * .12 * math.exp(-t * 180)
        elif kind == "snare":
            sample = (noise * .68 + math.sin(TAU * 188 * t) * .32) * math.exp(-t * 32)
        else:
            high = noise - previous
            sample = high * .45 * math.exp(-t * (78 if kind == "hat" else 28))
        previous = noise
        sample *= min(1.0, i / (RATE * .003)) * min(1.0, (length - i - 1) / (RATE * .006))
        dest = (start + i) % len(track) if circular else start + i
        if 0 <= dest < len(track):
            track[dest] += sample * gain


def write_audio(relative, samples, target=.76, loop=False):
    """Remove componente contínua e mantém margem para mixagem no jogo."""
    mean = sum(samples) / len(samples)
    peak = max(abs(s - mean) for s in samples) or 1.0
    # Normaliza músicas; efeitos leves de interface continuam discretos.
    factor = target / peak if loop else min(1.0, target / peak)
    values = [int(max(-.80, min(.80, (s - mean) * factor)) * 32767) for s in samples]
    # Uma rampa de 4ms faz a fronteira do loop chegar exatamente a zero.
    ramp = min(round(RATE * .004), len(values) // 3)
    for i in range(ramp):
        factor_edge = i / ramp
        values[i] = round(values[i] * factor_edge)
        values[-1 - i] = round(values[-1 - i] * factor_edge)
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = struct.pack("<" + "h" * len(values), *values)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(payload)
    if loop:
        # O bloco padrão smpl permite ao Godot detectar o loop na importação.
        metadata = struct.pack("<9I", 0, 0, round(1_000_000_000 / RATE), 60, 0, 0, 0, 1, 0)
        metadata += struct.pack("<6I", 0, 0, 0, len(values) - 1, 0, 0)
        riff = bytearray(path.read_bytes())
        riff += b"smpl" + struct.pack("<I", len(metadata)) + metadata
        struct.pack_into("<I", riff, 4, len(riff) - 8)
        path.write_bytes(riff)
    duration = len(values) / RATE
    rms = math.sqrt(sum((v / 32767) ** 2 for v in values) / len(values))
    final_peak = max(abs(v) for v in values) / 32767
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    STATS.append((relative, duration, final_peak, rms, digest))


CHORDS = [
    (38, [62, 65, 69, 76]),   # Ré menor com nona.
    (34, [62, 65, 69, 72]),   # Si bemol maior com sétima.
    (41, [60, 64, 69, 74]),   # Fá maior com sexta e nona.
    (36, [60, 64, 67, 74]),   # Dó maior com nona.
]


def make_menu():
    beat = .5
    track = buffer(16)
    melody = [
        [(0, 74, 1.2), (2, 81, .45), (3, 77, .70)],
        [(.5, 76, .5), (1.5, 74, .65), (3, 72, .65)],
        [(0, 77, 1), (1.5, 81, .5), (2.5, 79, .55), (3.5, 77, .35)],
        [(0, 76, .8), (1.25, 74, .5), (2.5, 72, 1)],
        [(0, 74, .70), (1, 77, .6), (2.5, 81, 1)],
        [(.5, 79, .5), (1.5, 77, .5), (2.5, 76, .9)],
        [(0, 77, .7), (1.5, 76, .5), (2.5, 74, .7)],
        [(0, 72, .75), (1.5, 76, .5), (2.5, 69, 1.2)],
    ]
    for bar in range(8):
        start = bar * 4 * beat
        root, chord = CHORDS[bar % 4]
        for note in chord[:3]:
            voice(track, start, note, beat * 3.8, .035, "pad", True)
        for b, note in ((0, root), (1.5, root + 12), (2.5, root + 7), (3.25, root + 12)):
            voice(track, start + b * beat, note, beat * .65, .15, "bass", True)
        for step in range(8):
            note = chord[(step + bar) % 4] + 12
            voice(track, start + step * beat / 2, note, .13, .043, "pearl", True)
        for b, note, length in melody[bar]:
            voice(track, start + b * beat, note, length * beat, .135, "pearl", True)
            voice(track, start + b * beat + .18, note, length * beat, .026, "pearl", True)
        for b in (0, 2):
            drum(track, start + b * beat, "kick", .14, bar * 100 + b)
        drum(track, start + 2 * beat, "snare", .048, bar * 127)
        for step in range(8):
            drum(track, start + step * beat / 2, "hat", .023 if step % 2 else .034, bar * 32 + step)
    write_audio("Music/menu.wav", track, .68, True)


def make_game():
    beat = 60 / 140
    track = buffer(12 * 4 * beat)
    motifs = [
        [(0, 74, .7), (.75, 77, .45), (1.5, 81, .45), (2.25, 79, .45), (3, 77, .7)],
        [(0, 74, .45), (.75, 77, .45), (1.5, 81, .7), (2.5, 84, .45), (3.25, 81, .6)],
        [(0, 81, .45), (.75, 79, .45), (1.5, 77, .7), (2.5, 76, .45), (3.25, 77, .55)],
        [(0, 79, .7), (1, 76, .45), (1.75, 74, .45), (2.5, 72, .45), (3.25, 69, .55)],
    ]
    for bar in range(12):
        start = bar * 4 * beat
        root, chord = CHORDS[bar % 4]
        for note in chord[:3]:
            voice(track, start, note, beat * 3.75, .026, "pad", True)
        for step in range(8):
            note = root + (12 if step in (3, 6) else 7 if step == 7 else 0)
            voice(track, start + step * beat / 2, note, beat * .37, .18, "bass", True)
        for step in range(16):
            note = chord[(step + (bar // 4)) % 4] + (12 if step % 8 < 4 else 0)
            voice(track, start + step * beat / 4, note, beat * .19, .050 if step % 4 else .070, "pearl", True)
        for b, note, length in motifs[bar % 4]:
            if bar >= 8 and bar % 4 == 0:
                note += 12
            voice(track, start + b * beat, note, length * beat, .12, "pulse", True)
            voice(track, start + b * beat + beat * .5, note, length * beat, .020, "pearl", True)
        for b in (0, 1.75, 2, 3.5):
            drum(track, start + b * beat, "kick", .19 if b in (0, 2) else .105, bar * 211 + int(b * 10))
        for b in (1, 3):
            drum(track, start + b * beat, "snare", .105, bar * 71 + b)
        for step in range(8):
            drum(track, start + step * beat / 2, "hat", .04 if step % 2 else .027, bar * 83 + step)
        if bar % 4 == 3:
            for step in (13, 14, 15):
                drum(track, start + step * beat / 4, "snare", .055, bar * 99 + step)
    write_audio("Music/partida.wav", track, .74, True)


def sweep(track, start, duration, first, last, gain=.2, shape="pearl", noise=.0, seed=1):
    rng = random.Random(seed)
    length = round(duration * RATE)
    offset = round(start * RATE)
    phase = 0.0
    for i in range(length):
        f = i / max(1, length - 1)
        hz = first * (last / first) ** f
        phase += TAU * hz / RATE
        sample = math.sin(phase)
        if shape == "pulse":
            sample = (sample + .26 * math.sin(phase * 3) + .10 * math.sin(phase * 5)) / 1.36
        sample = sample * (1 - noise) + rng.uniform(-1, 1) * noise
        envelope = min(1, i / (RATE * .004)) * math.sin(math.pi * f) ** .45 * (1 - .55 * f)
        dest = offset + i
        if dest < len(track):
            track[dest] += sample * envelope * gain


def notes_sound(name, notes, seconds, gain=.22, kind="pearl"):
    track = buffer(seconds)
    for at, note, duration in notes:
        voice(track, at, note, duration, gain, kind)
    write_audio("SFX/" + name + ".wav", track)


def make_sfx():
    track = buffer(.095)
    sweep(track, 0, .085, 610, 920, .17)
    write_audio("SFX/rebote.wav", track)
    track = buffer(.19)
    sweep(track, 0, .15, 620, 150, .24, "pulse", .14, 15)
    sweep(track, .015, .09, 1450, 850, .09)
    write_audio("SFX/bloco.wav", track)
    track = buffer(.17)
    sweep(track, 0, .145, 1750, 310, .13, "pulse", .015, 31)
    write_audio("SFX/laser.wav", track)
    notes_sound("coleta", [(0, 74, .13), (.09, 77, .13), (.18, 81, .15), (.27, 86, .28)], .60, .21)
    track = buffer(.78)
    sweep(track, 0, .36, 330, 83, .26, "pulse", .10, 51)
    voice(track, .19, 50, .30, .16, "bass")
    voice(track, .40, 38, .34, .17, "bass")
    write_audio("SFX/vida.wav", track)
    track = buffer(1.65)
    for at, note, duration in [(0, 74, .24), (.22, 72, .24), (.44, 69, .28), (.71, 65, .28), (1.0, 62, .58)]:
        voice(track, at, note, duration, .21, "pulse")
        voice(track, at, note - 12, duration, .10, "bass")
    write_audio("SFX/game_over.wav", track)
    notes_sound("iniciar", [(0, 62, .18), (.10, 69, .18), (.20, 74, .20), (.34, 77, .25), (.48, 81, .40)], .95, .22)
    track = buffer(1.12)
    for at, note, duration in [(0, 74, .16), (.14, 77, .16), (.28, 81, .16), (.42, 86, .26), (.68, 81, .34)]:
        voice(track, at, note, duration, .20, "pearl")
    for note in (62, 65, 69):
        voice(track, .67, note, .4, .09, "pad")
    write_audio("SFX/setor.wav", track)
    notes_sound("ui_move", [(0, 81, .060)], .09, .070)
    notes_sound("ui_confirm", [(0, 77, .095), (.07, 84, .12)], .24, .095)


def write_report():
    header = "file\tduration_s\tpeak\trms\tsha256\n"
    rows = [f"{name}\t{duration:.6f}\t{peak:.6f}\t{rms:.6f}\t{digest}\n" for name, duration, peak, rms, digest in STATS]
    (ROOT / "audio_manifest.tsv").write_text(header + "".join(rows), encoding="utf-8")
    for name, duration, peak, rms, _ in STATS:
        print(f"{name:24} {duration:7.3f}s peak={peak:.3f} RMS={rms:.3f}")


if __name__ == "__main__":
    make_menu()
    make_game()
    make_sfx()
    write_report()
