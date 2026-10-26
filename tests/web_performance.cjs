/* Browser startup and opening-to-bedroom transition under CPU throttling.
 * NODE_PATH must include Playwright. Starts a temporary loopback-only server.
 * node tests/web_performance.cjs [build directory] [CPU slowdown, default 4]
 */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const http = require('node:http');
const build = path.resolve(process.argv[2] || 'build/web');
const slowdown = Number(process.argv[3] || 4);
const output = path.resolve(process.env.PERF_OUTPUT_DIR || 'work/performance-browser');
const modes = (process.env.PERF_MODES || 'low,balanced,high').split(',');

async function checkLoadingSurface(browser, origin) {
  for (const viewport of [{ width: 1280, height: 720 }, { width: 390, height: 844 }]) {
    const context = await browser.newContext({ viewport, reducedMotion: 'reduce' });
    const page = await context.newPage();
    // Exercise the real loading shell without starting a second game engine.
    await page.route('**/index.js', route => route.fulfill({ body: '', contentType: 'application/javascript' }));
    await page.goto(origin, { waitUntil: 'networkidle' });
    const values = await page.evaluate(() => {
      const read = () => Number(document.getElementById('loading-track').getAttribute('aria-valuenow'));
      digiLoading.progress(50, 100);
      const download = read();
      digiLoading.progress(100, 100);
      const downloaded = read();
      digiLoading.show('Digi World');
      digiLoading.scene_progress(0.5, 'Preparing scenery');
      const preparing = read();
      digiLoading.scene_progress(0.2, 'Preparing scenery');
      const earlierUpdate = read();
      digiLoading.ready();
      const ready = read();
      digiLoading.show('Your bedroom');
      const reset = read();
      digiLoading.scene_progress(0.64, 'Preparing scenery');
      digiLoading.progress(100, 100);
      return { download, downloaded, preparing, earlierUpdate, ready, reset, scene: read(),
        pending: document.getElementById('loading-track').classList.contains('is-pending') };
    });
    assert(values.download > 0 && values.download < values.downloaded && values.downloaded < 100,
      'Download completion must reserve progress for scene preparation');
    assert(values.preparing >= values.downloaded && values.earlierUpdate === values.preparing,
      'Preparation progress must not move backwards');
    assert(values.ready === 100 && values.reset === 0 && values.scene === 64 && !values.pending,
      'Each scene must have a new determinate progress bar and ignore late download callbacks');
    const bounds = await page.locator('#loading-track').boundingBox();
    assert(bounds.x >= 0 && bounds.x + bounds.width <= viewport.width && bounds.height >= 10,
      'Loading progress must fit the viewport and remain visible');
    await page.screenshot({ path: path.join(output, `progress-${viewport.width}.png`) });
    await context.close();
  }
}

(async () => {
  await fs.mkdir(output, { recursive: true });
  const server = http.createServer(async (request, response) => {
    const url = new URL(request.url, 'http://127.0.0.1');
    const file = path.resolve(build, decodeURIComponent(url.pathname).slice(1) || 'index.html');
    if (!file.startsWith(build + path.sep)) { response.writeHead(403).end(); return; }
    const mime = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm',
      '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.png': 'image/png' };
    try {
      const body = await fs.readFile(file);
      response.writeHead(200, { 'Content-Type': mime[path.extname(file)] || 'application/octet-stream' });
      response.end(body);
    } catch { response.writeHead(404).end(); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_BIN || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true, args: ['--autoplay-policy=no-user-gesture-required']
  });
  const results = [];
  try {
    if (process.env.BASELINE !== '1' && process.env.PERF_SKIP_SURFACE_QA !== '1') await checkLoadingSurface(browser, origin);
    for (const mode of modes) {
      const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', error => errors.push(error.message));
      page.on('console', message => {
        if (message.type() === 'error') console.error(mode, message.text());
        if (/^(SCRIPT ERROR:|ERROR:)/.test(message.text())) {
          errors.push(message.text());
          console.error(mode, message.text());
        }
      });
      await page.addInitScript(() => {
        window.performanceCheck = { phase: 'startup', longTasks: [], transitions: [], marks: [] };
        new PerformanceObserver(list => {
          for (const entry of list.getEntries()) {
            performanceCheck.longTasks.push({ phase: performanceCheck.phase, start: entry.startTime, duration: entry.duration });
          }
        }).observe({ type: 'longtask', buffered: true });
        new PerformanceObserver(list => {
          for (const entry of list.getEntries()) performanceCheck.marks.push({ name: entry.name, start: entry.startTime });
        }).observe({ type: 'mark', buffered: true });
        let loading;
        Object.defineProperty(window, 'digiLoading', {
          get: () => loading,
          set(value) {
            loading = value;
            const show = value.show.bind(value);
            const ready = value.ready.bind(value);
            const sceneProgress = value.scene_progress?.bind(value);
            value.show = title => {
              performanceCheck.phase = `loading:${title}`;
              performanceCheck.transitions.push({ title, start: performance.now(), progress: [] });
              return show(title);
            };
            if (sceneProgress) value.scene_progress = (fraction, stage) => {
              const result = sceneProgress(fraction, stage);
              performanceCheck.transitions.at(-1).progress.push({ fraction, stage,
                percent: Number(document.getElementById('loading-track').getAttribute('aria-valuenow')),
                pending: document.getElementById('loading-track').classList.contains('is-pending') });
              return result;
            };
            value.ready = () => {
              performanceCheck.transitions.at(-1).ready = performance.now();
              performanceCheck.phase = 'gameplay';
              return ready();
            };
          }
        });
      });
      const session = await context.newCDPSession(page);
      await session.send('Emulation.setCPUThrottlingRate', { rate: slowdown });
      await page.goto(`${origin}/?quality=${mode}&profile_loading=1`, { waitUntil: 'domcontentloaded' });
      try {
        await page.waitForFunction(() => document.getElementById('canvas').getAttribute('aria-busy') === 'false', null, { timeout: 120000 });
      } catch (error) {
        await page.screenshot({ path: path.join(output, `${mode}-failure.png`) });
        console.error(await page.evaluate(() => ({ check: performanceCheck, status: document.getElementById('loading-status')?.textContent })), errors);
        throw error;
      }
      await page.waitForTimeout(6500);
      await page.screenshot({ path: path.join(output, `${mode}-opening.png`) });
      await page.mouse.click(640, 501);
      await page.waitForFunction(() => performanceCheck.transitions.some(item => /bedroom/i.test(item.title) && item.ready), null, { timeout: 120000 });
      await page.waitForTimeout(1000);
      await page.screenshot({ path: path.join(output, `${mode}-bedroom.png`) });
      const result = await page.evaluate(() => performanceCheck);
      result.mode = mode;
      result.slowdown = slowdown;
      result.errors = errors;
      const sceneStart = result.marks.find(mark => mark.name.startsWith('digi-loading: resources:')).start;
      const sceneTasks = result.longTasks.filter(task => task.start >= sceneStart);
      result.longestSceneTaskMs = Math.max(0, ...sceneTasks.map(task => task.duration));
      results.push(result);
      await fs.writeFile(path.join(output, 'results.json'), JSON.stringify(results, null, 2));
      console.log(JSON.stringify({ mode, transitions: result.transitions.map(item => ({ title: item.title, loadMs: Math.round(item.ready - item.start) })),
        longestTaskMs: Math.max(0, ...result.longTasks.map(task => task.duration)),
        longestSceneTaskMs: result.longestSceneTaskMs, errors }));
      assert.deepEqual(errors, [], `${mode} raised browser errors`);
      if (process.env.BASELINE !== '1') {
        for (const transition of result.transitions) {
          assert(transition.progress.length > 4, `${mode}: scene progress was not reported`);
          assert.equal(transition.progress.at(-1).percent, 100, `${mode}: loading never reached 100%`);
          assert(transition.progress.some(item => /scenery/i.test(item.stage)), `${mode}: scenery stage was missing`);
          assert(transition.progress.some(item => /first view/i.test(item.stage)), `${mode}: rendering stage was missing`);
          for (let i = 0; i < transition.progress.length; i++) {
            const item = transition.progress[i];
            assert(!item.pending, `${mode}: scene loading used an indeterminate bar`);
            assert(item.percent >= 0 && item.percent <= 100, `${mode}: invalid progress`);
            if (i > 0) assert(item.percent >= transition.progress[i - 1].percent, `${mode}: progress moved backwards`);
            if (item.fraction < 1) assert(item.percent < 100, `${mode}: loading showed 100% before ready`);
          }
        }
      }
      // This detects a regression to multi-second main-thread freezes; it is
      // deliberately a responsiveness bound, not a hardware-independent FPS claim.
      assert(result.longestSceneTaskMs < 5000,
        `${mode} blocked the browser thread for five seconds`);
      await context.close();
    }
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
