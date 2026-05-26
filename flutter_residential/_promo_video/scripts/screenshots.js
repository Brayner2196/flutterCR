#!/usr/bin/env node
/**
 * Toma screenshots del launch film en keyframes clave.
 * Espera __ready, luego usa window.__seek(t) para saltar a cada timestamp.
 * Output: _promo_video/output/keyframes/keyframe-{t}s.png
 */
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const HTML = path.resolve(__dirname, '..', 'promo-launch-film.html');
const OUT_DIR = path.resolve(__dirname, '..', 'output', 'keyframes');

const KEYFRAMES = [
  { t: 0.6,  label: 'hook-01-tagline-begin' },
  { t: 2.0,  label: 'hook-02-tagline-full' },
  { t: 4.2,  label: 'login-01-typewriter-mid' },
  { t: 6.8,  label: 'login-02-button-press' },
  { t: 9.0,  label: 'dashboard-01-deuda-cards-2' },
  { t: 11.5, label: 'dashboard-02-full-stack' },
  { t: 13.5, label: 'pagos-01-estado-cuenta' },
  { t: 15.0, label: 'pagos-02-success' },
  { t: 18.5, label: 'reservas-01-calendar' },
  { t: 19.5, label: 'reservas-02-confirm' },
  { t: 22.5, label: 'closing-01-logo' },
  { t: 24.0, label: 'closing-02-final' },
];

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  console.log(`▸ Launching Chromium...`);
  const browser = await chromium.launch();
  const ctx = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    deviceScaleFactor: 1,
  });
  await ctx.addInitScript(() => { window.__recording = true; });
  const page = await ctx.newPage();

  console.log(`▸ Loading: ${HTML}`);
  await page.goto('file://' + HTML, { waitUntil: 'load', timeout: 60000 });
  await page.waitForFunction(() => window.__ready === true, { timeout: 15000 });
  await page.waitForTimeout(500);

  // Hide Stage chrome (scrubber) for clean screenshots
  await page.addStyleTag({
    content: `
      [style*="position: fixed"][style*="bottom: 0"][style*="background: rgba(0, 0, 0, 0.8)"],
      div[style*="rgba(0,0,0,0.8)"] { display: none !important; }
    `,
  });

  for (const { t, label } of KEYFRAMES) {
    await page.evaluate((time) => {
      if (typeof window.__seek === 'function') window.__seek(time);
    }, t);
    // Wait two frames for the seek to apply + render
    await page.evaluate(() =>
      new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)))
    );
    await page.waitForTimeout(120);
    const outPath = path.join(OUT_DIR, `t${String(t).padStart(5, '0')}s-${label}.png`);
    await page.screenshot({ path: outPath, fullPage: false });
    console.log(`✓ ${path.basename(outPath)}`);
  }

  await browser.close();
  console.log(`\n✓ ${KEYFRAMES.length} keyframes en ${OUT_DIR}`);
})().catch(e => { console.error(e); process.exit(1); });
