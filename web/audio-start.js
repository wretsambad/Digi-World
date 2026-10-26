/* Register before Godot creates its Web Audio context. Keep the same context
 * for every scene, and resume it directly inside trusted browser gestures. */
(() => {
  'use strict';

  const NativeContext = window.AudioContext || window.webkitAudioContext;
  const button = document.getElementById('enable-audio');
  const canvas = document.getElementById('canvas');
  const contexts = new Set();
  let ready = false;

  const update = () => {
    const blocked = [...contexts].some(context => context.state !== 'running' && context.state !== 'closed');
    const hadFocus = document.activeElement === button;
    button.hidden = !ready || !blocked;
    if (button.hidden && hadFocus) canvas.focus({ preventScroll: true });
  };

  const resume = () => {
    if (document.hidden) return;
    for (const context of contexts) {
      if (context.state === 'running' || context.state === 'closed') continue;
      // An earlier autoplay attempt can remain pending. Call resume again
      // synchronously on the gesture, rather than waiting on that promise.
      try {
        Promise.resolve(context.resume()).then(update, update);
      } catch (_) {
        update();
      }
    }
    update();
  };

  if (NativeContext) {
    // A constructor proxy preserves the native prototype and options. Godot
    // still owns creation, playback and disposal; no second context is made.
    window.AudioContext = new Proxy(NativeContext, {
      construct(target, args, newTarget) {
        const context = Reflect.construct(target, args, newTarget);
        contexts.add(context);
        context.addEventListener('statechange', () => {
          if (context.state === 'closed') contexts.delete(context);
          update();
        });
        resume();
        return context;
      }
    });
  }

  for (const event of ['pointerdown', 'pointerup', 'touchend', 'keydown']) {
    window.addEventListener(event, resume, { capture: true, passive: true });
  }
  document.addEventListener('visibilitychange', resume);
  window.addEventListener('focus', resume);
  window.addEventListener('pageshow', resume);
  // This control enables sound without passing a click or key into the game.
  for (const event of ['pointerdown', 'pointerup', 'keydown', 'keyup']) {
    button.addEventListener(event, input => input.stopPropagation());
  }
  button.addEventListener('click', event => {
    event.stopPropagation();
    resume();
  });

  window.digiAudio = {
    ready() {
      ready = true;
      resume();
    },
    resume,
    get state() {
      if (!NativeContext) return 'unavailable';
      if (!contexts.size) return 'initializing';
      return [...contexts].every(context => context.state === 'running') ? 'running' : 'suspended';
    }
  };
})();
