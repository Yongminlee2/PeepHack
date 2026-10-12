# -*- coding: utf-8 -*-
"""효과음 5개를 합성해 assets/sfx/ 에 쓴다(표준 라이브러리만). 프로젝트 루트에서: python tool/gen_sfx.py"""
import math, os, random, struct, wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")
random.seed(42)


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))
    print("wrote", name, round(len(samples) / SR, 3), "s")


def env(i, n, attack=0.004):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * (1.0 - i / n)


def tone(freq, ms, vol=0.5, shape="sine", sweep_to=None):
    n = int(SR * ms / 1000); out = []; phase = 0.0
    for i in range(n):
        f = freq if sweep_to is None else freq + (sweep_to - freq) * i / n
        phase += 2 * math.pi * f / SR
        if shape == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
        elif shape == "tri":
            v = 2 / math.pi * math.asin(math.sin(phase))
        else:
            v = math.sin(phase)
        out.append(v * vol * env(i, n))
    return out


def noise(ms, vol=0.4, lowpass=0.3):
    n = int(SR * ms / 1000); out = []; prev = 0.0
    for i in range(n):
        prev += lowpass * (random.uniform(-1, 1) - prev)
        out.append(prev * vol * env(i, n))
    return out


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def mix(a, b):
    n = max(len(a), len(b))
    return [max(-1, min(1, (a[i] if i < len(a) else 0) + (b[i] if i < len(b) else 0))) for i in range(n)]


# 키 입력: 기계식 키보드 딸깍(짧은 노이즈 + 높은 틱)
write_wav("key", mix(noise(18, 0.35, 0.9), tone(2400, 12, 0.15, "square")))
# 칩 누르기: 짧은 디지털 블립
write_wav("tap", tone(1200, 35, 0.22, "square"))
# 실행: 위로 올라가는 짧은 스윕
write_wav("run", tone(500, 90, 0.25, "square", sweep_to=1100))
# 성공: 세 음 아르페지오(터미널 「접속 허가」)
write_wav("ok", concat(tone(660, 70, 0.3, "square"), tone(880, 70, 0.3, "square"), tone(1320, 140, 0.3, "square")))
# 경보: 두 음을 오가는 사이렌(추적 70%)
write_wav("alarm", concat(*[tone(f, 120, 0.28, "square") for f in (880, 660, 880, 660)]))
# 실패: 낮게 떨어지는 버즈
write_wav("fail", mix(tone(220, 180, 0.3, "square", sweep_to=110), noise(120, 0.15, 0.5)))
# 목표 완료: 맑은 두 음 위로
write_wav("daemon", concat(tone(988, 60, 0.28, "square"), tone(1480, 110, 0.28, "square")))
# 연쇄: 빠른 네 음 상승 + 반짝이
write_wav("chain", mix(concat(*[tone(f, 55, 0.3, "square") for f in (784, 988, 1175, 1568)]), concat(tone(1, 160, 0), noise(90, 0.12, 0.95))))
# 별: 짧은 딩
write_wav("star", tone(1760, 120, 0.25, "sine"))
# 도장: 낮은 쿵 + 종이 소리
write_wav("stamp", mix(tone(120, 140, 0.45, "sine", sweep_to=60), noise(80, 0.25, 0.4)))
