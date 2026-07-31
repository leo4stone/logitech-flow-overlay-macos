# Artwork source rules

`AppIconSource.png` is the full-bleed square source for the macOS app icon.
The source image must:

- extend its background to every canvas edge;
- contain no outer border, frame, bezel, or inset tile;
- contain no precomposed rounded corners or transparent corner padding;
- contain no text or third-party logos.

macOS controls the final icon presentation. Do not draw the operating system's
icon mask into the source artwork.

`DMGBackgroundBase.png` contains background artwork only. Exact installation
text and the drag direction are rendered by `scripts/render_dmg_background.swift`.
