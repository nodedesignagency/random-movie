# reel.

A random-movie picker for iOS 26, built in SwiftUI with Liquid Glass and a dark, cinematic look.

## The three tabs

**Reel**: posters sit on a 3D drum, a bit like a Rolodex. The card in front faces you and the rest fold back into thin slivers above and below. You can drag it with your finger, flick it and let it coast, or tap a sliver to bring that card forward. Each card that passes gives a haptic tick. Tap the **dice**, or shake the phone, and the reel spins like a slot machine. It slows down and lands on a random film, and the light behind it flares.

**Filters**: the slider button turns into a Liquid Glass panel. It has a mood dial (Mind-bending, Dread, Cozy…), an era ruler from 1950 to today with two draggable handles, and a length picker. The reel updates while you adjust them.

**Orbit**: the "rabbit hole". One film sits in the centre and related films circle it. Each one says why it's related: same director, a shared actor, a shared mood. Tap a film and it moves to the centre while a new set of related films appears around it. Breadcrumbs at the top show the path you took.

**Stubs**: films you save are printed as glass ticket stubs. Tap the stub end to tear it off and stamp the film "watched".

## Run it

Open `Reel.xcodeproj` in **Xcode 26** or later, pick an iPhone simulator or a device, and press Run. It has no dependencies and needs no API keys. For a physical device, choose your team under *Signing & Capabilities*.

## How it's built

| Area | Where |
| --- | --- |
| Film list (88 films, chosen so directors and actors overlap) | `Reel/Resources/movies.json` |
| Generated posters, one of 18 motifs per film, using typefaces that ship with iOS | `Reel/Design/PosterArtist.swift` |
| Reel motion: display-link spring, flick momentum, slot-machine spin | `Reel/Motion/ReelScroller.swift` |
| Card fold, depth and slivers | `Reel/Features/Reel/CardTransform.swift` |
| How films are linked for Orbit | `Reel/Model/Relations.swift` |

- The posters are not real posters. Each film gets a minimal "alternative poster" drawn in code from its own colours, motif and typeface, so the app needs no licensed artwork. To use real posters, swap `PosterArt` for an image loader (TMDB, for example).
- The reel's motion is calculated in code on every frame instead of using SwiftUI animations. That way the app always knows which card is under the centre line, which is what makes the ticks and the slot-machine landing possible. It runs at up to 120 Hz on ProMotion screens.

### Debug launch arguments

These are used by CI to set up screenshots. Add them in *Scheme → Run → Arguments*:

`-ReelStartTab orbit|stubs` · `-ReelShowFilters YES` · `-ReelOpenDetail <film-id>` · `-ReelOrbitPath id1,id2` · `-ReelSeedStubs YES` · `-ReelAutoSpin YES`

## CI

`.github/workflows/ios.yml` builds the app on a macOS 26 runner and uploads screenshots of each screen, plus a screen recording of a spin, as an artifact.
