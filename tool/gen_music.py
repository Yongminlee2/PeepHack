# -*- coding: utf-8 -*-
"""배경음악(어두운 신스 반복곡)을 합성해 assets/music/ambient.wav 로 쓴다. 저작권 없음(직접 만든 곡).

프로젝트 루트에서: python tool/gen_music.py   (numpy 필요)

구성: 90 BPM, 16마디(약 43초), Am - F - Dm - E 를 네 번.
  1~4마디 패드만 → 5마디부터 베이스 → 9마디부터 아르페지오·하이햇 → 13마디부터 킥.
끝의 잔향(꼬리)을 처음으로 겹쳐 넣어서 이어 돌려도 끊김이 없다.
"""
import os
import wave

import numpy as np

SR = 22050
BPM = 90
BEAT = 60 / BPM
BAR = BEAT * 4
BARS = 16
L = int(SR * BAR * BARS)
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'music', 'ambient.wav')
rng = np.random.default_rng(7)

buf = np.zeros(L)


def add(sig, start_sec):
    """신호를 반복 버퍼에 더한다(끝을 넘으면 처음으로 감는다)."""
    i0 = int(start_sec * SR)
    idx = (np.arange(len(sig)) + i0) % L
    np.add.at(buf, idx, sig)


def hz(note):  # MIDI 번호 → 주파수
    return 440.0 * 2 ** ((note - 69) / 12)


def saw(f, n, detune=0.0):
    t = np.arange(n) / SR
    ph = (t * f * (1 + detune)) % 1.0
    return 2 * ph - 1


def lowpass(sig, cutoff):
    """FFT 로 부드럽게 깎는 저역 통과."""
    spec = np.fft.rfft(sig)
    fr = np.fft.rfftfreq(len(sig), 1 / SR)
    spec *= 1 / (1 + (fr / cutoff) ** 4)
    return np.fft.irfft(spec, len(sig))


def env(n, a, r, sustain=1.0):
    e = np.ones(n) * sustain
    na, nr = int(a * SR), int(r * SR)
    e[:na] = np.linspace(0, sustain, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e


# 화음(MIDI): Am, F, Dm, E
CHORDS = [[57, 60, 64], [53, 57, 60], [50, 53, 57], [52, 56, 59]]

for bar in range(BARS):
    chord = CHORDS[bar % 4]
    t0 = bar * BAR

    # 패드: 음마다 살짝 어긋난 톱니 셋 → 저역 통과 → 느린 시작·끝(다음 마디와 겹친다)
    n = int(SR * (BAR + 1.2))
    pad = np.zeros(n)
    for note in chord + [chord[0] + 12]:
        for d in (-0.004, 0.0, 0.005):
            pad += saw(hz(note), n, d)
    pad = lowpass(pad, 900) * env(n, 0.8, 1.4) * 0.035
    add(pad, t0)

    # 베이스: 8분음 펄스(5마디부터)
    if bar >= 4:
        for k in range(8):
            m = int(SR * BEAT / 2 * 0.9)
            b = lowpass(saw(hz(chord[0] - 24), m), 400) * env(m, 0.005, 0.12) * 0.22
            add(b, t0 + k * BEAT / 2)

    # 아르페지오: 16분음, 화음 음을 오르내림 + 메아리(9마디부터)
    if bar >= 8:
        pattern = [0, 1, 2, 3, 2, 1, 0, 1] * 2
        notes = chord + [chord[0] + 12]
        for k, p in enumerate(pattern):
            m = int(SR * 0.16)
            f = hz(notes[p] + 12)
            tt = np.arange(m) / SR
            tone = np.sign(np.sin(2 * np.pi * f * tt)) * 0.5 + np.sin(2 * np.pi * f * tt) * 0.5
            tone = lowpass(tone, 2500) * env(m, 0.003, 0.12) * 0.06
            st = t0 + k * BEAT / 4
            add(tone, st)
            add(tone * 0.35, st + BEAT * 0.75)  # 메아리
            add(tone * 0.12, st + BEAT * 1.5)

        # 하이햇: 엇박마다 짧은 잡음
        for k in range(8):
            m = int(SR * 0.04)
            noise = rng.uniform(-1, 1, m)
            noise = (noise - lowpass(noise, 6000)) * env(m, 0.001, 0.035) * 0.05
            add(noise, t0 + k * BEAT / 2 + BEAT / 4)

    # 킥: 1·3박에 아래로 떨어지는 사인(13마디부터)
    if bar >= 12:
        for k in (0, 2):
            m = int(SR * 0.25)
            tt = np.arange(m) / SR
            f = 110 * np.exp(-tt * 18) + 45
            kick = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(m, 0.002, 0.2) * 0.35
            add(kick, t0 + k * BEAT)

buf /= np.max(np.abs(buf)) / 0.7  # 약 -3dB
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with wave.open(OUT, 'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((buf * 32767).astype('<i2').tobytes())
print('wrote', OUT, round(L / SR, 1), 's', os.path.getsize(OUT) // 1024, 'KB')
