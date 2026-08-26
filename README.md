# Instagram Reel Creation

Turn a single still image into a vertical (9:16), Reel-ready `.mp4` with a
blurred fill background (so nothing gets cropped) and a slow Ken Burns
zoom-in.

## Usage

```
scripts/make_instagram_reel.sh <input_image> <output.mp4> [duration_seconds]
```

Example:

```
scripts/make_instagram_reel.sh assets/sakura_neon_tokyo.jpg output/sakura_neon_tokyo_reel.mp4 12
```

Requires `ffmpeg` on `PATH`. Output is 1080x1920, 30fps, with a silent audio
track (add music/voiceover in Instagram after uploading, or overlay one with
ffmpeg's `-i music.mp3` before export).
