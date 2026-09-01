# AppleCharge80

SwiftUI prototype for a flat 1980s-style rainbow Apple charging animation.

## Animation sequence

1. A thin outline is drawn for 1 second.
2. The outline fades away.
3. The logo fills from bottom to top, one color band at a time.
4. Each active fill boundary has a large, smooth, irregular liquid wave.
5. Small flat leaves, flowers and twigs rise from below and are absorbed into the lower part of the logo.
6. At about 78%, the leaf begins growing from its stem.
7. The leaf morphs into its final shape by 100%.
8. From 75% to 100%, the particle stream gradually weakens and stops.
9. At 100%, the logo remains flat and clean.

## Testing

Tap **Подключить зарядку** to run the complete demo.

The slider lets you inspect any charge level manually.

## Notes

The first prototype uses a visual 30 mm approximation. iOS points are not a guaranteed physical millimetre measurement across displays, so exact physical calibration should be added if a strict 30 mm physical size is required.

The animation is currently a simulation. It does not yet control the iPhone's system charging UI.
