# Synthesizes the game's sound effects and ambience loops (no recordings, no third-party audio).
# Usage: python3 make_sounds.py OUT_DIR   -> 16-bit mono WAV files at 22050 Hz.
import sys, wave, numpy as np
R = 22050
rng = np.random.default_rng(7)
out = sys.argv[1]

def save(name, x, peak=0.85):
    x = np.asarray(x, float)
    m = np.max(np.abs(x)) or 1.0
    x = np.clip(x / m * peak, -1, 1)
    with wave.open(f"{out}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(R)
        w.writeframes((x * 32767).astype("<i2").tobytes())

def t(sec): return np.arange(int(R * sec)) / R
def env(n, a=0.02, r=0.2, sec=None):
    n = int(n); e = np.ones(n); ai = max(1, int(R * a)); ri = max(1, int(R * r))
    e[:ai] = np.linspace(0, 1, ai); e[-ri:] *= np.linspace(1, 0, ri); return e
def lowpass(x, cut):
    a = np.exp(-2 * np.pi * cut / R); y = np.zeros_like(x); acc = 0.0
    for i, v in enumerate(x): acc = (1 - a) * v + a * acc; y[i] = acc
    return y
def bandpass(x, lo, hi): return lowpass(x, hi) - lowpass(x, lo)
def osc(freq, kind="saw"):
    ph = np.cumsum(2 * np.pi * np.asarray(freq) / R)
    if kind == "sin": return np.sin(ph)
    if kind == "sq": return np.sign(np.sin(ph))
    return 2 * ((ph / (2 * np.pi)) % 1) - 1
def formants(src, fs):
    return sum(bandpass(src, f * 0.8, f * 1.2) * g for f, g in fs)
def loopfade(x, f=0.25):
    n = int(R * f); y = x.copy(); y[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n); return y[:-n]

# Cow: low "moo" with a slow pitch rise and fall and a nasal formant.
tt = t(1.6); f0 = 105 + 25 * np.sin(np.pi * tt / 1.6) + 2 * np.sin(2 * np.pi * 5 * tt)
src = osc(f0); moo = formants(src, [(300, 1.0), (700, 0.6), (1100, 0.2)])
moo = lowpass(moo, 1800) * env(len(tt), 0.15, 0.5); save("vaca", moo)
# Horse: whinny, fast falling vibrato then a snort.
tt = t(1.3); f0 = 700 - 380 * (tt / 1.3) ** 0.7 + 70 * np.sin(2 * np.pi * 14 * tt)
wh = formants(osc(f0), [(900, 1.0), (1800, 0.5), (2600, 0.25)]) * env(len(tt), 0.03, 0.4)
sn = bandpass(rng.standard_normal(int(R * 0.35)), 300, 2500) * env(R * 0.35, 0.01, 0.25)
save("cavalo", np.concatenate([wh, np.zeros(int(R * 0.05)), sn * 0.6]))
# Chicken: three short clucks.
parts = []
for f in (520, 480, 600):
    tt = t(0.11); c = formants(osc(f + 200 * tt), [(1000, 1), (2200, 0.5)]) * env(len(tt), 0.005, 0.07)
    parts += [c, np.zeros(int(R * 0.06))]
save("galinha", np.concatenate(parts))
# Pig: two grunts (low pulses with noise).
parts = []
for f in (95, 80):
    tt = t(0.22); g = osc(f + 30 * np.sin(2 * np.pi * 3 * tt), "sq") * 0.6 + rng.standard_normal(len(tt)) * 0.3
    parts += [lowpass(formants(g, [(400, 1), (900, 0.5)]), 1500) * env(len(tt), 0.01, 0.1), np.zeros(int(R * 0.08))]
save("porco", np.concatenate(parts))
# Sheep: bleating "baa" with strong tremolo.
tt = t(0.9); f0 = 300 + 15 * np.sin(2 * np.pi * 6 * tt)
baa = formants(osc(f0), [(800, 1), (1300, 0.6)]) * (0.6 + 0.4 * np.sin(2 * np.pi * 18 * tt)) * env(len(tt), 0.05, 0.35)
save("ovelha", baa)
# Hoof beats (one clop pair) for walking/riding.
tt = t(0.06); clop = bandpass(rng.standard_normal(len(tt)), 400, 2200) * np.exp(-tt * 60) + osc(180 + 0 * tt, "sin") * np.exp(-tt * 50) * 0.5
save("casco", np.concatenate([clop, np.zeros(int(R * 0.09)), clop * 0.7, np.zeros(int(R * 0.05))]))
# Lake: water lapping loop (filtered noise with slow swells).
tt = t(8.25); n = rng.standard_normal(len(tt))
lap = bandpass(n, 150, 900) * (0.55 + 0.45 * np.sin(2 * np.pi * 0.35 * tt) ** 2) + bandpass(n, 1500, 4000) * 0.08 * (np.sin(2 * np.pi * 0.9 * tt) > 0.7)
save("lago", loopfade(lap), 0.6)
# Farm ambience loop: soft wind plus bird chirps.
tt = t(12.25); wind = lowpass(rng.standard_normal(len(tt)), 250) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.08 * tt))
amb = wind * 3.0
for k in range(14):
    st = int(rng.uniform(0, 11.5) * R); f = rng.uniform(2200, 4200)
    for c in range(int(rng.integers(2, 5))):
        tt2 = t(rng.uniform(0.05, 0.11)); ch = osc(f + 900 * np.sin(np.pi * tt2 / tt2[-1]), "sin") * env(len(tt2), 0.005, 0.03)
        s0 = st + c * int(R * 0.13); amb[s0:s0 + len(ch)] += ch * 0.35
save("fazenda", loopfade(amb), 0.5)
# Truck engine loop: low rumble with firing pulses.
tt = t(2.25); f0 = 38 + 2 * np.sin(2 * np.pi * 0.7 * tt)
eng = osc(f0) * 0.6 + osc(f0 * 2, "sq") * 0.25 + lowpass(rng.standard_normal(len(tt)), 400) * 0.6
eng = lowpass(eng, 700) * (0.8 + 0.2 * np.sin(2 * np.pi * 19 * tt))
save("motor", loopfade(eng), 0.7)
# Horn: two-tone honk, twice.
tt = t(0.32); h = (osc(392 + 0 * tt, "sq") + osc(494 + 0 * tt, "sq")) * env(len(tt), 0.01, 0.05)
h = lowpass(h, 2500); save("buzina", np.concatenate([h, np.zeros(int(R * 0.12)), h]))
# Door: wooden creak then a thump.
tt = t(0.45); cr = formants(osc(140 + 120 * tt + 25 * np.sin(2 * np.pi * 30 * tt)), [(900, 1), (1700, 0.5)]) * env(len(tt), 0.02, 0.1) * 0.5
tt2 = t(0.18); th = lowpass(rng.standard_normal(len(tt2)), 300) * np.exp(-tt2 * 25) + osc(70 + 0 * tt2, "sin") * np.exp(-tt2 * 20)
save("porta", np.concatenate([cr, th]))
# Splash (bobber, falling in) and swim strokes.
tt = t(0.6); sp = bandpass(rng.standard_normal(len(tt)), 300, 5000) * np.exp(-tt * 9) * (1 + 0.5 * np.sin(2 * np.pi * 40 * tt))
save("splash", sp)
tt = t(0.35); st = bandpass(rng.standard_normal(len(tt)), 250, 2200) * np.sin(np.pi * tt / 0.35) ** 2
save("nado", st, 0.6)
# Cast whoosh and reel clicks.
tt = t(0.4); wh = bandpass(rng.standard_normal(len(tt)), 600, 3500) * np.sin(np.pi * tt / 0.4) ** 3
save("arremesso", wh)
tt = t(0.6); clicks = np.zeros(len(tt))
for k in range(12):
    i = int(k * 0.05 * R); clicks[i:i + 60] += bandpass(rng.standard_normal(60), 2000, 6000) * np.exp(-np.arange(60) / 12)
save("molinete", clicks)
# Footstep in the house (wood) — unused by default, kept for the house floor.
print("ok")
