# FonkPlay 🎵

A web-based MOD/S3M tracker module player with DOS-era CRT aesthetics and modern audio features.

## Features

- **MOD & S3M support** - Play classic tracker modules from the Amiga and PC demoscene era
- **32-channel playback** - Full support for multi-channel S3M files
- **Real-time waveform display** - Oscilloscope visualization for each channel
- **Three interpolation modes:**
  - Sound Blaster (none) - Authentic crunchy 90s sound
  - Gravis Ultrasound (linear) - Smooth classic sound
  - Modern (8-point sinc) - High-quality interpolation
- **Surround sound modes:**
  - Stereo - Standard output
  - Pro Logic Surround - Dolby Pro Logic matrix encoding for home theater
  - Headphone HRTF - Binaural 3D audio with proper HRTF convolution
- **Automatic sample classification** - AI-powered detection of bass, drums, leads, pads for surround placement
- **WAV export** - Render modules to WAV with selectable quality
- **Timeline scrubbing** - Jump to any position in the song
- **Channel solo** - Click any channel to solo it

## Technical Highlights

- **AudioWorklet** with ScriptProcessorNode fallback
- **S-curve (smoothstep) volume ramping** for click-free transitions
- **Sample-rate vibrato** with integrated sine anti-aliasing
- **64-tap HRTF convolution** based on KEMAR measurements
- **21-tap Hilbert transform** for Pro Logic surround encoding
- **Zero dependencies** - Single HTML file, no build step

## Usage

1. Open [FonkPlay](https://aghiles.github.io/fonkplay)
2. Drag & drop a `.mod` or `.s3m` file (or click to browse)
3. Enjoy!

## Tips

- **Click channel** - Solo (click again to unsolo)
- **Drag timeline** - Scrub to any position

## About the Surround Modes

### Pro Logic Surround
Uses Hilbert transform to create 90° phase-shifted surround channel, compatible with any Dolby Pro Logic decoder. Bass stays center, leads up front, pads and textures in the rear.

### Headphone HRTF
Proper binaural processing using 64-tap head-related impulse responses. Creates convincing "behind you" perception for surround content through regular headphones.

## Sample Classification

Each sample is automatically analyzed using:
- **Audio analysis**: Zero-crossing rate, attack time, sustain level, noise content
- **Pattern analysis**: Beat alignment, note variety, trigger frequency

This determines optimal surround placement:
| Type | Detection | Placement |
|------|-----------|-----------|
| Bass | Low frequency | Center |
| Drums | Fast attack + beat-aligned | Front |
| Lead | Melodic content | Front |
| Pad | Slow attack + sustained | Rear |
| Texture | Noisy + looped | Surround |

## License

MIT License - See [LICENSE](LICENSE) file

## Credits

- **Psyke/DCB** & **VIP/DCB** - Original ASM player code
- Built with ❤️ and Claude
