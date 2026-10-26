# DigiWorld scene audio

Seven original instrumental tracks, rendered by `tools/compose_soundtracks.py`
from `tools/soundtrack_scores.py`. No downloaded samples or vocals are used.

| File | Title | Setting | Feel |
| --- | --- | --- | --- |
| neighborhood.ogg | Hello, DigiWorld | Main menu / neighborhood | Sunny major-key guitar, electric keys and a pop chorus, 112 BPM |
| bedroom.ogg | After School | Teen bedroom | Cheerful guitar and wooden keys, a gentle beat and a lively middle, 104 BPM |
| treehouse.ogg | Branch by Branch | Protect Your Base | Familiar wooden theme expanding into a guitar/percussion chorus, 106 BPM |
| winter.ogg | Snowflakes and Secrets | Both Sharing Board rounds | Playful winter tune, bell accents and a string-backed chorus, 112 BPM |
| phone.ogg | Think Before You Tap | Phone investigation | Curious upbeat plucks and keys from the start, 114 BPM |
| party.ogg | Park Party | Restored speakers | Synth brass, bass fills and claps, 124 BPM |
| snowman_party.ogg | Snowman Shuffle | Alternate song choice | Wooden melody, bells and a bouncing party beat, 120 BPM |

Each track is 32 bars (62–74 seconds): a four-bar introduction, twelve-bar
theme, eight-bar energetic lift, four-bar break, and four-bar return. The
renderer checks decoded peaks, loop continuity and at least 3 dB of energy
contrast between lift and break. Timings and measured section levels are in
`tracks.json`. Notes and reflection tails wrap across the loop boundary.

Files are compact 44.1 kHz stereo Ogg Vorbis. Desktop and Web play the same
rendered assets without runtime music synthesis. The Web builder follows
their literal resource references.

`AudioManager.claim_music(owner, track, priority)` crossfades scene backgrounds
over 0.85 seconds. Leaving an owner restores the previous track. The embedded
computer releases its track when returning to the bedroom. The phone score
plays while its speakers are off; active party speakers take over, and
switching them off restores the investigation score. Both song choices use
full arrangements. Starting speakers while muted starts their timeline too,
so unmuting resumes audibly. The finale retains its separate score.

The three games have feedback for correct answers, mistakes and major events:
building and repairing the treehouse, stitching and checking cards, finding
and covering photo clues, posting, phone notifications, rewinds and completion.
Short typing taps follow actual newly revealed letters in game dialogue and
captions. They stop on completion, skip, cancel, hiding and pause; delayed text,
whitespace, bedroom prompts and button captions stay quiet. Existing sound,
volume and pause controls apply to all audio.

Settings also has a separate Music switch. It mutes the shared Music bus,
including party speakers and finale music, while leaving effects and typing
audible. It preserves playback positions and the independent master Sound
setting. In browsers, autoplay is attempted as soon as the engine initializes;
if browser policy blocks it, the home screen offers Turn sound on and any
click, tap or key can unlock audio without starting the game.

To regenerate, install NumPy and put FFmpeg on PATH, then run:

```powershell
python tools/compose_soundtracks.py
```

WAV masters and an MP3 sampler (introduction then energetic lift for each track)
are saved in ignored `work/music/`. The game uses only the small `.ogg` files.

Run the music lifecycle check with Godot:

```powershell
godot --headless --path . --script res://tests/music_flow.gd
godot --headless --path . --script res://tests/audio_feedback.gd
```
