from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[2]
frames = [Image.open(p).convert('RGB') for p in sorted((root / '.impeccable/review/animation-frames').glob('*.png'))]
assert len(frames) == 160
output = root / 'character_assets/preview/character-animations.gif'
frames[0].save(output, save_all=True, append_images=frames[1:], duration=50, loop=0, optimize=True, disposal=2)
with Image.open(output) as result:
    assert result.n_frames == 160
    assert result.size == (800, 720)
print(f'Saved {output.name}: 160 frames, 8 seconds, {output.stat().st_size:,} bytes')
