# reel.

A random-movie picker for iOS 26, built in SwiftUI with Liquid Glass and a dark, cinematic look.

## What it does

**The rack**: every film is a real CD jewel case, standing in a row that runs corner to corner across the screen. The case in front slides out of the row toward you so you can see its whole cover: the full poster, plus a printed side panel with the title on its side. Drag anywhere along the rack (or flick it and let it coast) to move through the films. Tap any case to bring it out, and tap the one in front to open it. When the app opens, the cases sweep in on a ribbon, far end first.

**The backdrop**: the colours of the film in front fill the whole screen, edge to edge, with its poster blurred on top. When you move to another film, they blend into its colours.

**Tonight's pick**: each day the app picks one film and marks it with a "Tonight's pick" badge. **Pick for me** (or shaking the phone) spins the rack to a new random film, which becomes tonight's pick.

**The ruler**: under the rack, every film is a tick. Drag the ringed pin along it to scrub the rack. The ticks swell and brighten around the pin as it moves.

**Mood**: the slider button opens a Liquid Glass sheet of moods (Mind-bending, Dread, Cozy…). Choosing one dims the films that don't match, and Pick for me only lands on films that do.

**Your shelf**: the bookmark saves the film in front. The button at the top right opens your shelf; tap a film there to jump to it, or swipe to remove it.

**Detail**: opens with a zoom from the case and shows the TMDB backdrop, logline, director, cast and moods, plus **More like this**, which travels the rack to the most closely related film.

## Run it

With **Xcode 26** or later installed, run `./scripts/run.sh` from the repo folder: it builds the app and opens it in the iPhone 17 Pro simulator (pass another simulator name to use that one). Or open `Reel.xcodeproj`, pick an iPhone simulator or a device, and press Run. It has no dependencies and needs no API keys. Posters ship in the app; backdrops on the detail page load from TMDB's image CDN. For a physical device, choose your team under *Signing & Capabilities*.

## How it's built

| Area | Where |
| --- | --- |
| Film list (88 films, with TMDB poster and backdrop paths) | `Reel/Resources/movies.json` |
| Bundled posters | `Reel/Resources/Posters/` |
| Jewel-case photo split into base, shade and glare layers | `Reel/Resources/Case/` |
| Printing each cover and compositing it into the case (Core Graphics, off the main thread) | `Reel/Design/CaseArt.swift`, `Reel/Design/CaseShelf.swift` |
| Rack physics: drag, coast, springs, spins, the entrance | `Reel/Motion/RackMotion.swift` |
| Where each case sits, the slide-out and the ribbon entrance | `Reel/Features/Rack/RackGeometry.swift` |
| Ruler, title card and the glass controls | `Reel/Features/Rack/` |
| How films are linked for More like this | `Reel/Model/Relations.swift` |

- The rack's motion is calculated in code on every frame instead of with SwiftUI animations, so the app always knows which case is in front. That's what makes the haptic ticks and the pick landing possible. It runs at up to 120 Hz on ProMotion screens.
- Posters and stills come from TMDB. This app is not endorsed or certified by TMDB.

### Debug launch arguments

These are used by CI to set up screenshots. Add them in *Scheme → Run → Arguments*:

`-ReelPick <film-id>` · `-ReelGoTo <film-id>` · `-ReelOpenDetail <film-id>` · `-ReelSheet mood|shelf` · `-ReelMood dread` · `-ReelAutoPick YES` · `-ReelSkipIntro YES` · `-ReelSeedShelf YES` · `-ReelPoseIntro 1.0`

## CI

`.github/workflows/ios.yml` builds the app on a macOS 26 runner and uploads screenshots of each screen, plus a screen recording of a pick, as an artifact.
