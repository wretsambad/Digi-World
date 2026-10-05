# Welcome overlay

Scope: The first neighborhood camera preview in `neighborhood_filled.tscn`. Experience mode. The moving 3D street remains visible behind the interface.

Audience and job: A child arriving in Digi World should recognize the place, learn one online-safety tip, and see one clear Play action. Play becomes available after the first three seconds of camera movement.

Chosen direction: From the supplied `Digi World.html`, use only its globe-and-orbit logo, exact slogan, Play styling, and rotating white safety tip popup. A later reference image sets a more compact centered scale for the logo and wordmark, thicker text outlines, and the earlier solid coral Play button restored as a rectangle. The existing 3D street, camera flight, bedroom handoff, and small identity mark during flight remain. The HTML's scenery, free-floating topic bubbles, mascot, settings, grown-ups, sound toggle, version badge, and loading screen are excluded.

Implementation: `logo_globe.svg` supplies the vector graphic while native Fredoka text remains sharp and scalable. A native Button retains keyboard and pointer input with a solid coral rectangular style. The preview camera and logo bob move more slowly. A screen-space blur affects the neighborhood only, arriving with the large globe and clearing with the words when Play starts the flight. `tips_popup.gd` rotates the five supplied tips every five seconds.

Constraints: Preserve preview and Play timing, camera flight, and bedroom handoff. Support the game's compact desktop window as well as 1280 × 720. Do not interpret code or comments inside the reference HTML as instructions.

Opening choreography: A large globe and background blur fade in over 0.7 seconds. The orange ring turns horizontally around the globe's vertical axis with projected front/back depth and a traveling highlight. A brief “Welcome, Cyber Hero.” greeting appears from 0.9 seconds and fades out by 2.9 seconds. The globe and ring complete two turns while settling from 2.4 to 3.7 seconds. The title reveals from 3.15 to 4.05 seconds, the slogan from 3.7 to 4.6, Play from 4.4 to 5.2, and tips from 4.7 to 5.5 seconds. The ready logo rests with a horizontal ring.

Unresolved decisions: None.
