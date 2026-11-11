// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Visual effects (splashes, ripples, sparkles, fireflies) and sound effects (Web Audio).
'use strict';

const fx = { parts: [], ripples: [] };
function splash(x, y, n, col) {
  for (let i = 0; i < n; i++) { const a = -Math.PI * (0.15 + rng() * 0.7), sp = 20 + rng() * 40; fx.parts.push({ x, y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, g: 120, life: 0.5 + rng() * 0.3, col, s: 1 }); }
}
function sparkle(x, y, n, col) { for (let i = 0; i < n; i++) { const a = rng() * 6.28, sp = 10 + rng() * 30; fx.parts.push({ x, y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, g: 0, life: 0.6 + rng() * 0.6, col, s: 1, tw: true }); } }
function ripple(x, y) { fx.ripples.push({ x, y, r: 1, life: 1 }); }
function updateFx(dt) {
  for (const p of fx.parts) { p.x += p.vx * dt; p.y += p.vy * dt; p.vy += p.g * dt; p.life -= dt; }
  fx.parts = fx.parts.filter(p => p.life > 0);
  for (const r of fx.ripples) { r.r += 10 * dt; r.life -= dt * 0.9; }
  fx.ripples = fx.ripples.filter(r => r.life > 0);
}
function drawFx(g, cx, cy, t) {
  for (const r of fx.ripples) {
    g.globalAlpha = Math.max(0, r.life) * 0.8; g.strokeStyle = PAL.foam; g.lineWidth = 1;
    g.beginPath(); g.ellipse(Math.round(r.x - cx) + 0.5, Math.round(r.y - cy) + 0.5, r.r * 1.6, r.r * 0.8, 0, 0, Math.PI * 2); g.stroke();
  }
  g.globalAlpha = 1;
  for (const p of fx.parts) {
    if (p.tw && Math.sin(t * 30 + p.x) < -0.3) continue;
    g.globalAlpha = Math.min(1, p.life * 2); R(g, Math.round(p.x - cx), Math.round(p.y - cy), p.s, p.s, p.col);
  }
  g.globalAlpha = 1;
}

// ---- Sound effects ----
function noise(dur, vol = 0.2, freq = 1200) {
  if (!audio || muted) return;
  const ac = audio.ac, n = Math.floor(ac.sampleRate * dur), b = ac.createBuffer(1, n, ac.sampleRate), d = b.getChannelData(0);
  let z = 12345; // audio texture only: its own generator, so sound never moves the gameplay rng
  for (let i = 0; i < n; i++) { z = (Math.imul(z, 1103515245) + 12345) | 0; d[i] = ((z >>> 16) / 32768 - 1) * (1 - i / n); }
  const src = ac.createBufferSource(), f = ac.createBiquadFilter(), g = ac.createGain();
  src.buffer = b; f.type = 'lowpass'; f.frequency.value = freq; g.gain.value = vol;
  src.connect(f).connect(g).connect(audio.out); src.start();
}
const sfx = {
  cast() { noise(0.25, 0.15, 2500); tone(520, 0.12, 'triangle', 0.12); },
  splash() { noise(0.35, 0.25, 900); },
  nibble() { tone(330, 0.05, 'sine', 0.12); },
  bite() { tone(880, 0.08, 'square', 0.18); setTimeout(() => tone(1100, 0.1, 'square', 0.18), 90); noise(0.2, 0.2, 1500); },
  hook() { tone(220, 0.15, 'sawtooth', 0.12); },
  reelTick(p) { tone(400 + p * 500, 0.03, 'square', 0.05); },
  reel() { tone(300, 0.08, 'triangle', 0.1); },
  catch() { [523, 659, 784, 1046].forEach((f, i) => setTimeout(() => tone(f, 0.16, 'square', 0.16), i * 80)); noise(0.3, 0.2, 1200); },
  escape() { tone(300, 0.2, 'sawtooth', 0.12); setTimeout(() => tone(200, 0.3, 'sawtooth', 0.12), 120); },
  coin() { tone(988, 0.07, 'square', 0.14); setTimeout(() => tone(1319, 0.14, 'square', 0.14), 70); },
  deny() { tone(150, 0.15, 'square', 0.12); },
  click() { tone(660, 0.04, 'square', 0.08); },
  eat() { tone(440, 0.06, 'triangle', 0.15); setTimeout(() => tone(550, 0.08, 'triangle', 0.15), 80); },
  luck() { [784, 988, 1175, 1568].forEach((f, i) => setTimeout(() => tone(f, 0.12, 'triangle', 0.12), i * 60)); },
  level() { [523, 659, 784, 659, 784, 1046].forEach((f, i) => setTimeout(() => tone(f, 0.2, 'square', 0.15), i * 120)); },
  door() { noise(0.15, 0.12, 600); tone(200, 0.1, 'triangle', 0.08); },
};
