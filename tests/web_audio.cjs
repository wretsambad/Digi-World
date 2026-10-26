/* Real Chrome checks for blocked/allowed autoplay, global recovery and touch.
 * NODE_PATH must include Playwright. Requests use the built files directly,
 * so no listening server or external network access is needed.
 * Run: node tests/web_audio.cjs
 */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');

const url = process.argv[2] || 'http://127.0.0.1:8060/';
const directory = path.resolve('work/music/web-audio');
const build = path.resolve(process.env.WEB_BUILD_DIR || 'build/web');
const executablePath = process.env.CHROME_BIN || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const sessions = new WeakMap();

async function read(page, expression) {
  const result = await sessions.get(page).send('Runtime.evaluate', {
    expression, returnByValue: true, awaitPromise: true, userGesture: false
  });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
  return result.result.value;
}

async function waitFor(page, expression, timeout = 90000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    if (await read(page, expression)) return;
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  console.log('Audio diagnostics:', await read(page, `({
    state: digiAudio.state, times: audioTest.contexts.map(context => context.currentTime),
    starts: audioTest.starts, connections: audioTest.connections,
    gains: audioTest.gains.map(node => node.gain.value), edges: audioTest.edges
  })`));
  throw new Error(`Timed out: ${expression}`);
}

async function instrument(page) {
  await page.addInitScript(() => {
    window.audioTest = { contexts: [], starts: [], analysers: [], canvasInputs: 0, connections: [], gains: [], edges: [] };
    window.addEventListener('pointerdown', event => {
      if (event.target.id === 'canvas') window.audioTest.canvasInputs++;
    }, true);
    const connect = AudioNode.prototype.connect;
    AudioNode.prototype.connect = function (destination, ...args) {
      if (this instanceof GainNode && destination instanceof GainNode) {
        audioTest.edges.push([audioTest.gains.indexOf(this), audioTest.gains.indexOf(destination)]);
      }
      if (destination === this.context.destination) {
        window.audioTest.connections.push(this.constructor.name);
        const analyser = this.context.audioTestAnalyser;
        if (analyser) {
          connect.call(this, analyser, ...args);
          connect.call(analyser, destination);
          return destination;
        }
      }
      return connect.call(this, destination, ...args);
    };
    const Native = window.AudioContext;
    window.AudioContext = new Proxy(Native, {
      construct(target, args, newTarget) {
        const context = Reflect.construct(target, args, newTarget);
        window.audioTest.contexts.push(context);
        const createGain = context.createGain.bind(context);
        context.createGain = (...options) => {
          const gain = createGain(...options);
          audioTest.gains.push(gain);
          return gain;
        };
        const analyser = context.createAnalyser();
        analyser.fftSize = 2048;
        context.audioTestAnalyser = analyser;
        window.audioTest.analysers.push(analyser);
        // Worklet fetches bypass page routing in Chromium. Fetch the exact
        // built module through the routed page, then load those bytes locally.
        if (context.audioWorklet) {
          const addModule = context.audioWorklet.addModule.bind(context.audioWorklet);
          context.audioWorklet.addModule = async (url, options) => {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`Worklet download failed: ${url}`);
            const local = URL.createObjectURL(new Blob([await response.text()], { type: 'application/javascript' }));
            try { return await addModule(local, options); }
            finally { URL.revokeObjectURL(local); }
          };
        }
        const createSource = context.createBufferSource.bind(context);
        context.createBufferSource = (...options) => {
          const source = createSource(...options);
          const start = source.start.bind(source);
          source.start = (...timing) => {
            const data = source.buffer?.getChannelData(0);
            const peak = data ? Math.max(...data.slice(0, 48000).map(Math.abs)) : 0;
            window.audioTest.starts.push({ seconds: source.buffer?.duration, loop: source.loop, peak });
            return start(...timing);
          };
          return source;
        };
        return context;
      }
    });
  });
}

const audible = `audioTest.analysers.some(analyser => {
  const samples = new Float32Array(analyser.fftSize);
  analyser.getFloatTimeDomainData(samples);
  return samples.some(sample => Math.abs(sample) > 0.00001);
})`;

async function loaded(page) {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  sessions.set(page, await page.context().newCDPSession(page));
  const origin = new URL(url).origin;
  const basePath = new URL(url).pathname.replace(/\/?$/, '/');
  await page.route('**/*', async route => {
    const request = new URL(route.request().url());
    if (request.origin !== origin || !request.pathname.startsWith(basePath)) return route.abort();
    const resource = path.resolve(build, decodeURIComponent(request.pathname.slice(basePath.length)) || 'index.html');
    if (!resource.startsWith(build + path.sep)) return route.abort();
    const mime = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm',
      '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.png': 'image/png' };
    try {
      await route.fulfill({ body: await fs.readFile(resource),
        contentType: mime[path.extname(resource)] || 'application/octet-stream' });
    } catch (_) {
      await route.fulfill({ status: 404, body: 'Not found' });
    }
  });
  await instrument(page);
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  // Playwright evaluation/locators can grant a CDP user gesture. Observe via
  // Runtime.evaluate with userGesture:false until the actual test interaction.
  await waitFor(page, "document.getElementById('canvas').getAttribute('aria-busy') === 'false'");
  assert.deepEqual(errors, [], 'The web game raised a JavaScript error');
}

async function checkBlocked(browser, mobile) {
  const context = await browser.newContext(mobile
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 } });
  try {
    const page = await context.newPage();
    await loaded(page);
    console.log('Browser audio at load:', await read(page, `({
      state: digiAudio.state, contexts: audioTest.contexts.map(context => context.state),
      activation: navigator.userActivation.hasBeenActive,
      starts: audioTest.starts.length
    })`));
    await waitFor(page, "digiAudio.state === 'suspended'");
    assert.equal(await read(page, 'navigator.userActivation.hasBeenActive'), false, 'The test accidentally activated the page');
    assert.equal(await read(page, "document.getElementById('enable-audio').hidden"), false,
      'Blocked audio has no way to enable sound before Play');
    const box = await read(page, "document.getElementById('enable-audio').getBoundingClientRect().toJSON()");
    const viewport = page.viewportSize();
    assert(box.height >= 44 && box.x >= 0 && box.x + box.width <= viewport.width && box.y + box.height <= viewport.height,
      'The sound control is too small or outside the screen');
    const screenshot = await sessions.get(page).send('Page.captureScreenshot', { format: 'png' });
    await fs.writeFile(path.join(directory, mobile ? 'mobile.png' : 'desktop.png'), Buffer.from(screenshot.data, 'base64'));
    if (mobile) await page.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2);
    else await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await waitFor(page, "digiAudio.state === 'running'");
    assert.equal(await read(page, "document.getElementById('enable-audio').hidden"), true,
      'The sound prompt did not leave after enabling audio');
    await waitFor(page, audible, 15000);
    const playing = await read(page, `({
      contexts: audioTest.contexts.length,
      canvasInputs: audioTest.canvasInputs
    })`);
    assert.equal(playing.contexts, 1, 'Audio recovery created a second engine audio context');
    assert.equal(playing.canvasInputs, 0, 'Enabling sound also sent an input to the game');

    // A later browser interruption uses the same global recovery in any scene.
    await read(page, 'audioTest.contexts[0].suspend()');
    await waitFor(page, "digiAudio.state === 'suspended'");
    if (mobile) await page.touchscreen.tap(20, 80);
    else await page.keyboard.press('Shift');
    await waitFor(page, "digiAudio.state === 'running'");
    await waitFor(page, audible);
    console.log(`PASS: blocked autoplay, ${mobile ? 'touch' : 'keyboard'}, menu stays open, interruption recovery`);
  } finally {
    await context.close();
  }
}

(async () => {
  await fs.mkdir(directory, { recursive: true });
  const common = {
    executablePath, headless: true,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--disable-features=PreloadMediaEngagementData,MediaEngagementBypassAutoplayPolicies']
  };
  const blocked = await chromium.launch({ ...common, args: [...common.args, '--autoplay-policy=document-user-activation-required'] });
  try {
    await checkBlocked(blocked, false);
    await checkBlocked(blocked, true);
  } finally {
    await blocked.close();
  }
  // An allowed browser must start sound without showing an unnecessary prompt.
  const allowed = await chromium.launch({ ...common, args: [...common.args, '--autoplay-policy=no-user-gesture-required'] });
  try {
    const page = await allowed.newPage({ viewport: { width: 1280, height: 720 } });
    await loaded(page);
    await waitFor(page, "digiAudio.state === 'running'");
    await waitFor(page, audible);
    assert.equal(await read(page, "document.getElementById('enable-audio').hidden"), true);
    assert.equal(await read(page, 'audioTest.contexts.length'), 1);
    assert.equal(await read(page, 'navigator.userActivation.hasBeenActive'), false);
    console.log('PASS: automatic audio on browsers that allow autoplay');
  } finally {
    await allowed.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
