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
const output = path.resolve('work/performance-browser');

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
    for (const mode of ['low', 'balanced', 'high']) {
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
            value.show = title => {
              performanceCheck.phase = `loading:${title}`;
              performanceCheck.transitions.push({ title, start: performance.now() });
              return show(title);
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
      console.log(JSON.stringify({ mode, transitions: result.transitions,
        longestTaskMs: Math.max(0, ...result.longTasks.map(task => task.duration)),
        longestSceneTaskMs: result.longestSceneTaskMs, errors }));
      assert.deepEqual(errors, [], `${mode} raised browser errors`);
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
