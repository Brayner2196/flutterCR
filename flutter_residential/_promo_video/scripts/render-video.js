#!/usr/bin/env node
/**
 * Render del launch film a MP4 (silente).
 * Adaptado del render-video.js de huashu-design para Windows + ffmpeg-static.
 *
 * Uso: node scripts/render-video.js promo-launch-film.html [--duration=25]
 */
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');
const ffmpegPath = require('ffmpeg-static');

function arg(name, def) {
  const p = process.argv.find(a => a.startsWith('--' + name + '='));
  return p ? p.slice(name.length + 3) : def;
}

const HTML_FILE = process.argv[2];
if (!HTML_FILE) {
  console.error('Usage: node render-video.js <html-file> [--duration=25]');
  process.exit(1);
}

const DURATION = parseFloat(arg('duration', '25'));
const WIDTH    = parseInt(arg('width', '1920'));
const HEIGHT   = parseInt(arg('height', '1080'));
const READY_TIMEOUT = parseFloat(arg('readytimeout', '12'));
const FONT_WAIT = parseFloat(arg('fontwait', '2.0'));

const HTML_ABS = path.resolve(HTML_FILE);
const BASE     = path.basename(HTML_FILE, path.extname(HTML_FILE));
const DIR      = path.dirname(HTML_ABS);
const OUT_DIR  = path.join(DIR, 'output');
const TMP_DIR  = path.join(OUT_DIR, '.tmp-' + Date.now());
const MP4_OUT  = path.join(OUT_DIR, BASE + '-silent.mp4');

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.mkdirSync(TMP_DIR, { recursive: true });

console.log(`▸ Rendering: ${HTML_FILE}`);
console.log(`  size: ${WIDTH}x${HEIGHT} · duration: ${DURATION}s`);
console.log(`  output: ${MP4_OUT}`);

(async () => {
  const browser = await chromium.launch();
  const url = 'file://' + HTML_ABS;

  // Warmup (cache fonts)
  console.log('▸ Warmup (cache fonts)…');
  const warmupCtx = await browser.newContext({ viewport: { width: WIDTH, height: HEIGHT } });
  const warmupPage = await warmupCtx.newPage();
  await warmupPage.goto(url, { waitUntil: 'load', timeout: 60000 });
  await warmupPage.waitForTimeout(FONT_WAIT * 1000);
  await warmupCtx.close();

  // Record
  console.log('▸ Recording…');
  const recordCtx = await browser.newContext({
    viewport: { width: WIDTH, height: HEIGHT },
    deviceScaleFactor: 1,
    recordVideo: { dir: TMP_DIR, size: { width: WIDTH, height: HEIGHT } },
  });
  await recordCtx.addInitScript(() => { window.__recording = true; });

  // Hide scrubber chrome
  await recordCtx.addInitScript(() => {
    function hideChrome() {
      document.querySelectorAll('div').forEach(el => {
        const s = getComputedStyle(el);
        if (s.position !== 'fixed') return;
        const r = el.getBoundingClientRect();
        if (r.bottom < window.innerHeight - 100) return;
        if (r.height > window.innerHeight * 0.2) return;
        if (el.querySelector('button')) {
          el.style.setProperty('display', 'none', 'important');
        }
      });
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', hideChrome);
    } else hideChrome();
    setTimeout(hideChrome, 100);
    setTimeout(hideChrome, 500);
    setTimeout(hideChrome, 1500);
  });

  const T0 = Date.now();
  const page = await recordCtx.newPage();
  await page.goto(url, { waitUntil: 'load', timeout: 60000 });

  let animStart;
  const hasReady = await page.waitForFunction(
    () => window.__ready === true,
    { timeout: READY_TIMEOUT * 1000 },
  ).then(() => true).catch(() => false);

  if (hasReady) {
    // Seek back to t=0 to ensure clean start
    await page.evaluate(() => {
      if (typeof window.__seek === 'function') window.__seek(0);
    });
    await page.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))));
    animStart = (Date.now() - T0) / 1000;
    console.log(`▸ Ready at ${animStart.toFixed(2)}s + __seek(0)`);
  } else {
    await page.waitForTimeout(FONT_WAIT * 1000);
    animStart = (Date.now() - T0) / 1000;
    console.log(`⚠ No __ready signal, fallback offset ${animStart.toFixed(2)}s`);
  }

  // +2s buffer so trim+DURATION doesn't run past the WebM tail
  await page.waitForTimeout(DURATION * 1000 + 2000);

  await page.close();
  await recordCtx.close();
  await browser.close();

  const webms = fs.readdirSync(TMP_DIR).filter(f => f.endsWith('.webm'));
  if (webms.length === 0) {
    console.error('✗ No webm produced');
    process.exit(1);
  }
  const webmPath = path.join(TMP_DIR, webms[0]);
  console.log(`▸ WebM: ${(fs.statSync(webmPath).size / 1024 / 1024).toFixed(1)} MB`);

  const trim = animStart + (hasReady ? 0.08 : 0.5);
  console.log(`▸ ffmpeg: trim=${trim.toFixed(2)}s, encode H.264…`);

  const ff = spawnSync(ffmpegPath, [
    '-y',
    '-ss', String(trim),
    '-i', webmPath,
    '-t', String(DURATION),
    '-c:v', 'libx264',
    '-pix_fmt', 'yuv420p',
    '-crf', '18',
    '-preset', 'medium',
    '-movflags', '+faststart',
    MP4_OUT,
  ], { stdio: ['ignore', 'ignore', 'pipe'] });

  if (ff.status !== 0) {
    console.error('✗ ffmpeg failed:\n' + ff.stderr.toString().slice(-2000));
    process.exit(1);
  }

  fs.rmSync(TMP_DIR, { recursive: true, force: true });
  const size = (fs.statSync(MP4_OUT).size / 1024 / 1024).toFixed(1);
  console.log(`✓ Done: ${MP4_OUT} (${size} MB)`);
})().catch(e => { console.error(e); process.exit(1); });
