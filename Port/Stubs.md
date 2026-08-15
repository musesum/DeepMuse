# Port/Stubs.md — WinSky utility → DeepMuse destination API mapping

Destination = DeepMuse (`/Users/warren/Dev/Deep/Deep/Muse/`) + Mu packages
(`/Users/warren/Dev/Deep/Mu/*`). Source = WinSky CA rules/shapes/waves/fields.

Compute domain: cellular-automata rules run as Metal compute kernels inside a
ping-pong texture chain. State packs into RGBA of a `bgra8Unorm` texture
(`.b` = primary cell plane 0…255, `.g` = 255−value inverse, `(.a<<8)+.r` = HiC
high counter). Any ported rule reads neighbors from `.b` and writes the same
packing to interoperate with the color-map stage.

## Mapping table

| WinSky utility need | Destination API (exact) | Location |
|---|---|---|
| Per-cell value / neighbor read | `inTex.read(uint2)` → `.b` channel × 255/256 | kernel body; see `Metal/cell.rule.ave.metal:49-52` |
| Write next-gen cell | `outTex.write(half4/float4(fr,fg,fb,fa), gid)` | `Metal/cell.rule.fred.metal:113-114` |
| Rule variant selector (int/float knob) | `constant float& version [[buffer(0)]]` | every `cell.rule.*.metal`; bound in `Mu/MuVision/.../Pipeline/CellNode.swift:53-54` |
| Iteration count / sub-steps | `loops` flo buffer → CellNode ping-pong loop | `Mu/MuVision/.../Pipeline/CellNode.swift:59-66`; flo leaf `pipe.cell.rule.<name>.loops` |
| Grid dimensions | `outTex.get_width()` / `.get_height()` | `Metal/cell.rule.ave.metal:16-17` |
| Thread/pixel coordinate | `uint2 gid [[thread_position_in_grid]]` | all kernels |
| Time / frame counter | `CellNode.frame` (Int, unused sink) OR add `constant float& time [[buffer(n)]]` | `Mu/MuVision/.../Pipeline/CellNode.swift:17` |
| Random numbers | none built-in — hash `gid`+`version` in-kernel (e.g. `fract(sin(dot(...))*k)`) | GAP (see below) |
| Palette / color LUT | `pipe.color.pal` texture (256×1), applied downstream by `colorKernel` | flo `pipe.flo.h:31`; `Mu/MuVision/.../Pipeline/ColorNode.swift`, `Metal/pipe.color.metal` |
| False-color mapping | `sky.color.pal0/pal1/xfade` flo → ColorNode | `Resources/sky.flo.h:15-19` |
| Metal math (waves/fields) | `metal_stdlib`: `sin cos fract fmod fabs mix trunc pow` | `#include <metal_stdlib>` in every kernel |
| Camera texture input (fields) | `pipe.camera.out` texture, blended via `pipe.cell.real (<- (draw.out, camera.out))` | `Resources/pipe.flo.h:8-11,15` |
| Draw/brush input | `pipe.draw.out` → `pipe.cell.fake`/`real` | `Resources/pipe.flo.h:3-7,14-15` |
| Parameter UI (slider/segment) | flo leaf `seg`/`val`/`x A…B=default` + menu `<>` bind | `Resources/cell.flo.h:3-6` |

## Audio-reactive needs (waves/fields driven by sound)

| Need | Destination verdict |
|---|---|
| Audio amplitude / RMS level | **GAP.** MuAudio exposes no level tap. |
| FFT bins / spectrum | **GAP.** No FFT anywhere in MuAudio. |
| Beat / onset detection | **GAP.** None. |
| MIDI note/CC as modulation | **AVAILABLE.** MuAudio is MIDI-only: `MuMidi`, `TouchMidi`, `MidiItem` → routed into flo via `MidiFlo` (`Mu/MuAudio/Sources/MuAudio/`). CC/note values already land on flo leaves. |

MuAudio (`Mu/MuAudio/Sources/MuAudio/MuAudio.swift`) wraps AudioKit but only
instantiates `AudioEngine()` for a `testAudio()` oscillator; the 8 source files
are entirely MIDI. AudioKit *is* a linked dependency, so `AmplitudeTap` and
`FFTTap` (AudioKit) or a `vDSP`/Accelerate FFT can be added without a new package
dependency — but no tap, buffer, or spectrum surface exists today.

## Gaps (candidates for TODO shims)

1. **FFT / spectrum bins** — no destination equivalent. Shim: add `FFTTap` on
   `MuAudio.audioEngine` (AudioKit already linked) or a `vDSP_DFT` tap, publish
   N bins onto new flo leaves (e.g. `sky.audio.fft.bin0…binN`) so kernels read
   them via a `constant float* fft [[buffer(n)]]` uniform. Requires extending
   `CellNode.computeShader` to bind buffer index > 0.
2. **Audio level / RMS** — no equivalent. Shim: AudioKit `AmplitudeTap` →
   `sky.audio.level` flo leaf.
3. **Beat detection** — no equivalent. Shim: threshold/onset over the level or
   FFT flux; publish `sky.audio.beat` pulse leaf.
4. **RNG in kernel** — no Metal RNG primitive. Shim: coordinate hash of
   `gid`/`version`/`frame` (self-contained, no host state).
5. **Global time uniform** — `CellNode.frame` counter exists but is not bound to
   any buffer. Shim: bind `frame` (or a wall clock) to `buffer(1+)` and extend
   `CellNode.computeShader`. Only `version` (`buffer(0)`) reaches kernels today.
6. **Extra per-rule scalar** — `cell.rule.melt.metal` already declares
   `constant float& bits [[buffer(1)]]` but CellNode never binds buffer(1);
   melt therefore runs on an unbound uniform. Any new rule needing a 2nd scalar
   must extend `CellNode.computeShader` (currently binds buffer 0 only).
