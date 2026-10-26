"""Build and serve DigiWorld's single-threaded Web export (standard library only)."""

import argparse
import functools
import gzip
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "web"
ENTRY_SCENES = [
    "neighborhood_assets/preview/neighborhood_filled.tscn",
    "bedroom_assets/teen_bedroom.tscn",
    "scenes/monitor_game/monitor_game.tscn",
    "lessons/phone/phone_lesson.tscn",
    "lessons/sharing_board/round1.tscn",
    "lessons/sharing_board/round2.tscn",
]


def godot_path(explicit):
    candidates = [explicit, os.environ.get("GODOT_BIN"), shutil.which("godot"), shutil.which("godot4")]
    candidates += sorted((Path.home() / "Downloads").glob("Godot*_console.exe"), reverse=True)
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(Path(candidate).resolve())
    raise SystemExit("Pass --godot /path/to/godot, or set GODOT_BIN to Godot 4.7.2.")


def build(args):
    executable = godot_path(args.godot)
    env = os.environ.copy()
    # Keep editor metadata, user data and scratch files within this checkout.
    runtime = ROOT / "work" / "web-user"
    temporary = ROOT / "work" / "web-temp"
    runtime.mkdir(parents=True, exist_ok=True)
    temporary.mkdir(parents=True, exist_ok=True)
    if os.name == "nt":
        installed = Path(os.environ.get("APPDATA", "")) / "Godot" / "export_templates"
        env["APPDATA"] = env["LOCALAPPDATA"] = str(runtime)
        destination = runtime / "Godot" / "export_templates"
        if installed.is_dir() and installed.resolve() != destination.resolve():
            for template in installed.glob("*/web_nothreads*.zip"):
                target = destination / template.relative_to(installed)
                target.parent.mkdir(parents=True, exist_ok=True)
                if not target.exists() or target.stat().st_size != template.stat().st_size:
                    shutil.copy2(template, target)
    env["TMP"] = env["TEMP"] = env["TMPDIR"] = str(temporary)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "neighborhood_assets/preview/logo_globe.svg", OUTPUT / "loading-brand.svg")
    shutil.copy2(ROOT / "neighborhood_assets/preview/fonts/Fredoka.ttf", OUTPUT / "Fredoka.ttf")
    shutil.copy2(ROOT / "web/audio-start.js", OUTPUT / "audio-start.js")
    # Exported scripts can load other scripts by name, including global classes.
    # Include the runtime code explicitly; editor dependency caches are incomplete
    # for these references when only selected scenes are exported.
    preset = ROOT / "export_presets.cfg"
    config = preset.read_text(encoding="utf-8")
    selected = {"res://" + path for path in ENTRY_SCENES}
    selected.update("res://" + path.relative_to(ROOT).as_posix() for path in (ROOT / "audio" / "finale").glob("*.wav"))
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    autoloads = project.split("[autoload]", 1)[1].split("[", 1)[0]
    selected.update(re.findall(r'"\*(res://[^"\n]+)"', autoloads))
    for directory, folders, files in os.walk(ROOT):
        folders[:] = [folder for folder in folders if folder not in {".git", ".godot", "work", "build", "dist", "tests", "tools", "source", "addons"}]
        for name in files:
            if not name.endswith(".gd"):
                continue
            path = Path(directory) / name
            if re.search(r"^class_name\s", path.read_text(encoding="utf-8"), re.MULTILINE):
                selected.add("res://" + path.relative_to(ROOT).as_posix())
    # Follow literal preload/load/scene resource references too. GDScript resource
    # dependencies are not all reported by Godot's selected-resource exporter.
    pending = list(selected)
    while pending:
        resource = pending.pop()
        path = ROOT / resource.removeprefix("res://")
        if path.suffix not in {".gd", ".tscn", ".tres", ".gdshader"}:
            continue
        for reference in re.findall(r'''["'](res://[^"'\n]+)["']''', path.read_text(encoding="utf-8")):
            target = ROOT / reference.removeprefix("res://")
            if target.is_file() and reference not in selected:
                selected.add(reference)
                pending.append(reference)
    config = re.sub(r'export_filter="[^"]+"', 'export_filter="resources"', config, count=1)
    config = re.sub(r"export_files=PackedStringArray\(.*?\)", "export_files=PackedStringArray(" + ", ".join(json.dumps(path) for path in sorted(selected)) + ")", config, count=1)
    preset.write_text(config, encoding="utf-8", newline="\n")
    log = ROOT / "work" / "web-build.log"
    with log.open("w", encoding="utf-8") as stream:
        result = subprocess.run([executable, "--headless", "--path", str(ROOT), "--export-release", "Web", str(OUTPUT / "index.html")], env=env, stdout=stream, stderr=subprocess.STDOUT)
    errors = [line for line in log.read_text(encoding="utf-8", errors="replace").splitlines() if line.startswith(("ERROR:", "SCRIPT ERROR:"))]
    if result.returncode or errors:
        print(log.read_text(encoding="utf-8", errors="replace")[-6000:])
        raise SystemExit(f"Export failed; see {log}")
    sizes = {}
    for path in OUTPUT.iterdir():
        if path.suffix in {".wasm", ".pck", ".js", ".html", ".svg", ".ttf"}:
            compressed = gzip.compress(path.read_bytes(), compresslevel=9, mtime=0)
            path.with_name(path.name + ".gz").write_bytes(compressed)
            sizes[path.name] = {"bytes": path.stat().st_size, "gzip_bytes": len(compressed)}
    (OUTPUT / "sizes.json").write_text(json.dumps(sizes, indent=2) + "\n", encoding="utf-8")
    print(f"Built {OUTPUT / 'index.html'}")
    print(f"Payload: {sum(item['bytes'] for item in sizes.values()) / 1048576:.2f} MiB raw, {sum(item['gzip_bytes'] for item in sizes.values()) / 1048576:.2f} MiB with gzip")
    print("Run: python tools/web.py serve")


class WebHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".pck": "application/octet-stream", ".js": "text/javascript"}

    def send_head(self):
        path = Path(self.translate_path(self.path))
        if path.is_dir():
            path = path / "index.html"
        compressed = path.with_name(path.name + ".gz")
        if path.is_file() and compressed.is_file() and "gzip" in self.headers.get("Accept-Encoding", ""):
            stat = compressed.stat()
            etag = f'"{stat.st_mtime_ns:x}-{stat.st_size:x}"'
            if self.headers.get("If-None-Match") == etag:
                self.send_response(304)
                self.send_header("ETag", etag)
                self.send_header("Vary", "Accept-Encoding")
                self.end_headers()
                return None
            self.send_response(200)
            self.send_header("ETag", etag)
            self.send_header("Content-Type", self.guess_type(str(path)))
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(compressed.stat().st_size))
            self.send_header("Vary", "Accept-Encoding")
            self.end_headers()
            return compressed.open("rb")
        return super().send_head()

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def serve(args):
    directory = Path(args.directory).resolve() if args.directory else OUTPUT
    if not (directory / "index.html").is_file():
        raise SystemExit("Build first: python tools/web.py build")
    handler = functools.partial(WebHandler, directory=str(directory))
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(f"DigiWorld running at http://127.0.0.1:{args.port}/", flush=True)
    server.serve_forever()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    builder = commands.add_parser("build", help="Export a release build and precompress downloads")
    builder.add_argument("--godot")
    builder.set_defaults(run=build)
    server = commands.add_parser("serve", help="Serve locally with gzip and WebAssembly MIME types")
    server.add_argument("--port", type=int, default=8060)
    server.add_argument("--directory")
    server.set_defaults(run=serve)
    args = parser.parse_args()
    args.run(args)


if __name__ == "__main__":
    main()
