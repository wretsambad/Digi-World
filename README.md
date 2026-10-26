# DigiWorld
An animated, 3D interactive game designed for children to educate them about digital security and being safe with their data online. 

Run in a browser with Godot 4.7.2 and its matching Web export templates installed:

```powershell
python tools/web.py build
python tools/web.py serve
```

Open http://127.0.0.1:8060/ in Chrome or Firefox. The server serves the release
build with gzip compression and the correct WebAssembly content type. Keep it
running while playing; Ctrl+C stops it. If Godot is not found automatically,
pass `--godot "C:/path/to/Godot_console.exe"` to the build command or set
`GODOT_BIN`.

The complete static site is in `build/web/`. For hosting, upload that folder
and configure gzip negotiation for the supplied `.gz` files (or enable the
host's compression). Serve `.wasm` as `application/wasm`. This is a
single-threaded Compatibility/WebGL 2 build; cross-origin isolation headers
are unnecessary. Use HTTPS on a public host.

The custom startup and lesson loading screen is in `web/loading.html`. It uses
the existing DigiWorld logo, Fredoka font and plum/orange palette. The build
script copies its logo and font beside the exported HTML. The computer's
camera/operator animation plays before the heavy lesson is created; the
loading screen covers setup at the end of that animation. The sharing-board
and phone entrances use the same loading screen after their animations.

See [browser performance notes](docs/browser-performance.md) for the rendering
changes, measurements and verification commands.
