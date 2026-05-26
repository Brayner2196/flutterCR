#!/usr/bin/env node
/**
 * Mezcla audio en el MP4 silente:
 *   BGM (bgm-educational, -18dB, fade in/out) + SFX cues posicionados con adelay.
 *
 * Uso: node scripts/mix-audio.js
 * Input:  output/promo-launch-film-silent.mp4
 * Output: output/promo-final.mp4
 */
const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');
const ffmpegPath = require('ffmpeg-static');

const ROOT = path.resolve(__dirname, '..');
const SKILL = path.resolve(ROOT, '..', '.claude', 'skills', 'huashu-design', 'assets');
const SFX = path.join(SKILL, 'sfx');

const INPUT  = path.join(ROOT, 'output', 'promo-launch-film-silent.mp4');
const BGM    = path.join(SKILL, 'bgm-educational.mp3');
const OUTPUT = path.join(ROOT, 'output', 'promo-final.mp4');

if (!fs.existsSync(INPUT)) {
  console.error('✗ Input MP4 missing: ' + INPUT);
  console.error('  Run: node scripts/render-video.js promo-launch-film.html');
  process.exit(1);
}
if (!fs.existsSync(BGM)) {
  console.error('✗ BGM missing: ' + BGM);
  process.exit(1);
}

// SFX cues: [timestamp_seconds, file, gain_db]
const CUES = [
  // Login typewriter — email (3.6 → 5.0)
  [3.60, 'keyboard/type.mp3',          -4],
  [3.80, 'keyboard/type.mp3',          -6],
  [4.05, 'keyboard/type.mp3',          -4],
  [4.30, 'keyboard/type.mp3',          -6],
  [4.55, 'keyboard/type.mp3',          -4],
  [4.85, 'keyboard/type.mp3',          -5],
  // Login typewriter — password (5.2 → 6.4)
  [5.25, 'keyboard/type.mp3',          -8],
  [5.55, 'keyboard/type.mp3',          -9],
  [5.95, 'keyboard/type.mp3',          -8],
  [6.30, 'keyboard/type.mp3',          -9],
  // Login submit
  [6.85, 'keyboard/enter.mp3',         -3],
  // Transition to dashboard
  [7.10, 'transition/whoosh.mp3',      -6],
  // Tap on Estado de Cuenta
  [12.10, 'ui/tap-finger.mp3',         -4],
  // Pago success
  [14.85, 'feedback/success-chime.mp3', -3],
  // Swipe to reservas
  [17.10, 'transition/swipe-horizontal.mp3', -6],
  // Reserva confirm
  [19.20, 'feedback/notification-pop.mp3', -3],
  // Closing logo reveal
  [21.90, 'impact/logo-reveal.mp3',    -5],
];

// Validate all SFX files exist
for (const [, file] of CUES) {
  const fullPath = path.join(SFX, file);
  if (!fs.existsSync(fullPath)) {
    console.error(`✗ SFX missing: ${fullPath}`);
    process.exit(1);
  }
}

console.log('▸ Building ffmpeg command:');
console.log(`  input:  ${path.basename(INPUT)}`);
console.log(`  bgm:    bgm-educational.mp3 (−18 dB)`);
console.log(`  cues:   ${CUES.length} sfx events`);
console.log(`  output: ${path.basename(OUTPUT)}`);

// Build filter_complex:
//   - bgm: trim to 25s, fade in 0.3s, fade out 1.0s, volume -18dB
//   - each sfx: adelay to its t, volume
//   - amix everything together
// Stream indexes: 0=video MP4, 1=bgm, 2..N+1=sfx

const DURATION = 25;
const FADE_OUT_START = DURATION - 1.0;

const inputs = ['-i', INPUT, '-i', BGM];
for (const [, file] of CUES) inputs.push('-i', path.join(SFX, file));

const filterParts = [];

// BGM track
filterParts.push(
  `[1:a]atrim=0:${DURATION},asetpts=PTS-STARTPTS,` +
  `afade=t=in:st=0:d=0.3,afade=t=out:st=${FADE_OUT_START}:d=1.0,` +
  `volume=-18dB[bgm]`
);

// SFX tracks
const sfxLabels = [];
CUES.forEach(([t, , gain], i) => {
  const inputIdx = i + 2;          // bgm is input 1, sfx start at 2
  const delayMs = Math.round(t * 1000);
  const label = `sfx${i}`;
  filterParts.push(
    `[${inputIdx}:a]adelay=${delayMs}|${delayMs},volume=${gain}dB[${label}]`
  );
  sfxLabels.push(`[${label}]`);
});

// Mix BGM + all SFX
const mixInputs = '[bgm]' + sfxLabels.join('');
filterParts.push(
  `${mixInputs}amix=inputs=${1 + CUES.length}:duration=longest:normalize=0[aout]`
);

const filterComplex = filterParts.join(';');

const ffArgs = [
  '-y',
  ...inputs,
  '-filter_complex', filterComplex,
  '-map', '0:v',
  '-map', '[aout]',
  '-c:v', 'copy',
  '-c:a', 'aac',
  '-b:a', '192k',
  '-shortest',
  OUTPUT,
];

console.log('▸ Running ffmpeg (mix BGM + ' + CUES.length + ' SFX)…');
const res = spawnSync(ffmpegPath, ffArgs, { stdio: ['ignore', 'pipe', 'pipe'] });

if (res.status !== 0) {
  console.error('✗ ffmpeg failed:');
  console.error(res.stderr.toString().slice(-3000));
  process.exit(1);
}

const size = (fs.statSync(OUTPUT).size / 1024 / 1024).toFixed(1);
console.log(`✓ Done: ${OUTPUT} (${size} MB)`);

// Verify audio stream exists
const ffprobePath = require('ffprobe-static').path;
const probe = spawnSync(ffprobePath, [
  '-v', 'error',
  '-select_streams', 'a:0',
  '-show_entries', 'stream=codec_name,sample_rate,channels',
  '-of', 'json',
  OUTPUT,
]);
if (probe.status === 0) {
  const info = JSON.parse(probe.stdout.toString());
  if (info.streams && info.streams.length) {
    const s = info.streams[0];
    console.log(`✓ Audio: ${s.codec_name} ${s.sample_rate}Hz ${s.channels}ch`);
  } else {
    console.warn('⚠ No audio stream detected in output');
  }
}
