# WinSky Waves and Fields -- Call Tree, Inputs, Selection Mechanism, Catalog

Source tree analyzed: `/Users/warren/Dev/WinSky/WinSky/pixel/` (canonical). The
sibling directories `~sky` and `~vc project` were excluded per instructions;
where those directories duplicated a file, only the `pixel/` copy was read.
This document is the companion reference to the macro expansions in
`Port/Expanded/*.expanded.cpp`. All file:line citations below were verified
by direct grep/read of the WinSky tree (read-only; no WinSky files were
modified).

---

## 1. Wave call chain

### 1.1 Ownership and top-level dispatch

- `WaveShapes waves;` is a member of `Main` (`main/Main.h:78`) -- the field is
  named `waves`, not `waveShapes`.
- `Main::init()` calls `waves.init()` once at startup (`main/Main.cpp:391`).
  `WaveShapes::init()` (`pixel/Waveshapes.cpp:295-305`) hardwires
  `algo.set(1)` (always starts on wave-shape index 1), computes
  `startime`/`endtime` from `skyClock`, and sets `wavePhase = WavePhaseFirst`.
- `Main::go()` (the per-frame tick, `main/Main.cpp:426-500`) calls `waves.go()`
  **once per rendered frame**, near the end of the frame after
  `draw.go()` and before `capture.go()`/`pic.go()`:

  ```
  Main::go() frame order (main/Main.cpp:426-500):
    pen.go() -> waveSky.go() [audio capture + FFT, this frame's audio data]
      -> skyClock.go() -> spec0/spec1.go() -> connect.go() -> exec.go()
      -> midiSky.go() -> seq1/seq2.go() -> tree.go() -> budCaches.go()
      -> dboxLo/Hi.go() -> dplayLo/Hi.go() -> adsr.go()
      -> beat1..8.go() -> lfo1..8.go()
      -> draw.go()        [rasterizes points/polys QUEUED by LAST frame's waves.go()]
      -> waves.go()       [<-- wave shapes evaluated HERE, once per frame]
      -> capture.go(pic.facemap, waveSky.bufs)
      -> pic.go()         [-> field.go() / field.goRgb(), see section 2]
  ```

  Because `draw.go()` runs *before* `waves.go()` in the same iteration, the
  dot/poly leaves that `waves.go()` writes this frame are not rasterized
  until `draw.go()` runs again next frame -- a one-frame pipeline latency
  between "wave math evaluated" and "pixels actually written".

### 1.2 Per-shape dispatch (`WaveShapes::go()` / `goPhase()`)

`WaveShapes::go()` (`pixel/Waveshapes.cpp:307-347`), called once per frame:

1. Builds a `User` struct from the `userX/Y/R/A` slider leaves (this frame's
   `ux,uy,ur,ua`).
2. If the selected shape (`algo.v()`) changed since last frame, OR the
   previous shape's timer expired (`t > endtime`) -- advance `algo`,
   reset `startime/endtime`, and call `goPhase(WavePhaseFirst, ...)` (runs
   **setup once**, selecting fresh random constants for every instance).
3. Every frame, unconditionally: `goPhase(WavePhaseFrame, ...)` then
   `goPhase(WavePhaseLoop, ...)`.

`goPhase()` (`pixel/Waveshapes.cpp:250-262`) is a `switch(algo.v())` generated
by re-including `WaveShort.sky`/`PartiShort.sky` with
`#define Wave(P,Q,R,S,N) case WaveShapeType_##P: ws_##P.go(phase,polyDot,user,title); break;`
-- i.e. exactly one `WS_<Name>` instance's `go(phase,...)` runs per frame,
selected by `algo`. `WaveShape::go()` (`pixel/Waveshapes.cpp:55-63`) routes
the phase to `setup()`/`frame()`/`pixel()`, which are the three
macro-expanded method bodies documented in section 3.

`WS_<Name>::pixel()` is the body captured in `Port/Expanded/*.expanded.cpp`.
It is **per-instance, per-step** (not per-scanline, not per-display-pixel):
a nested loop `for id in [0,num)` x `for sint in [0,steps]` runs the
C()/X()/Y()/XY() math and calls `draw()`, which writes normalized (-1..1)
coordinates into the `polyDot` tree leaves -- it does not touch a
framebuffer directly and has no notion of screen resolution.

### 1.3 From tree leaves to actual pixels

`WaveShape::draw()` (`pixel/Waveshapes.cpp:76-110`) sets `BudInt` leaves
bound to tree paths set in the `WaveShapes` constructor
(`pixel/Waveshapes.cpp:267-293`), e.g. `polyDot.dotX.path =
"WaveshapeDrawDotX"`. Those paths are wired via tree-connect arrows
(`tree_demo.sky:2296-2328`) to `draw.shape.dot`/`draw.shape.poly` tree nodes,
whose native paths match the `Draw` class's own leaves
(`pixel/Draw.cpp:26-54`, e.g. `"DrawShapeDotX"`). The actual pixel writes
happen in `Draw::update(DrawNewType)` (`pixel/Draw.cpp:61-121`):
- `DrawNewDot` -> `Draw::circle()` (`Draw.cpp:160-176`) -> `univ.uxy(x,y) = val`
- `DrawNewPoly` -> `Draw::poly()` queues points, drained by `Draw::go()`
  (`Draw.cpp:132-158`) via `Draw::line()` -> `univ.uxy(x,y) = val`

`Draw::go()` runs once per frame (`main/Main.cpp:496`, immediately before
`waves.go()` -- see 1.1). So the true "per-pixel" write for wave shapes
happens inside `Draw::circle()`/`Draw::line()`, which is itself only called
once per frame (it drains whatever points were queued), never per-scanline.

**Summary: wave shapes are evaluated once per frame, per-instance,
per-step (not per-scanline, not per-display-pixel); their output is a
normalized point/line list consumed by a separate once-per-frame
rasterizer.**

---

## 2. Field call chain

### 2.1 Ownership and top-level dispatch

- `Field field;` is a member of `Pic` (`pic/Pic.h:52`, comment: "delta field
  for post mixing alpha blending"), i.e. `main.pic.field` -- **not** a
  member of `Main` directly (unlike `waves`).
- `Pic::init()` (`pic/Pic.cpp:58`) and `Pic::newPicSize()` (`Pic.cpp:240`,
  the resize path) call `field.init(fxs, fys, 1, facemap.univSurfs)`, which
  allocates the `fxy[]`/`frt[]`/`rt[]` per-pixel lookup tables sized to the
  current grid and calls `calcMap(); calcViz(); calcFade(); calcRT();`.
- Every frame, `Pic::go()` -> `Pic::goRule()` (`pic/Pic.cpp:443-459`) calls:
  - `Pic::goFake()` -> **`field.go()`** (`Pic.cpp:392`, comment "warped
    feedback") -> `facemap.goTile(field.fix, facemap.tileFake)`
  - `Pic::goReal()` -> **`field.goRgb()`** (`Pic.cpp:433`): if a
    false-color viz mode is active, it *replaces* the normal camera/draw
    "real" display path with `field.rtmap` (the delta-angle/delta-radius
    color visualization from `Field::calcViz()`) instead of
    `goRealStrip()`.
  - `field.goRgb()` is also checked again to choose which tile
    (`tileFake` vs `tileField`) feeds `win.go(...)` (`Pic.cpp:456-458`).

### 2.2 The critical architectural fact: the warp table is static between selections

`Field::go()` (`pixel/Field.cpp:317-361`) is the only per-frame call, and it
is deliberately cheap:

```cpp
if (oldFader != fader.v())  calcFade();   // only on fader change
if (oldAlgo  != algo.v())   calcMap();    // only on algo (field) change
if (oldViz   != viz.v())    calcViz();    // only on viz-mode change
for (... every (x,y) on the xs*ys grid ...)   // ALWAYS runs, every frame
    blend fade[buf[prev][fxyi]] with the new incoming pixel -> buf[next]
```

`calcMap()` (`Field.cpp:239-263`) is where the *entire* macro-expanded
Test()/Go*() math from `fieldShort.sky.h`/`field_dir/rt/xy.sky.h` actually
executes -- and it only runs **once, when the selected field index
(`algo`) changes**, not every frame. It walks the whole xs*ys grid one time
and bakes the result into the static `fxy[]` (Cartesian source-pixel index)
and `frt[]` (source radius/theta) tables. Every subsequent frame,
`Field::go()` does a pure table lookup + `fade[]`-weighted blend of the
*previous rendered frame's* buffer through that fixed table.

**Consequence for porting:** any `rnd()` call inside a field body (many of
them have one -- see `Port/Expanded/fieldShort.expanded.cpp` /
`field_variants.expanded.cpp`) produces a spatial jitter pattern that is
generated **once per field selection** and then held static (spatially)
for as long as that field stays selected -- it is *not* fresh per-pixel
noise every frame. What *looks* like continuous animation/evolution comes
entirely from the accumulated feedback: the same static warp re-applied to
a buffer that itself keeps changing frame over frame (because the
previous frame's *output* becomes this frame's *input*), not from
re-evaluating the field math per frame. This is the single most important
behavioral difference from wave shapes (which recompute `a[]`/`b[]` every
frame from live `t`) and is worth flagging explicitly to whoever ports
this: a naive port that re-evaluates the field expression every frame
(including its `rnd()` calls) will look meaningfully different --
"boiling"/noisy instead of a stable spinning/zooming warp.

### 2.3 Selection dispatch mechanism (detail in section 4)

`calcMap()`'s body is wrapped `if(0){ #include "fieldShort.sky" ... }`; the
`Test(...)` macro is defined as
`#define Test(A,B,C,D) calcViz(); return;} if (test++==oldAlgo) { title.set(#A);`
so the whole included file macro-expands into a flat chain of
`if (test++ == oldAlgo) { ...; calcViz(); return; }` blocks -- see section 4.

### 2.4 No scanline-level invocation anywhere

Both wave and field call sites were checked for any loop that invokes
`waves.go()`/`goPhase()`/`field.go()`/`calcMap()`/`calcViz()`/`calcRT()`
once per horizontal scanline rather than once per frame; none exists.
`Field::calcMap()`/`calcViz()`/`calcRT()` each internally contain a
`for (yy...) for (xx...)` loop over the whole grid, but those loops run
*inside* a function that itself only executes once per algo/viz change (or
once at init), not once per scanline of a raster callback.

---

## 3. The macro DSL: how a `Wave()`/`Test()` block becomes 3-7 C++ passes

`pixel/Waveshapes.cpp` (`WinSky/pixel/Waveshapes.cpp:120-262`) `#include`s
`WaveShort.sky`/`PartiShort.sky` **seven times**, redefining `Wave`, `Draw`,
`A`, `B`, `C`, `X`, `Y`, `XY`, `Steps`/`Stps`, `Aspect`/`Aspc` differently
each time (classic X-macro / multi-pass code generation):

| Pass | `Wave(P,...)` expands to | `A`/`B`/`C`/`X`/`Y`/`XY` | Purpose |
|---|---|---|---|
| 1 | `class WS_##P : public WaveShape { ... };` | no-ops | class declarations |
| 2 | `WS_##P ws_##P;` | no-ops | instance declarations |
| 3 | `void WS_##P::setup(...) { init(N); ForId { ... } }` | only `A` active | one-time-per-instance setup (`a[]`), plus `Steps()`/`Aspect()` |
| 4 | `void WS_##P::frame(User&) { ForId { ... } }` | only `B` active | once-per-frame-per-instance (`b[]`); `ux/uy/ur/ua` in scope |
| 5 | `void WS_##P::pixel(...) { ForId { ForSteps { ... } } }` | `C`/`X`/`Y`/`XY` active, `Draw` -> `draw(...)` call | per-instance, per-step (`c[]`, final `x[]`/`y[]`), `ux/uy/ur/ua` still in scope |
| 6 | `WaveShapeType_##P,` | no-ops | builds the `WaveShapeType` enum |
| 7 | `case WaveShapeType_##P: ws_##P.go(phase,...); break;` | no-ops | `goPhase()` dispatch switch |

`Port/Expanded/*.expanded.cpp` collapses passes 3-5 into **one** function per
wave shape (clearly commented `setup` / `frame` / `pixel` sections) because
that is far more readable while remaining a faithful, order-preserving
transcription -- see the "codegen correctness" note in section 6.

`pixel/Field.cpp::calcMap()` uses the same X-macro idea but with a single
pass and a different mechanism: instead of a `switch`, `Test(...)` closes
the previous `if` block and opens the next (see section 2.3/4), and the
per-pixel loop (`ForXY`) is embedded directly in the `Go*()` macros rather
than split into separate setup/frame/pixel passes -- fields have no
per-frame recompute step at all (section 2.2).

---

## 4. Waveform / field selection mechanism

### Waves

`algo` (`BudInt`, tree leaf `"ScreenWaveshapeAlgo"`) selects the active
shape. `WaveShapes::init()` hardwires `algo.set(1)`. `WaveShapes::go()`
auto-advances `algo.increase()` whenever the current shape's timer expires
(`endtime`, default `startime+1200`s, or `Duration(expr)` if the shape sets
one) **or** something else changed `algo` externally (e.g. UI). Dispatch
from `algo.v()` (an int, one per `Wave(...)` block in file order) to the
actual `WS_<Name>::go()` call is a plain `switch` statement generated by
pass 7 above (`pixel/Waveshapes.cpp:250-262`) -- an O(1) jump table, not a
sequential search. **Only `waveshort.sky.h` + `PartiShort.sky.h` are
actually wired into this switch** (see `#include` list at
`Waveshapes.cpp:138-139` etc.) -- 47 + 21 = 68 total selectable shapes at
runtime. `WaveShapes.sky.h` (192 shapes), `Particles.sky.h` (79),
`beats.sky.h` (19) and `waves.sky` (93) are **not** `#include`d by the
active `Waveshapes.cpp` and are therefore archival/curatorial source only
-- not reachable from the running program (see section 6 for the evidence
and the set-overlap analysis).

### Fields

`algo` (`BudInt`, tree leaf `"screenFieldAlgo"`, on `Field`) selects the
active field. Dispatch is a **sequential counter match**, not a switch:
`Test(name,...)` macro-expands (in file order) to
`if (test++ == oldAlgo) { title.set(name); <body>; calcViz(); return; }`,
so field index 0 is hard-coded "None" (`Field::calcMap()`'s own
`if (test++==oldAlgo) { algo.sneak(FieldNone); return; }` ahead of the
`#include`), and field index *N* (1-based within the included file) is the
*N*th `Test(...)` block. This means selecting field #200 costs up to 200
integer comparisons (negligible in practice, but structurally different
from the wave `switch`). **Only `fieldShort.sky.h` (24 fields) is actually
`#include`d** by the live `Field::calcMap()` (`pixel/Field.cpp:257`,
with `field_xy.sky`/`field_rt.sky`/`field_dir.sky` commented out
immediately below it at lines 258-260) -- `field_dir.sky.h` (107),
`field_rt.sky.h` (88), `field_xy.sky.h` (45) are **archival only, not
reachable at runtime today** (240 fields total, same archival status as
`WaveShapes.sky.h` for waves).

---

## 5. Macro input variables -- what they are and where they are sourced

| Variable | Wave/Field | Meaning | Source (file:line) |
|---|---|---|---|
| `t` | wave | elapsed seconds since program start | `double t` global, updated every frame in `WaveShapes::go()` from `skyClock.getTime()/1000.` (`pixel/Waveshapes.cpp:317`) |
| `s` | wave | step fraction 0..1 across the current shape's `Steps()` | `WaveShape::pixel()`'s `ForSteps` loop (`Waveshapes.cpp:208`); Port expansion recomputes as `sint/steps` |
| `id`, `num` | wave | current instance index [0,num), instance count | `WaveShape` members (`double id,num;`, `Waveshapes.cpp:23-28`), driven by the `ForId` loop; `num` set once from `Wave(...)`'s 5th arg (or `Num(expr)` in the legacy dialect) via `init(N)` |
| `ux,uy,ur,ua` | wave | user/UI slider parameters | `WaveShapes::userX/Y/R/A` `BudInt` leaves (tree paths `"WaveshapeUserX/Y/R/A"`, `Waveshapes.cpp:276-279`), read into a `User` struct once per frame in `WaveShapes::go()` (`Waveshapes.cpp:316`) |
| `mag(s)` | wave | time-domain audio amplitude ("oscilloscope" trace) sampled at step position `s` | `WaveShape::mag()` -> `main.waveSky.mag(steps,s)` (`Waveshapes.cpp:36`) -> `WaveSky::mag()` (`audio/WaveSky.cpp:437-455`) indexes `waveFft.Tape(index)`, the raw time-domain sample ring buffer, scaled by `magVol`/`magWidth` UI knobs, normalized `/32768.` |
| `fft(s)` | wave | frequency-domain FFT bin intensity at position `s` | `WaveShape::fft()` -> `main.waveSky.fft(steps,s)` (`Waveshapes.cpp:37`) -> `WaveSky::fft()` (`audio/WaveSky.cpp:457-475`) indexes `waveFft.GetIntensity(index)`, scaled by `fftVol`/`fftWidth`/`fftStart`, normalized `/32768.` |
| `beat()` | wave | beat-pulse accessor | `WaveShape::beat()` -> `main.waveSky.beat()` (`Waveshapes.cpp:68`) -> `WaveSky::beat()` (`audio/WaveSky.cpp:477-480`) is a **stub that unconditionally `return 1;`** in the current tree -- no real beat detection is wired to this accessor (a separate `Beat` class exists in `time/Beat.h`/`.cpp` for tempo-synced recording/playback, but it is not connected to `WaveSky::beat()`) |
| `rnd(n)` | wave + field | uniform random in `[0,n)` | `pixel/FieldFunc.cpp:15-19`, thin wrapper over libc `rand()/RAND_MAX`; consumed heavily by `A()` (wave setup) and field setup/`Go*()` expressions |
| `timeStart()`/`timeEnd()` | wave | this shape's selection start-time / auto-advance deadline | `Waveshapes.cpp:69-70`, backed by the file-scope `startime`/`endtime` doubles set in `WaveShapes::go()`/`init()` |
| `sampleSteps()`/`sampleSlots()`/`fftSlots()`/`fftSteps()` | wave | buffer sizing accessors, often used as `Steps(...)` expressions | `Waveshapes.cpp:71-74`, backed by `main.waveSky.samPerBuf`/`fftPerBuf` |
| `PI`, `sin/cos/pow/sqrt/atan2/...` | wave + field | standard math | `main/Defs.h:20` (`3.14159265358979323846`, waves) vs a **local `#define PI (3.14159265358979f)`** (float!) in `pixel/Field.cpp:68` (fields) -- the two `PI` constants are not textually identical (double vs float literal); harmless in practice but worth knowing for bit-exact ports |
| `dabs,sqr,trnc,flor,wrap,clip,pos,sgn,trwv,saw,sqwv,seed` | wave + field | small math-DSL helpers (abs, truncate, floor, wrap-to-frac, clamp-0-1, positive-part, sign, triangle-wave, sawtooth, square-wave, `srand()` reseed) | `pixel/FieldFunc.cpp:5-79` / `.h`, shared verbatim by both waves and fields |
| `x,y` | field | current destination pixel, normalized roughly to `x∈[-aspect,aspect], y∈[-1,1]` | `Field::ForXY` macro loop variables (`Field.cpp:216-218`), one iteration per screen grid cell |
| `radius,theta` | field | current destination pixel's polar coordinates, precomputed once per grid | `Field::calcRT()` (`Field.cpp:274-285`): `radius=sqrt(x^2+y^2)`, `theta=PiPos(atan2(y,x))` (wrapped to `[0,2*PI)`) |
| `a[16]` | field | setup constants for the selected field, evaluated once (see 2.2) | local `float a[16]` in `Field::calcMap()` (`Field.cpp:245`), assigned by literal `a[i]=expr;` statements ahead of the `Go*()` call |
| `d[16]` | field | optional feedback/delta channel(s) | local `float d[16]` in `Field::calcMap()` (`Field.cpp:246`), assigned by the `GoD*XY`/`GoD*RT` macro family (0-8 channels) |

**Audio-reactivity is exclusive to waves.** Field bodies have no access to
`t`, `mag()`, `fft()`, `beat()`, `id`, or `num` -- confirmed by grep across
`fieldShort.sky.h`/`field_dir/rt/xy.sky.h` (no hits for any of those
identifiers). Fields only see per-pixel position (`x,y,radius,theta`),
their own setup constants (`a[]`), optional feedback channels (`d[]`), and
`rnd()` (frozen at selection time, see 2.2).

**Cross-reference to the existing DeepMuse port-gap analysis**
(`Port/Stubs.md`): the "Audio-reactive needs" table there already flags
audio amplitude/RMS, FFT bins, and beat detection as **GAP** (no
destination equivalent in `MuAudio`) and RNG-in-kernel as **GAP** (no Metal
RNG primitive) -- this file's `mag()`/`fft()`/`beat()`/`rnd()` rows above are
exactly the WinSky-side symbols those gaps need to replace. The "Global
time uniform" gap in `Stubs.md` corresponds to this file's `t` row.

---

## 6. Notes on source dialects, quirks, and defects found during expansion

These were discovered mechanically while writing the parser/codegen used to
produce `Port/Expanded/*.expanded.cpp` (a Python macro-expander, not manual
transcription, so counts below are exact, not estimates) and are worth
knowing before porting any specific shape.

1. **`WaveShapes.sky.h` is a different, older dialect than the active
   engine.** It uses bare capitalized `ID`/`Num`/`Beat`/`EndTime`/
   `StartTime`/`NumFftBins`/`NumSampleBins` where the live
   `pixel/Waveshapes.cpp` engine uses `id`/`num`/`beat()`/`timeEnd()`/
   `timeStart()`/`fftSlots()`/`sampleSlots()`, plus abbreviated
   `Aspc`/`Stps` for `Aspect`/`Steps`, array-literal `a[N]`/`b[N]`/`c[N]`
   instead of the `aN`/`bN`/`cN` token macros, and instance count
   sometimes set via a separate `Num(expr)` macro (58 occurrences) instead
   of `Wave()`'s 5th argument. None of these legacy names exist anywhere
   else in the current `pixel/` tree (verified by grep). `WaveShapes.expanded.cpp`
   normalizes all of these to the modern spelling and calls this out in a
   file-level banner comment.
2. **`WaveShapes.sky.h`/`waves.sky`/`Particles.sky.h`/`beats.sky.h` are a
   superset/archive, not live code.** Name-overlap check: 45/47
   `waveshort.sky.h` shapes, 21/21 `PartiShort.sky.h` shapes, all 79
   `Particles.sky.h` shapes, and all 19 `beats.sky.h` shapes also appear
   (by name) in `WaveShapes.sky.h`'s 192 entries -- i.e. the "master
   archive" is a near-complete union of every curated sub-list, consistent
   with it being where shapes are authored/kept before (or after) being
   promoted into an active `#include`d shortlist. Only `Big_and_Banded2`
   and `Pollock_Spectagon` exist in `waveshort.sky.h` but not in the master
   archive (newer additions not yet merged back). The same superset
   relationship holds for fields: `field_dir.sky.h`/`field_rt.sky.h`/
   `field_xy.sky.h` (240 fields total) are commented out of the live
   `Field::calcMap()` `#include` chain (`pixel/Field.cpp:258-260`) and only
   `fieldShort.sky.h` (24 fields) is live.
3. **Execution-order hazard fixed in the expander, not just cosmetic.**
   Grouping "all `C()` terms, then all `X()`, then all `Y()`" (rather than
   preserving exact source order) would silently change behavior for any
   shape that reuses a `c[]` (or `a[]`/`b[]`) index for two different
   purposes within the same pass with an `X()`/`Y()`/`XY()` read in
   between the two writes. One shape does this on purpose:
   `Hourglass` (`waveshort.sky.h:214`) sets `c[5] = .1*mag(s)` and reads it
   in three `X()`/`Y()` terms, then **reassigns** `c[5] = ux*fft(s)*40`
   afterward for use only in `Draw()`'s width argument. A systematic check
   across all 260 wave shapes for this hazard found exactly this one case;
   `waveshort.expanded.cpp`'s `wave_Hourglass` preserves the original
   interleaved order (see the file's own comment on why) rather than the
   grouped order used everywhere else that grouping is provably safe
   (`x[]`/`y[]` are write-only sinks -- never read back by any macro body,
   confirmed by grep -- so grouping C/X/Y/XY *within* a pass is safe except
   for this specific same-index-reuse pattern).
4. **`id`/`num` are `double`, not `int`.** `WaveShape` declares
   `double s,si,aspect,num,id;` (`Waveshapes.cpp:23-28`); several shapes
   compute `id/num` expecting a floating-point fraction (e.g. an angular
   position around a circle). `Port/Expanded/*.expanded.cpp` functions
   take `double id, double num` for exactly this reason -- an `int`
   signature would silently truncate `id/num` to 0 for `id<num`.
5. **`Steps(-1)` is a sentinel meaning 300**, per
   `#define Steps(P) steps=(int)(P); if (steps==-1) steps=300;`
   (`Waveshapes.cpp:159`). 5 shapes in `waveshort.sky.h` use it
   (`Hourglass`, `Dans_Furathama`, `Rotating_Arcs`, `Darren_Doublehelix`,
   `Splutterbug`); the expander reproduces the fallback explicitly rather
   than leaving `steps=-1` (which would make the per-step loop a no-op).
6. **`Steps()`/`Aspect()` are shape-wide, not per-instance, despite living
   inside the per-instance `ForId` setup loop.** They assign to plain
   `WaveShape` members (`this->steps`, `this->aspect`), so if a shape's
   `Steps(...)`/`Aspect(...)` expression references `id`, only the *last*
   instance's value survives setup and applies to every instance for the
   shape's whole lifetime (e.g. `Miris_Ball`'s `Steps(num + (num - id))` in
   `WaveShapes.sky.h`). Flagged with a `NOTE(port)` in the generated
   function header whenever detected.
7. **Four confirmed source defects, all preserved-and-flagged rather than
   silently fixed** (found by an automated `)digit`-with-no-operator scan,
   an argument-count scan, and a case-sensitivity scan across all three
   wave files -- not by manual reading, so this list is exhaustive for
   those defect classes):
   - `WaveShapes.sky.h:36` (`Eight_Flying_Bassheadz_Tomi`): `Draw(1,
     20*(mag(s)+.15)1, 1)` -- a stray `1` after a close-paren with no
     operator; not valid C++ as written. Preserved verbatim, flagged
     `TODO(port)`.
   - `WaveShapes.sky.h:1868` (`Meth_Junkie`): `Draw(3,1)` -- only 2 of the
     required 3 arguments; expander defaults the missing color argument to
     `1` and flags `TODO(port)`.
   - `WaveShapes.sky.h:953` (`DaveF_Planets_Align`): `draw(1,a[0],1)` --
     lowercase; `Draw` is a case-sensitive macro name, so as written the
     real engine would **not** expand this call at all (the shape would
     render nothing). Used as a best-effort fallback, flagged `TODO(port)`.
   - `WaveShapes.sky.h:610-614` (`Critters`): four `XY(N,expr)` calls have
     a stray `)` truncating the argument list early (e.g.
     `XY( 4,c[2]* .5) , c[3]* .5)`), leaving `, c[3]* .5)` dangling as
     inert text immediately after. The expander detects the dangling
     `, <expr>)` fragment, reattaches it as the missing 2nd argument
     (matching the clear sibling pattern of the surrounding "Inner"/"Outer"
     XY groups at 0.25/0.75 scale vs this "Middle" group's 0.5 scale), and
     flags all four recovered lines `TODO(port)` for verification.
8. **Some macro bodies read a `c[]`/`b[]` index before it is ever
   assigned in the same pass** (e.g. `Critters`'s `C(3,c[1]*sin(...))`
   appears before `C(1,...)` assigns `c[1]`). Because `WaveVars` arrays are
   **not** cleared between frames, this picks up whatever value was left
   in that slot by the *previous frame's* pass (a one-frame-stale read) --
   this is a faithful characteristic of the original engine, reproduced
   as-is by the expander (execution order preserved per point 3 above), not
   a parser artifact. Worth knowing if a port "fixes" it and gets a subtly
   different look.

## 7. Codegen correctness methodology (why the expansions can be trusted)

The five `Port/Expanded/*.expanded.cpp` files were produced by a small
Python macro-expander (parse the `Wave()`/`Test()` DSL with a balanced-paren
scanner, not regex-only), not by hand-transcribing 524 shapes. Validation
performed (all counts below are exact):
- Every `A(`/`B(`/`C(`/`X(`/`Y(`/`XY(`/`Draw(`/`Test(`/`Go*(` occurrence
  outside a comment was accounted for -- cross-checked the parser's call
  counts against an independent regex count over comment-stripped source
  for every file; final counts match exactly (e.g. `WaveShapes.sky.h`:
  734 `A(`, 650 `B(`, 633 `C(`, 215 `X(`, 209 `Y(`, 424 `XY(`, 192 `Draw`-family
  calls, all captured).
- Zero silently dropped macro calls: every `Wave()`/`Test()` block produced
  exactly one output function; every shape has a non-`null` `Draw()` (after
  the point-7 defect recovery above); every field has exactly one `Go*()`
  warp (240/240 field-archive entries have exactly 1, none have 0 or >1).
- Brace-balance and function-count sanity checks pass on all five output
  files (260 `wave_*` functions across the three wave files = 192+47+21;
  240 + 24 = 264 `field_*` functions across the two field files).
- Two field names (`D_Julia B` at `field_xy.sky.h:1` and `field_xy.sky.h:403`;
  `Thick River` at `field_xy.sky.h:321` and `field_xy.sky.h:327`) repeat
  *within* `field_xy.sky.h` itself; disambiguated with a `_2` suffix in
  `field_variants.expanded.cpp` (source `file:line` in each function's
  header comment is the authoritative identity either way).

---

## 8. Catalog: every wave shape and field function

524 entries total: 260 wave shapes (47 active + 21 active-particle + 192
archive) and 264 field functions (24 active + 240 archive). "Math
description" is generated from the actual parsed expressions (draw mode,
symmetry-fold count, rotation/audio/randomization/instance-count/pseudo-3D
detection for waves; polar-vs-Cartesian, radial/angular/ripple/Julia/jitter/
feedback-channel detection for fields), combined with the author's own
short description text where the source provided one (shown before the
` -- ` separator). This is a systematic heuristic over 524 entries, not
524 individually hand-written descriptions -- treat it as a fast index into
`Port/Expanded/*.expanded.cpp` (same `Name`/source `Line` identify the
matching expanded function) rather than a definitive characterization; the
expanded C++ is the source of truth for exact math.

#### Waves -- active shortlist (pixel/waveshort.sky.h) -- 47 wave shapes

| # | Name | Line | Author | Instances | Steps | Math description |
|---|---|---|---|---|---|---|
| 1 | Pair | 1 | Jay Mc Bride | 1 | 100 | 2-fold connected (rotating, audio-reactive) |
| 2 | Dancing_Days | 30 | Thomas Geier | 1 | 150 | 6-fold connected (rotating, audio-reactive, pseudo-3D perspective) |
| 3 | Five | 64 | Jay Mc Bride | 1 | 120 | Satellite Lovers with kids -- 5-fold connected (rotating, audio-reactive, pseudo-3D perspective) |
| 4 | Big_and_Banded | 115 | -- | 1 | 100 | connected (audio-reactive) |
| 5 | Big_and_Banded2 | 124 | -- | 1 | 100 | connected (audio-reactive) |
| 6 | HAL_Splashy_Scope | 132 | Howard A. Landman | 1 | sampleSlots() | dotted (rotating, audio-reactive) |
| 7 | Cycling_Dots | 148 | Christian Lupp, Germany | 2 | 11 | dotted (audio-reactive, 2-instance) |
| 8 | CircWarp | 167 | Andy O'Meara | (int)(10+rnd(12)+rnd(12)) | 20 | connected (rotating, audio-reactive, (int)(10+rnd(12)+rnd(12))-instance) |
| 9 | Dense_Spiral | 195 | Erlend Robaye | 1 | 720 | dotted (rotating, audio-reactive) |
| 10 | Hourglass | 214 | Erik, aka HHunter | 1 | -1 | 3-fold dotted (rotating, audio-reactive) |
| 11 | DT_SineDot | 247 | David Tryse | 1 | 68 | 3-fold dotted (rotating, audio-reactive) |
| 12 | Pollock_Spectagon | 272 | ws | 2 | 9 | dotted (audio-reactive, randomized, 2-instance) |
| 13 | Uber_Aurora | 295 | Uberbach | 1 | 80 | 3-fold dotted (audio-reactive) |
| 14 | Spectagon | 315 | Erik Loyer & Andy O'Meara | 1 | 5 | 9-fold connected (rotating, audio-reactive) |
| 15 | I_Declare | 344 | -- | 1 | 500 | Generator -- connected (rotating, audio-reactive) |
| 16 | Align | 396 | Andy O | 1 | 100 | tictactoe by sephless -- 4-fold connected (rotating, audio-reactive) |
| 17 | Arena | 421 | Thomas Geier | 1 | 100 | 4-fold connected (rotating, audio-reactive) |
| 18 | Critters | 448 | Andy? | 1 | 100 | Quad-circle -- 12-fold connected (audio-reactive) |
| 19 | Cylinder | 481 | -- | 1 | 512 | Generator.txt -- connected (rotating, audio-reactive) |
| 20 | Dans_Furathama | 505 | Samaan Ibrahim | 1 | -1 | 2-fold connected (rotating, audio-reactive) |
| 21 | Father_and_Daughters | 534 | Demonseed | 1 | fftSlots() | Simple Horizontal -- 8-fold connected (audio-reactive) |
| 22 | Lightning_Strikes | 556 | Bob Covey | 1 | 32 | 4-fold connected (rotating, audio-reactive) |
| 23 | Moving | 613 | Justin Swidler | 1 | 160 | 5-fold connected (rotating, audio-reactive) |
| 24 | Radar_Sweep | 631 | -- | 1 | 512 | connected (rotating, audio-reactive) |
| 25 | Rotating_Arcs | 647 | -- | 1 | -1 | 2-fold dotted (rotating, audio-reactive) |
| 26 | Rotating_Bars | 666 | -- | 1 | 30 | 10-fold connected (rotating, audio-reactive) |
| 27 | Rotating_X | 689 | -- | 1 | 512 | 2-fold dotted (rotating, audio-reactive) |
| 28 | Simple_Horizontal | 705 | -- | 1 | 512 | connected (audio-reactive, randomized) |
| 29 | Simple_Vertical | 715 | -- | 1 | 512 | connected (audio-reactive) |
| 30 | Sing_Me_to_Sleep | 724 | Andy O | 1 | fftSlots() | 4-fold connected (audio-reactive) |
| 31 | SM_Spectometer | 738 | Sajoy Mukundan | 1 | 10 | 20-fold connected (audio-reactive, randomized) |
| 32 | SOLs_Vinyl | 770 | Brad Anderson | 1 | 512 | 4-fold dotted (rotating, audio-reactive, pseudo-3D perspective) |
| 33 | Spin_Doctor | 818 | Andy Cabrera | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 34 | SpinIt | 839 | Jay | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 35 | The_Eye | 861 | Thomas Geier | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 36 | Threes_A_Crowd | 879 | Jay Protopapas | 1 | 128 | 3-fold dotted (rotating, audio-reactive) |
| 37 | Thunderation | 902 | -- | 1 | 2 * fftSlots() | 2-fold connected (audio-reactive, randomized) |
| 38 | Wave | 919 | Thomas Geier | 1 | 512 | 3-fold connected (rotating, audio-reactive) |
| 39 | Darren_Doublehelix | 937 | Darren Izzard | 1 | -1 | 2-fold connected (rotating, audio-reactive) |
| 40 | DT_Spectrum | 966 | David Tryse | 1 | 3 | 12-fold connected (rotating, audio-reactive) |
| 41 | DT_Wild | 987 | David Tryse | 1 | 512 | connected (rotating, audio-reactive) |
| 42 | Splutterbug | 997 | -- | 1 | -1 | connected (rotating, audio-reactive) |
| 43 | Orbiting_Stars | 1022 | Ted | 1 | 55 | 6-fold connected (rotating, audio-reactive, pseudo-3D perspective) |
| 44 | Sci_Fi_Expander | 1130 | Ted | 1 | 512 | Sci-Fi Expander by Andy O'Meara -- 4-fold connected (rotating, audio-reactive) |
| 45 | Simple_Sine | 1147 | Ted | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 46 | Tension_II | 1162 | Ted | 1 | fftSlots() | 6-fold connected (rotating, audio-reactive) |
| 47 | Walls_of_Sound | 1187 | Ted | 1 | fftSlots() | 12-fold connected (rotating, audio-reactive) |

#### Waves -- active particle shortlist (pixel/PartiShort.sky.h) -- 21 wave shapes

| # | Name | Line | Author | Instances | Steps | Math description |
|---|---|---|---|---|---|---|
| 1 | Sparkling_Table_Water | 1 | Thomas Geier | 12 | 12 | dotted (rotating, 12-instance) |
| 2 | Solala | 24 | Thomas Geier | 5 | 5 + rnd( 5 ) | dotted (rotating, 5-instance) |
| 3 | Rotating_Pulsating_Oval | 54 | by Erlend Robaye | 1 | 16 | dotted (rotating) |
| 4 | Colliders | 70 | Erlend Robaye | 10 | 2 | 5-fold dotted (rotating, 10-instance, pseudo-3D perspective) |
| 5 | Dancing_String | 170 | Thomas Geier | 1 | 300 | connected (rotating) |
| 6 | Orbiting_Rods_N_Sticks | 195 | Andy O'Meara | (int)(8+rnd(18.1)) | 2 | connected (rotating, (int)(8+rnd(18.1))-instance) |
| 7 | Miris_Ball | 217 | Jeff Osborn | (int)(rnd(5)+8) | num + (num - id) | 2-fold dotted (rotating, (int)(rnd(5)+8)-instance) |
| 8 | Waves | 253 | Erlend Robaye | 1 | 20 | 9-fold dotted (rotating, audio-reactive) |
| 9 | DNA_String | 287 | Erlend Robaye | 1 | 200 | dotted (rotating, pseudo-3D perspective) |
| 10 | Sea_Surface | 343 | Erlend Robaye | 1 | sqr(flor(15+ rnd(15) ) ) | dotted (rotating) |
| 11 | Pollock_Dots | 390 | Christian Lupp, Germany | 2 | 9 | dotted (randomized, 2-instance) |
| 12 | Pop_Circles | 410 | -- | (int)(rnd(12)+3) | 70 | connected (rotating, (int)(rnd(12)+3)-instance) |
| 13 | Raindrops | 431 | -- | 1 | 210 | dotted |
| 14 | Protozoan_Lovers | 442 | Jeff Osborn | (int)(rnd(2.5)+1) | rnd(3) + 9 | dotted (rotating, (int)(rnd(2.5)+1)-instance) |
| 15 | Snakes | 463 | Thomas Geier | (int)(5+rnd(10)) | 50 | connected (rotating, (int)(5+rnd(10))-instance, pseudo-3D perspective) |
| 16 | Spiral | 490 | Thomas Geier | 1 | 500 | connected (rotating) |
| 17 | Tosser | 509 | Justin Swidler | 1 | 121 | dotted (rotating, audio-reactive) |
| 18 | Typhoon | 539 | Erlend Robaye | 1 | 150 | dotted (rotating, audio-reactive, pseudo-3D perspective) |
| 19 | Uber_Spirograph | 605 | Uberbach | 1 | 512 | dotted (rotating) |
| 20 | Crosshatch | 617 | Ted | 1 | 300 | 2-fold connected (randomized) |
| 21 | Juggler | 643 | Ted | (int)(2+rnd(16)) | 2 | Orbiting Rods -- connected (rotating, (int)(2+rnd(16))-instance) |

#### Waves -- master archive (pixel/WaveShapes.sky.h) -- 192 wave shapes

| # | Name | Line | Author | Instances | Steps | Math description |
|---|---|---|---|---|---|---|
| 1 | Eight_Flying_Bassheadz_Tomi | 1 | -- | 1 | 2 | 12-fold connected (rotating, audio-reactive) |
| 2 | A_New_Hope | 38 | Andy | 1 | 130 | 4-fold connected (rotating, audio-reactive) |
| 3 | Airport | 58 | Thomas Geier | 1 | 40 | Look into the Sun -- 4-fold dotted (rotating) |
| 4 | Align | 76 | Andy O | 1 | 512 | tictactoe by sephless -- 4-fold connected (rotating, audio-reactive) |
| 5 | Arena | 107 | Thomas Geier | 1 | 100 | 4-fold connected (rotating, audio-reactive) |
| 6 | Attack | 134 | Thomas Geier | 3 | 15 | Sperm Attack -- 4-fold dotted (rotating, 3-instance) |
| 7 | BatSignal | 154 | Jay Protopapas | 1 | 201 | Critters -- 4-fold dotted (audio-reactive) |
| 8 | Big_and_Banded | 172 | -- | 1 | 512 | connected (audio-reactive) |
| 9 | Blades | 179 | Erlend Robaye | 2 + rnd( 4.1 ) | 360 | connected (rotating, 2 + rnd( 4.1 )-instance) |
| 10 | BoomBarrel | 218 | Jay Protopapas | 1 | NumFftBins / 8 | Critters -- 8-fold connected (audio-reactive) |
| 11 | Brain_Candy | 242 | Jeff Osborn | rnd(2) + 4 | 20 | connected (rotating, audio-reactive, rnd(2) + 4-instance) |
| 12 | Bunch | 263 | Erlend Robaye | 1 | 12 | dotted (rotating) |
| 13 | Centipede | 284 | -- | 1 + rnd( 7 ) | 1 | dotted (rotating, 1 + rnd( 7 )-instance) |
| 14 | Championship | 310 | Jay Protopapas | 1 | 201 | Critters -- 8-fold dotted (audio-reactive) |
| 15 | CircWarp | 334 | Andy O'Meara | 10 + rnd( 12 ) + rnd( 12 ) | 20 | connected (rotating, audio-reactive, 10 + rnd( 12 ) + rnd( 12 )-instance) |
| 16 | Colliders | 362 | Erlend Robaye | 10 | 2 | 5-fold dotted (rotating, 10-instance, pseudo-3D perspective) |
| 17 | Conic_Rave | 462 | -- | 1 | -1 | 2-fold connected (rotating) |
| 18 | Converge_Circle | 497 | Tomi Sajaniemi | 1 | 54 | Converge by Andy -- connected (randomized) |
| 19 | Converge_3 | 515 | -- | 1 | 3 + rnd( 15 ) | 3-fold dotted (rotating) |
| 20 | Converge | 545 | Andy | 1 | 27 | dotted (rotating) |
| 21 | Cotillion | 564 | Jay Protopapas | 1 | 60 | A New Hope -- 4-fold dotted (rotating) |
| 22 | Critters | 590 | Andy? | 1 | 100 | Quad-circle -- 12-fold connected (audio-reactive) |
| 23 | Cross | 624 | Erlend Robaye | 6 | 1 | 4-fold dotted (rotating, 6-instance) |
| 24 | CrossBall | 686 | Thomas Geier | 1 | 50 | 6-fold connected (rotating, audio-reactive) |
| 25 | Crosshairs | 753 | -- | 2 + rnd( 4.1 ) | 4 | connected (rotating, 2 + rnd( 4.1 )-instance) |
| 26 | Cutters | 771 | Demonseed | 1 | NumFftBins | Wind Mill by Andy Cabrera -- 18-fold connected (rotating, audio-reactive) |
| 27 | Cycling_Dots | 812 | Christian Lupp, Germany | 2 | 11 | dotted (audio-reactive, 2-instance) |
| 28 | Cylinder | 833 | -- | 1 | 512 | Generator.txt -- connected (rotating, audio-reactive) |
| 29 | Dans_Furathama | 857 | Samaan Ibrahim | 1 | -1 | 2-fold connected (rotating, audio-reactive) |
| 30 | Dancing_Days | 885 | Thomas Geier | 1 | 150 | 6-fold connected (rotating, audio-reactive, pseudo-3D perspective) |
| 31 | Dancing_String | 919 | Thomas Geier | 1 | 300 | connected (rotating) |
| 32 | DaveF_Planets_Align | 943 | DaveF | 1 | 5 + rnd(160) | Galaxy -- 2-fold connected (rotating) |
| 33 | DBears_Three_Dance | 955 | Denver Bear | 1 | 512 | 3-fold connected (rotating, audio-reactive) |
| 34 | DBears_Dancing_Curls | 987 | Denver Bear | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 35 | DBears_Spin_Grow | 1012 | Denver Bear | 1 | 512 | flowerpower -- 4-fold connected (rotating, audio-reactive) |
| 36 | Dense_Spiral_II | 1048 | Erlend Robaye | 1 | 100 | dotted (rotating) |
| 37 | Dense_Spiral | 1072 | Erlend Robaye | 1 | 720 | dotted (rotating, audio-reactive) |
| 38 | DNA_String | 1090 | Erlend Robaye | 1 | 200 | dotted (rotating) |
| 39 | Dot_Grid | 1142 | -- | 1 | 324 | dotted (rotating) |
| 40 | ER_Rhythm_is_Deified | 1163 | Erlend Robaye | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 41 | Ellipses | 1248 | Thomas Geier | 1 | 512 | 5-fold connected (rotating, audio-reactive) |
| 42 | Engage | 1283 | Andy | 3 + rnd( 20 ) | 5 + trnc( rnd( 1.9 ) ) * 100 | connect=2 (randomized, 3 + rnd( 20 )-instance) |
| 43 | Explosion | 1310 | Thomas Geier | 1 + rnd( 3.5 ) | 30 + rnd( 90 ) | dotted (randomized, 1 + rnd( 3.5 )-instance) |
| 44 | Father_and_Daughters | 1338 | Demonseed | 1 | NumFftBins | Simple Horizontal -- 8-fold connected (audio-reactive) |
| 45 | Five | 1359 | Jay Mc Bride | 1 | 120 | Satellite Lovers with kids -- 5-fold connected (rotating, audio-reactive) |
| 46 | Flower_Power_Erie_Atom | 1413 | Dr. Joseph A. Gardner | 1 | 512 | Flower Power -- 2-fold connected (rotating, audio-reactive) |
| 47 | Flower_Power_Spinner | 1433 | Dr. Joseph A. Gardner | 1 | 512 | Flower Power -- 2-fold connected (rotating, audio-reactive) |
| 48 | Flower_Power | 1458 | -- | 1 | 512 | dotted (rotating, audio-reactive) |
| 49 | HAL_Splashy_Scope | 1478 | Howard A. Landman | 1 | NumSampleBins | dotted (rotating, audio-reactive) |
| 50 | Heart_of_the_Beast | 1495 | -- | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 51 | Hollow_Circle | 1509 | -- | 2 | 512 | Andy O's Hollow Horizontal -- connected (audio-reactive, randomized, 2-instance) |
| 52 | Horizontal_Corridor | 1530 | Ted | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 53 | Horzonal_Sweep | 1549 | -- | 1 | -1 | 2-fold connected (rotating, audio-reactive) |
| 54 | Hourglass | 1562 | Erik, aka HHunter | 1 | -1 | 3-fold dotted (rotating, audio-reactive) |
| 55 | I_Declare | 1592 | -- | 1 | 100*(3+ fmod(rnd(400),4) ) | Generator -- connected (rotating, audio-reactive) |
| 56 | Unknown | 1645 | -- | 1 | NumSampleBins | connected (audio-reactive) |
| 57 | Kaleidoscope | 1688 | Jeff Osborn | 1 | 512 | 8-fold dotted (audio-reactive) |
| 58 | Lightning_Strikes | 1712 | Bob Covey | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 59 | Lizys_Starry_Night | 1768 | Jeff Osborn | 3 + rnd( 3.99 ) | 140 | I stole some code from Thomas Geier -- connected (rotating, 3 + rnd( 3.99 )-instance) |
| 60 | Magnum_II | 1800 | -- | 5 + rnd( 4.9 ) | 100 | connected (rotating, audio-reactive, 5 + rnd( 4.9 )-instance) |
| 61 | Melt_O_Rama | 1824 | Andy Cabrera | 1 | 15 | Melt-O-Rama for SoundJamMP -- 6-fold dotted (audio-reactive, randomized) |
| 62 | Meth_Junkie | 1844 | -- | 1 | 151 | 9-fold connect=3 (rotating, audio-reactive) |
| 63 | Metors | 1872 | -- | 4 + rnd( 8 ) + rnd( 18 ) | 1 | dotted (randomized, 4 + rnd( 8 ) + rnd( 18 )-instance) |
| 64 | Miris_Ball | 1897 | Jeff Osborn | rnd(5) + 8 | Num + (Num - ID) | 2-fold dotted (rotating, rnd(5) + 8-instance) |
| 65 | Moon_and_Sun | 1933 | -- | 1 | 18 | 3-fold dotted (rotating, audio-reactive) |
| 66 | Mother_and_Daughters | 1959 | -- | 1 | 512 | 5-fold connected (audio-reactive) |
| 67 | Moving | 1974 | Justin Swidler | 1 | 160 | 5-fold connected (rotating, audio-reactive) |
| 68 | NPTU_Squared | 1992 | Andy | 1 | 150 | 4-fold connected (rotating, audio-reactive) |
| 69 | Null | 2013 | Andy | 1 | 512 | 3-fold connected (rotating, audio-reactive) |
| 70 | Orbiting_Rods_N_Sticks | 2045 | Andy O'Meara | 8 + rnd( 18.1 ) | 2 | connected (rotating, 8 + rnd( 18.1 )-instance) |
| 71 | Orbiting_Rods | 2067 | Andy | 2 + rnd( 5.1 ) | 2 | connected (rotating, 2 + rnd( 5.1 )-instance) |
| 72 | Pair | 2087 | Jay Mc Bride | 1 | 100 | 2-fold connected (rotating, audio-reactive) |
| 73 | Parkening_Power | 2119 | -- | 1 | 51 | 3-fold connected (rotating, audio-reactive) |
| 74 | Pearl | 2137 | Thomas Geier | 20+rnd(40) | 17 | dotted (randomized, 20+rnd(40)-instance) |
| 75 | Pollock_Dots | 2159 | Christian Lupp, Germany | 2 | 9 | dotted (randomized, 2-instance) |
| 76 | Pop_Circles | 2182 | -- | rnd(12)+3 | 70 | connected (rotating, rnd(12)+3-instance) |
| 77 | Prophesy_SC | 2204 | -- | 4 + rnd( 10 ) | 15 | 5-fold connected (rotating, 4 + rnd( 10 )-instance) |
| 78 | Protozoan_Lovers | 2228 | Jeff Osborn | rnd(2.5) + 1 | rnd(3) + 9 | dotted (rotating, rnd(2.5) + 1-instance) |
| 79 | Pulsing_Oval | 2250 | Erlend Robaye | 1 | -1 | connected (rotating) |
| 80 | Pyramidion_Particle | 2264 | Erlend Robaye | 1 | 5 | Pyramidion -- 10-fold connected (rotating) |
| 81 | Quad_Circle | 2336 | -- | 1 | 100 | 4-fold connected (audio-reactive) |
| 82 | Quad_Sweep | 2353 | -- | 1 | 100 | 16-fold connected (rotating, audio-reactive) |
| 83 | Quadrapinski | 2407 | -- | 1 | 450 | iterated function system fractal -- dotted (audio-reactive, randomized) |
| 84 | Qvark | 2442 | Ted | 5+rnd(8) | 45 | Thanks To Thomas Geier -- connected (rotating, 5+rnd(8)-instance) |
| 85 | Radar_Sweep | 2469 | -- | 1 | 512 | connected (rotating, audio-reactive) |
| 86 | Raindrops | 2484 | -- | 1 | 210 | dotted |
| 87 | Raining_Oscilliscopes | 2496 | -- | 2 + rnd( 12 ) + rnd( 12 ) | 40 | connected (audio-reactive, randomized, 2 + rnd( 12 ) + rnd( 12 )-instance) |
| 88 | Random_Corridor | 2523 | -- | 1 | 512 | 2-fold connected (audio-reactive, randomized) |
| 89 | RipplingSpiral | 2540 | Erlend Robaye | 1 | rnd( 120 ) + 20 | dotted (rotating) |
| 90 | Robox | 2599 | Thomas Geier | 2+rnd(6) | 30 | 4-fold dotted (rotating, audio-reactive, 2+rnd(6)-instance) |
| 91 | Rotating_Arcs | 2625 | -- | 1 | -1 | 2-fold dotted (rotating, audio-reactive) |
| 92 | Rotating_Bars | 2644 | -- | 1 | 30 | 10-fold connected (rotating, audio-reactive) |
| 93 | Rotating_Pulsating_Oval_II | 2667 | -- | 1 | -1 | connected (rotating, audio-reactive) |
| 94 | Rotating_Pulsating_Oval | 2690 | by Erlend Robaye | 1 | 16 | dotted (rotating) |
| 95 | Rotating_X | 2707 | -- | 1 | 512 | 2-fold dotted (rotating, audio-reactive) |
| 96 | Sea_Surface | 2723 | Erlend Robaye | 1 | sqr(flor(15+ rnd(15) ) ) | dotted (rotating) |
| 97 | Simon_Says | 2769 | -- | 1 | 12 | A New Hope -- 4-fold connected (rotating, audio-reactive) |
| 98 | Simple_Horizontal | 2790 | -- | 1 | 512 | connected (audio-reactive, randomized) |
| 99 | Simple_Vertical | 2800 | -- | 1 | 512 | connected (audio-reactive) |
| 100 | Sine | 2809 | Erlend Robaye | 1 | 30 | dotted (rotating) |
| 101 | Sing_Me_to_Sleep | 2824 | Andy O | 1 | NumFftBins | 4-fold connected (audio-reactive) |
| 102 | SM_Colliding_Sticks | 2838 | Sajoy Mukundan | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 103 | SM_Spectometer | 2871 | Sajoy Mukundan | 1 | 10 | 20-fold connected (audio-reactive, randomized) |
| 104 | Snake | 2903 | Erlend Robaye | 1 | 25 | 3-fold dotted (rotating) |
| 105 | SnakePit | 2928 | Erlend Robaye | 1 | 512 | 3-fold connected (rotating, audio-reactive) |
| 106 | Snakes | 2963 | Thomas Geier | 5+rnd(10) | 50 | connected (rotating, 5+rnd(10)-instance) |
| 107 | Solala | 2989 | Thomas Geier | 1 | 2 + rnd( 50 ) | dotted (rotating) |
| 108 | SOLs_Vinyl | 3012 | Brad Anderson | 1 | 512 | 4-fold dotted (rotating, audio-reactive) |
| 109 | Sparkling_Table_Water | 3059 | Thomas Geier | 15 | 15 | dotted (rotating, 15-instance) |
| 110 | Spectagon | 3082 | Erik Loyer & Andy O'Meara | 1 | 4 + rnd( 1.9 ) | 9-fold connected (rotating, audio-reactive) |
| 111 | Spin_Doctor_II | 3111 | Andy Cabrera | 1 | 150 | 4-fold connected (rotating, audio-reactive) |
| 112 | Spin_Doctor | 3140 | Andy Cabrera | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 113 | SpinIt | 3161 | Jay | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 114 | Spinning_Cube | 3183 | Thomas Geier | 1 | 2 | Spinning Tetraeder -- 12-fold connected (rotating, pseudo-3D perspective) |
| 115 | Spinning_Plane | 3263 | -- | 1 | 121 | dotted (rotating) |
| 116 | Spinning_Tetra | 3319 | Andy O'Meara | 1 + rnd( 7 ) | 4 | Spinning plane -- dotted (rotating, 1 + rnd( 7 )-instance) |
| 117 | Spinning_Tetraeder | 3383 | Thomas Geier | 1 | 2 | 6-fold connected (rotating) |
| 118 | Spiral | 3467 | Thomas Geier | 1 | 500 | connected (rotating) |
| 119 | Splutterbug | 3485 | -- | 1 | -1 | connected (rotating, audio-reactive) |
| 120 | Sprinkles | 3510 | -- | 1 | 15 + rnd( 15 ) | dotted |
| 121 | Spyroid | 3526 | Erlend Robaye | 1 | 720 | connected (audio-reactive, randomized) |
| 122 | Square_Wheel_5 | 3569 | -- | rnd( 5 ) | 5 | connected (rotating, audio-reactive, rnd( 5 )-instance) |
| 123 | Starsweep | 3591 | Chris Sherrill | 1 | 6 | Darren Scanner -- 20-fold connected (rotating, audio-reactive) |
| 124 | Storm_Beat | 3644 | -- | 1 | 3 + rnd( 8 ) | dotted (rotating, audio-reactive) |
| 125 | Suck_Me_In | 3662 | Jeff Osborn | 1 | ( 10 + rnd( 30 ) ) * 30 | connected (rotating) |
| 126 | Tango_Particles | 3689 | -- | trnc( 20 * pow(rnd(1),9) +1.99 ) | 20 | connected (rotating, trnc( 20 * pow(rnd(1),9) +1.99 )-instance) |
| 127 | The_Eye | 3711 | Thomas Geier | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 128 | Threes_A_Crowd | 3729 | Jay Protopapas | 1 | 512 | 3-fold dotted (rotating, audio-reactive) |
| 129 | Thunderation | 3751 | -- | 1 | 2 * NumFftBins | 2-fold connected (audio-reactive, randomized) |
| 130 | Tosser | 3767 | Justin Swidler | 1 | 121 | dotted (rotating) |
| 131 | Tri_Cycle | 3796 | -- | 1 | -1 | 3-fold connected (rotating, audio-reactive) |
| 132 | Tri_Cycling_Dots | 3821 | by Christian Lupp, Germany | 2 | 11 | 3-fold dotted (audio-reactive, 2-instance) |
| 133 | Tri_Vertical | 3856 | -- | 1 | 512 | 3-fold connected (audio-reactive) |
| 134 | Typhoon | 3869 | Erlend Robaye | 1 | 150 | dotted (rotating) |
| 135 | Uber_Aurora | 3936 | Uberbach | 1 | 80 | 3-fold dotted (audio-reactive) |
| 136 | Uber_Disco_lights | 3955 | Uberbach | 1 | 128 | dotted (rotating, audio-reactive) |
| 137 | Uber_Spirograph | 3970 | Uberbach | 1 | 512 | dotted (rotating) |
| 138 | Uber_Twin_Snake | 3981 | Uberbach | 1 | 512 | 2-fold connected (rotating) |
| 139 | Up_Like_A_Cup | 4001 | -- | 1 | 512 | connected (audio-reactive) |
| 140 | Vertical_Corridor | 4011 | -- | 1 | -1 | 2-fold connected (audio-reactive) |
| 141 | Warp_Me_Away | 4024 | Andy O | 1 | 150 + rnd( 250 ) | dotted (rotating) |
| 142 | Wave | 4044 | Thomas Geier | 1 | 512 | 3-fold connected (rotating, audio-reactive) |
| 143 | Waves | 4062 | Erlend Robaye | 1 | 20 | 9-fold dotted (rotating) |
| 144 | Web_X | 4096 | Demonseed | 1 | 512 | SOL Vinyl -- 7-fold connected (rotating, audio-reactive) |
| 145 | Wind_Mill | 4151 | Andy Cabrera | 1 | 100 | Kaleidoscope -- 6-fold dotted (rotating, audio-reactive) |
| 146 | Yearmix_Box | 4177 | Andy O? | 1 | 5 | Yearmix 2001 -- 3-fold connect=2 (randomized) |
| 147 | Zoomed_Square | 4204 | Justin Swidler | 1 | -1 | Hortizontal Sweep -- 4-fold connected (rotating, audio-reactive) |
| 148 | Darren_Bird | 4223 | Darren Izzard | 1 | 0 | Darren RScanner -- 3-fold connected (rotating, audio-reactive) |
| 149 | Darren_DDoublehelix | 4249 | Darren Izzard | 1 | 512 | 4-fold connected (rotating, audio-reactive) |
| 150 | Darren_Doublehelix | 4277 | Darren Izzard | 1 | 0 | 2-fold connected (rotating, audio-reactive) |
| 151 | Darren_Quadhelix | 4304 | Darren Izzard | 1 | 0 | 4-fold connected (rotating, audio-reactive) |
| 152 | Darren_Scanner | 4336 | Darren Izzard | 1 | 0 | 2-fold connected (rotating, audio-reactive) |
| 153 | Darren_Stairway | 4364 | Darren Izzard | 1 | 0 | 4-fold connected (rotating, audio-reactive) |
| 154 | DT_Birds | 4399 | David Tryse | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 155 | DT_BorderThunder | 4421 | David Tryse | 1 | 512 | 8-fold connected (audio-reactive) |
| 156 | DT_Circle_II | 4439 | David Tryse | 1 | 512 | connected (audio-reactive) |
| 157 | DT_Circle_III | 4454 | David Tryse | 1 | 512 | connected (audio-reactive) |
| 158 | DT_Explode | 4467 | David Tryse | 1 | 42 | 2-fold connected (rotating, audio-reactive) |
| 159 | DT_Galaxy | 4491 | David Tryse | 1 | 333 | 2-fold connected (rotating) |
| 160 | DT_Mysko | 4503 | David Tryse | 1 | 512 | connected (rotating) |
| 161 | DT_Sine | 4517 | David Tryse | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 162 | DT_SineDot | 4534 | David Tryse | 1 | 68 | 3-fold dotted (rotating, audio-reactive) |
| 163 | DT_Snake | 4559 | David Tryse | 1 | 28 | connected (rotating, audio-reactive) |
| 164 | DT_Spectrum | 4576 | David Tryse | 1 | 3 | 12-fold connected (rotating, audio-reactive) |
| 165 | DT_Wild | 4597 | David Tryse | 1 | 512 | connected (rotating, audio-reactive) |
| 166 | DT_ZoomPlanet | 4607 | David Tryse | 1 | 42 | 11-fold connected (randomized) |
| 167 | Chi_II | 4639 | -- | 1 | NumFftBins | 4-fold connected (rotating, audio-reactive) |
| 168 | Crosshatch | 4679 | Ted | 1 | 300 | 2-fold connected (randomized) |
| 169 | Cylinder_Crown | 4705 | Ted | 1 | 2 * trnc( 2 + rnd(3.9) ) * NumFftBins | 2-fold connect=2 (rotating, audio-reactive) |
| 170 | Drop_and_Scatter | 4744 | Ted | rnd( 3 ) + rnd( 3 ) + rnd( 3 ) + 6 | 4 + rnd( 4 ) | Frame Fall -- connect=2 (randomized, rnd( 3 ) + rnd( 3 ) + rnd( 3 ) + 6-instance) |
| 171 | Fern | 4776 | Ted | 1 | 450 | iterated function system -- 2-fold dotted (audio-reactive, randomized) |
| 172 | Fireflies | 4832 | Ted | 1 | 55 | Orbiting Stars -- 3-fold connected (rotating, audio-reactive, pseudo-3D perspective) |
| 173 | Grapefruit | 4918 | Ted | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 174 | Inner_Spikes | 4944 | Ted | 1 | 4 * NumFftSteps | connected (rotating, audio-reactive) |
| 175 | Juggler | 4964 | Ted | 2+rnd(16) | 2 | Orbiting Rods -- connected (rotating, 2+rnd(16)-instance) |
| 176 | Morphagon | 4990 | Ted | 1 | 512 | 10-fold connected (audio-reactive, randomized, pseudo-3D perspective) |
| 177 | Orbiting_Stars | 5077 | Ted | 1 | 55 | 6-fold connected (rotating, audio-reactive, pseudo-3D perspective) |
| 178 | Outer_Spikes | 5187 | Ted | 1 | 512 | connected (rotating, audio-reactive) |
| 179 | Pinwheel | 5215 | Ted | 1 | 512 | 4-fold connected (audio-reactive, randomized) |
| 180 | Psychloids_II | 5237 | Ted | 2 | NumFftBins*flor(rnd(3)+3) | Cylinder Crown -- connected (rotating, audio-reactive, 2-instance) |
| 181 | Rhythm_Guppies | 5268 | Ted | 1 | NumFftBins | 4-fold dotted (audio-reactive, randomized) |
| 182 | Rosette | 5319 | Ted | trnc(rnd(2.99)+3)*2 | NumSampleBins/2 | Three's a Crowd,Hollow Horizontal -- connected (rotating, audio-reactive, trnc(rnd(2.99)+3)*2-instance) |
| 183 | Sci_Fi_Expander | 5363 | Ted | 1 | 512 | Sci-Fi Expander by Andy O'Meara -- 4-fold connected (rotating, audio-reactive) |
| 184 | Shivering_Weave | 5379 | -- | 2 + trnc( rnd( 4.99 ) ) | 512 | connected (audio-reactive, randomized, 2 + trnc( rnd( 4.99 ) )-instance) |
| 185 | Sierpinski | 5403 | Ted | 1 | 450 | iterated function system -- dotted (rotating) |
| 186 | Simple_Sine | 5450 | Ted | 1 | 512 | 2-fold connected (rotating, audio-reactive) |
| 187 | Square_Dance | 5466 | Ted | 4 | 13 | connected (rotating, 4-instance) |
| 188 | Tension_I | 5498 | Ted | 1 | NumFftBins | 4-fold connected (rotating, audio-reactive) |
| 189 | Tension_II | 5518 | Ted | 1 | NumFftBins | 6-fold connected (rotating, audio-reactive) |
| 190 | Trance_Snap | 5542 | Ted | flor(  rnd(  1.11111  )  )  +  1 | 512 | 4-fold connected (audio-reactive, randomized, flor(  rnd(  1.11111  )  )  +  1-instance) |
| 191 | Twizzler | 5594 | Ted | 1 | 512 | 4-fold connected (audio-reactive, randomized) |
| 192 | Walls_of_Sound | 5616 | Ted | 1 | NumFftBins | 12-fold connected (rotating, audio-reactive) |

#### Fields -- active shortlist (pixel/fieldShort.sky.h) -- 24 field functions

| # | Name | Line | Author | Warp | Math description |
|---|---|---|---|---|---|
| 1 | Ether Leak | 1 | Jay Protopapas | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 2 | Uber Incognito | 6 | Uberbach | GoXY | Cartesian warp |
| 3 | Gevian Rage | 14 | Demonseed | GoRT | Donut -- polar warp: radial zoom, angular spin |
| 4 | Disco Ball | 20 | Doug Fawley | GoRT | Burst -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 5 | D_Julia B | 29 | Mats Nordstrom | GoXY | Cartesian warp: complex-plane (Julia-like) iteration |
| 6 | Hip-no-Therapy | 38 | -- | GoRT | polar warp: radial zoom, angular spin |
| 7 | Poinsetta | 44 | Demonseed | GoRT | Boxilite -- polar warp: radial zoom, angular spin |
| 8 | Psilocybin Growth Formulae | 53 | Erich Kodotai | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 9 | Star of David | 63 | Jay Protopapas | GoRT | Thanks to Chris Sherrill -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 10 | Strangeitude | 73 | Erlend Robaye | GoDRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 11 | Warpo Tunnel | 86 | Chris Sherrill | GoRT | mysterious puddle -- polar warp: radial zoom, angular spin |
| 12 | Watery Ripples | 94 | -- | GoRT | polar warp: radial zoom, angular spin |
| 13 | Five Hole | 100 | Jay Protopapas | GoRT | Thanks to Erlend Robaye -- polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 14 | Gedenghi | 108 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 15 | Unfolding Before You) | 121 | Jay Protopapas | GoRT | Thanks to Thomas Geier -- polar warp: radial zoom, per-pixel jitter |
| 16 | Acid Flower | 129 | -- | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 17 | Collapsing  Sun | 139 | Chris Sherrill | GoRT | polar warp: radial zoom, per-pixel jitter |
| 18 | Pscyco Linear Spread | 146 | Chris Sherrill | GoXY | Cartesian warp |
| 19 | Smoke in the Mist | 152 | Chris Sherrill | GoXY | Cartesian warp: per-pixel jitter |
| 20 | Uber Concert | 158 | Uberbach | GoXY | Cartesian warp: per-pixel jitter |
| 21 | 6 Ft. Under | 167 | Demonseed | GoXY | Cartesian warp |
| 22 | g-life | 175 | Jay Protopapas | GoXY | Alife -- Cartesian warp: per-pixel jitter |
| 23 | Tripping Hard | 193 | Justin Swidler | GoRT | polar warp: radial zoom, angular spin |
| 24 | Lens Flare | 198 | Steve Wheeler | GoRT | polar warp |

#### Fields -- archive (mixed/general) (pixel/field_dir.sky.h) -- 107 field functions

| # | Name | Line | Author | Warp | Math description |
|---|---|---|---|---|---|
| 1 | Hyperbia | 1 | Ted | GoDRT | Hyperbolic Dreams, by Andy O -- polar warp: radial zoom, per-pixel jitter, 1-channel feedback |
| 2 | Chrysanthemum | 13 | Ted | GoDRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 3 | Curls | 23 | Ted | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 4 | Electric | 34 | Ted | GoXY | Cartesian warp: per-pixel jitter |
| 5 | Feathery | 43 | Ted | GoRT | polar warp: radial zoom, per-pixel jitter |
| 6 | Frosted | 52 | Ted | GoDXY | Cartesian warp: radial zoom, periodic ripple/kaleidoscope, per-pixel jitter |
| 7 | Glass Blocks | 61 | Ted | GoDXY | Cartesian warp: per-pixel jitter, 1-channel feedback |
| 8 | Honeycomb Alpha | 75 | Ted | GoXY | Cartesian warp: per-pixel jitter |
| 9 | Hubcap | 85 | Ted | GoDRT | Concentricity -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 10 | Hurry Up and Wait | 96 | Ted | GoRT | polar warp: angular spin, periodic ripple/kaleidoscope, per-pixel jitter |
| 11 | Inca Turtles | 105 | Ted | GoXY | Cartesian warp: per-pixel jitter |
| 12 | Interlock | 115 | Ted | GoXY | Cartesian warp: per-pixel jitter |
| 13 | Mitosis | 124 | Ted | GoD2XY | Cartesian warp: per-pixel jitter, 2-channel feedback |
| 14 | My Lost Marbles | 133 | Ted | GoDXY | Cartesian warp: per-pixel jitter, 1-channel feedback |
| 15 | Polar Tiles | 144 | Ted | GoDRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 16 | Polygon | 160 | Ted | GoD4XY | Cartesian warp: radial zoom, angular spin, per-pixel jitter |
| 17 | Spiral Shoals | 178 | Ted | GoD3RT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 18 | Spiraling | 189 | Ted | GoDRT | equiangular spiral -- polar warp: angular spin, per-pixel jitter, 1-channel feedback |
| 19 | Split and Twist | 202 | Ted | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 20 | Star Glass | 212 | Ted | GoD2RT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 21 | Tan Turn - Polar | 228 | Ted | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 22 | Turbulence | 240 | Ted | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 23 | Twisted Tiles | 249 | Ted | GoXY | HAL_Waves_Of_Grain -- Cartesian warp: per-pixel jitter |
| 24 | Walking Tiles Rotate | 262 | Ted | GoXY | Cartesian warp: per-pixel jitter |
| 25 | radius.E. Away From The Globe | 271 | Ryan Edwards | GoXY | From Ted -- Cartesian warp: radial zoom |
| 26 | radius.E. Coils | 276 | Ryan Edwards | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 27 | radius.E. Digital Staircase | 285 | Ryan Edwards | GoDXY | Cartesian warp: 1-channel feedback |
| 28 | radius.E. Flamin | 295 | Ryan Edwards | GoXY | Cartesian warp: radial zoom |
| 29 | radius.E. Fountain | 300 | Ryan Edwards | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 30 | radius.E. Glass Columns | 307 | Ryan Edwards | GoXY | Cartesian warp: per-pixel jitter |
| 31 | radius.E. Globe in the middle | 313 | Ryan Edwards | GoXY | Cartesian warp: per-pixel jitter |
| 32 | radius.E. Light Brush Strokes | 318 | Ryan Edwards | GoXY | Cartesian warp: radial zoom |
| 33 | radius.E. Nebula | 323 | Ryan Edwards | GoXY | A nebula that even has stars -- Cartesian warp |
| 34 | radius.E. Platforms of Heaven | 329 | Ryan Edwards | GoRT | polar warp: radial zoom, angular spin |
| 35 | radius.E. Rolling Waves | 339 | Ryan Edwards | GoDXY | Cartesian warp: 1-channel feedback |
| 36 | radius.E. Sides Up | 347 | Ryan Edwards | GoRT | polar warp: radial zoom, angular spin |
| 37 | radius.E. Spider Web | 358 | Ryan Edwards | GoXY | Cartesian warp: per-pixel jitter |
| 38 | radius.E. Spiral | 364 | Ryan Edwards | GoRT | polar warp: radial zoom, angular spin |
| 39 | radius.E. That | 376 | Ryan Edwards | GoDRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 40 | Thats Me | 384 | Ryan Edwards | GoXY | Cartesian warp |
| 41 | radius.E. Verdri Goood | 393 | Ryan Edwards | GoDRT | polar warp: per-pixel jitter, 1-channel feedback |
| 42 | radius.E. Whirlpool | 404 | Ryan Edwards | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 43 | JB1 - Tunnel | 413 | Jan Benz | GoXY | Cartesian warp |
| 44 | JB2 - Bubble Tunnel | 419 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 45 | JB3 | 425 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 46 | JB5 - Crafty Spread | 430 | Jan Benz | GoXY | Cartesian warp |
| 47 | JB9 - Quarters | 435 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 48 | JBa[0] - Wavy Diverge | 441 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 49 | JBa[1] - Diamonds | 447 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 50 | JBB1 - Diamond Tiled Tunnel | 452 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 51 | JBC1 | 458 | Jan Benz | GoDRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 52 | JBD1 - Dual Spirals | 466 | Jan Benz | GoDRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 53 | JBF0 | 474 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 54 | JBG0 | 479 | Jan Benz | GoDRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 55 | JBG1 - Waves | 488 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 56 | JBH0 | 495 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 57 | JBI0 | 501 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 58 | JBI1 - Theta Collapse | 506 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 59 | JBK1 - Sun Sine Ray | 514 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 60 | JBM0 | 521 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 61 | JBO1 - Bizarre Tiles | 528 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 62 | JBP0 | 534 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 63 | JBR0 - I Love to Burn | 540 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 64 | JBS0 | 547 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 65 | JBS1 - Bizzare Star | 556 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 66 | JBSL | 562 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 67 | JBV0 - Centrifugal | 570 | Jan Benz | GoDRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 68 | JBV1 - The Sun | 578 | Jan Benz | GoDXY | Cartesian warp: per-pixel jitter, 1-channel feedback |
| 69 | JBW0 - Wavy Converge | 587 | Jan Benz | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 70 | JBX0 - Organized Smoke | 593 | Jan Benz | GoXY | Cartesian warp: per-pixel jitter |
| 71 | HAL - Crop Circle | 600 | Howard A. Landman | GoRT | HAL_Waves_Of_Grain -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 72 | HAL - Crop Spiral | 621 | Howard A. Landman | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 73 | HAL - Dynamic | 645 | Howard A. Landman | GoXY | Cartesian warp: per-pixel jitter |
| 74 | HAL - Iris | 661 | Howard A. Landman | GoRT | polar warp: per-pixel jitter |
| 75 | HAL - Julia Seahorse | 669 | Howard A. Landman | GoXY | Cartesian warp: complex-plane (Julia-like) iteration |
| 76 | HAL - LDZ-04+131 | 705 | Howard A. Landman | GoDXY | Cartesian warp: 1-channel feedback |
| 77 | HAL - Paint Spinner | 741 | Howard A. Landman | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 78 | HAL - Puddle Pie | 749 | Howard A. Landman | GoRT | polar warp: radial zoom, angular spin |
| 79 | HAL - radius Chaos 2 | 771 | Howard A. Landman | GoRT | polar warp: radial zoom, angular spin |
| 80 | HAL - Sublime | 780 | Howard A. Landman | GoXY | Cartesian warp: per-pixel jitter |
| 81 | HAL - Waves Of Grain | 798 | Howard A. Landman | GoXY | Cartesian warp: per-pixel jitter |
| 82 | HAL - Weierstrauss Spread | 824 | Howard A. Landman | GoXY | Cartesian warp |
| 83 | EDP -- Aquarell | 844 | Erik Huizinga | GoXY | Cartesian warp: per-pixel jitter |
| 84 | EDP -- Magic Mirror | 850 | Erik Huizinga | GoXY | Cartesian warp: per-pixel jitter |
| 85 | E.radius. At the Oval Office | 857 | Erlend Robaye | GoDXY | Cartesian warp: per-pixel jitter, 1-channel feedback |
| 86 | E.radius. Mistify | 866 | Erlend Robaye | GoXY | Cartesian warp: per-pixel jitter |
| 87 | E.radius. Sauron | 874 | Erlend Robaye | GoD2XY | Cartesian warp: per-pixel jitter, 2-channel feedback |
| 88 | E.radius. Square Trails | 885 | Erlend Robaye | GoDXY | Cartesian warp: per-pixel jitter, 1-channel feedback |
| 89 | E.radius. Sunscape Twist | 894 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 90 | DT - Boxes | 914 | David Tryse | GoXY | Cartesian warp: per-pixel jitter |
| 91 | DT - Chaos | 923 | David Tryse | GoXY | Cartesian warp: per-pixel jitter |
| 92 | DT - Horizon | 929 | David Tryse | GoXY | Cartesian warp: per-pixel jitter |
| 93 | DT - Swirl | 939 | David Tryse | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 94 | DT - Tip | 949 | David Tryse | GoXY | Cartesian warp: per-pixel jitter |
| 95 | DT - Water | 960 | David Tryse | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 96 | DaveF-Cyclone Clouds | 971 | DaveF! | GoRT | MESS by Gwyn Perry -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 97 | DaveF-Diagonal Slice | 977 | DaveF! | GoXY | Diagonal slide -- Cartesian warp: per-pixel jitter |
| 98 | DaveF-Evacuate | 984 | DaveF! | GoRT | You are here -- polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 99 | DaveF-Hybiscus | 991 | DaveF! | GoRT | Inspired by Jan Benz -- polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 100 | DaveF-In the Ring | 998 | DaveF! | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 101 | DaveF-Lovely Darts | 1003 | DaveF! | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 102 | DaveF-Neucleus | 1009 | DaveF! | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 103 | DaveF-Rolling Hills | 1019 | DaveF! | GoXY | Cartesian warp: per-pixel jitter |
| 104 | DaveF-SmokeTornado | 1030 | DaveF! | GoRT | Inspired by Jan Benz -- polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 105 | DaveF-Swirlo | 1037 | DaveF! | GoRT | Starlight -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 106 | DaveF-WaveWorld | 1047 | DaveF! | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 107 | DaveF-You Are Here | 1056 | DaveF! | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |

#### Fields -- archive (polar-only) (pixel/field_rt.sky.h) -- 88 field functions

| # | Name | Line | Author | Warp | Math description |
|---|---|---|---|---|---|
| 1 | Directrix Expand Y | 1 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 2 | Directrix Expand X | 10 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 3 | Collapse & turn | 20 | -- | GoRT | polar warp: radial zoom, angular spin |
| 4 | Ether Leak | 26 | Jay Protopapas | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 5 | Concentricity | 32 | lunabunny | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 6 | Collapsing  Sun | 41 | Chris Sherrill | GoRT | polar warp: radial zoom, per-pixel jitter |
| 7 | Cloverleaf | 49 | Jay Protopapas | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 8 | Claustrophobia | 57 | Thomas Geier | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 9 | Bruce | 67 | Jay Protopapas | GoRT | Thanks to Dave F -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 10 | Birth of the Sea | 75 | Jay Protopapas | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 11 | angantyr antigravity well | 82 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 12 | Alan 1 | 91 | Andy O | GoDRT | polar warp: per-pixel jitter, 1-channel feedback |
| 13 | Angel's Caress | 106 | Demonseed | GoD2RT | Galaxy & Swirl Your Mind -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 14 | Acid Flower | 119 | -- | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 15 | Vaporize | 130 | Mike Thiesen | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 16 | (DJK)TraverseAmbit | 136 | Djknowone | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 17 | GlassFiver Twist | 145 | Erlend Robaye | GoD2RT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 18 | Glassfiber Realm | 166 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 19 | Get Smart | 178 | Jay Protopapas | GoRT | Thanks to Demonseed -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 20 | Gedenghi | 185 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 21 | Flower Power Flow | 199 | Thomas Geier | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 22 | FiberOptic Nerve | 210 | Jay Protopapas | GoRT | Thanks to Steve Wheeler -- polar warp: radial zoom, per-pixel jitter |
| 23 | Five Hole | 219 | Jay Protopapas | GoRT | Thanks to Erlend Robaye -- polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 24 | Expand and Turn | 228 | -- | GoRT | polar warp: angular spin |
| 25 | Event Horizon | 234 | Erlend Robaye | GoD2RT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 26 | Escher Swirls | 255 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 27 | Equalateral Hyperbola | 268 | -- | GoRT | polar warp: radial zoom, angular spin |
| 28 | Echo | 274 | Demonseed | GoRT | Contrail  by Andy -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 29 | Donut | 280 | -- | GoRT | polar warp: radial zoom, angular spin |
| 30 | Gevian Rage | 286 | Demonseed | GoRT | Donut -- polar warp: radial zoom, angular spin |
| 31 | Disco Ball | 292 | Doug Fawley | GoRT | Burst -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 32 | Constant Out | 302 | -- | GoRT | polar warp: radial zoom |
| 33 | Yes | 308 | Thomas Geier | GoRT | polar warp: radial zoom |
| 34 | Wormhole | 315 | lunabunny | GoDRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 35 | Wild Fire | 325 | Demonseed | GoRT | polar warp: radial zoom, angular spin |
| 36 | whoo-Whoo! | 331 | Jay Protopapas | GoRT | polar warp: per-pixel jitter |
| 37 | Watery Ripples | 339 | -- | GoRT | polar warp: radial zoom, angular spin |
| 38 | Warpo Tunnel | 344 | Chris Sherrill | GoRT | mysterious puddle -- polar warp: radial zoom, angular spin |
| 39 | Unfolding Before You) | 352 | Jay Protopapas | GoRT | Thanks to Thomas Geier -- polar warp: radial zoom, per-pixel jitter |
| 40 | UnFocused | 360 | Demonseed | GoRT | Donut -- polar warp: radial zoom, per-pixel jitter |
| 41 | UFO | 366 | Demonseed | GoRT | Direct X Expand - Y -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 42 | Uber Supernova | 376 | Uberbach | GoRT | polar warp: radial zoom, periodic ripple/kaleidoscope |
| 43 | Twister | 382 | Kasuha | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 44 | Tunnel Vision | 391 | Angelseed | GoRT | Flying Fast Through a Tunnel -- polar warp: per-pixel jitter |
| 45 | Tripping Hard | 399 | Justin Swidler | GoRT | polar warp: radial zoom, angular spin |
| 46 | TimeWarp | 405 | Justin and Jesse Swidler | GoRT | polar warp: angular spin |
| 47 | Time | 413 | Steve Wheeler | GoRT | polar warp: radial zoom, per-pixel jitter |
| 48 | Time Portal | 421 | Demonseed | GoRT | Tan Turn -- polar warp: radial zoom, angular spin |
| 49 | Theta Divergence | 427 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 50 | The Randomizer Speaks | 437 | Erich Kodotai | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 51 | The MAW | 445 | Steve Wheeler | GoRT | polar warp: radial zoom, angular spin |
| 52 | Sunscape | 454 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 53 | Sunburst | 462 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 54 | Dreamscape | 471 | Demonseed | GoRT | Sunburst - Many -- polar warp: angular spin, per-pixel jitter |
| 55 | Dreamscape 3 | 481 | Demonseed | GoD2RT | Based on Sunburst - Many -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 56 | Strangeitude | 500 | Erlend Robaye | GoDRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 57 |  | 514 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 58 | Star | 524 | Erlend Robaye | GoDRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 59 | Star of David | 538 | Jay Protopapas | GoRT | Thanks to Chris Sherrill -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 60 | Sparkle & Fade | 548 | Steve Wheeler | GoRT | Nothing Lasts forever -- polar warp: radial zoom, per-pixel jitter |
| 61 | Sincos | 556 | -- | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 62 | Sphere | 564 | -- | GoRT | polar warp: radial zoom, angular spin |
| 63 | Serendipity0 | 570 | lunabunny | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 64 | See Spot | 579 | Steve Wheeler | GoRT | polar warp: radial zoom, angular spin |
| 65 | Scattered Sunburst | 587 | Demonseed | GoRT | polar warp: radial zoom, angular spin |
| 66 | Scattered Flow Out | 593 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 67 | Scattered Flow In | 598 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 68 | Scatter Burst | 603 | Demonseed | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 69 | Sandstorm0 | 610 | Steve Wheeler | GoRT | polar warp: radial zoom, per-pixel jitter |
| 70 | Rotating Sun | 618 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 71 | Rotating Blob | 636 | Erlend Robaye | GoDRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 72 | Right Turn | 649 | -- | GoRT | polar warp: radial zoom, angular spin |
| 73 | Radial Madness IV | 655 | Erlend Robaye | GoRT | polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 74 | Radial Breakaway | 667 | -- | GoRT | polar warp: radial zoom, angular spin |
| 75 | Quantum Theta | 673 | Andy | GoRT | Spinner -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 76 | Quantum Ripple | 684 | DJ Alter-N8 | GoRT | Quantum Theta -- polar warp: radial zoom, angular spin, per-pixel jitter |
| 77 | Pyscho Disco Ball | 695 | -- | GoRT | polar warp: radial zoom, angular spin |
| 78 | Psychedelic Sunburst | 700 | -- | GoRT | polar warp: radial zoom, angular spin |
| 79 | Psilocybin Growth Formulae | 706 | Erich Kodotai | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 80 | n Or Out, Inner Turn | 716 | -- | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 81 | Nexus-One | 734 | Demonseed | GoRT | Thick River -- polar warp: radial zoom, angular spin |
| 82 | Lens Flare | 740 | Steve Wheeler | GoRT | polar warp |
| 83 | Lava Kava | 749 | -- | GoRT | Many Thanks to Erlend Robaye -- polar warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 84 | Left Turn and Flow Out | 761 | -- | GoRT | polar warp: radial zoom, angular spin |
| 85 | I Am Tetsuo | 768 | Steve Wheeler | GoRT | polar warp: angular spin |
| 86 | Hip-no-Therapy | 778 | -- | GoRT | polar warp: radial zoom, angular spin |
| 87 | Great Minds | 784 | Demonseed | GoRT | polar warp: radial zoom, angular spin, per-pixel jitter |
| 88 | Gravity Ball | 791 | Justin Swidler | GoRT | polar warp: radial zoom |

#### Fields -- archive (Cartesian-only) (pixel/field_xy.sky.h) -- 45 field functions

| # | Name | Line | Author | Warp | Math description |
|---|---|---|---|---|---|
| 1 | D_Julia B | 1 | Mats Nordstrom | GoXY | Cartesian warp: complex-plane (Julia-like) iteration |
| 2 | ClusterSwirlz | 9 | Jay Protopapas | GoXY | Cartesian warp |
| 3 | Swirly | 15 | August Schack | GoD8XY | Cartesian warp: per-pixel jitter, 8-channel feedback |
| 4 | Blaze | 50 | Jay Protopapas | GoXY | Thanks to Thomas Geier -- Cartesian warp: radial zoom, periodic ripple/kaleidoscope, per-pixel jitter |
| 5 | Bits Between bits | 56 | Erlend Robaye | GoXY | October 2001 -- Cartesian warp |
| 6 | Act Of Love | 67 | Demonseed | GoD2XY | Galaxy & Swirl Your Mind -- Cartesian warp: radial zoom, angular spin, per-pixel jitter |
| 7 | 6 Ft. Under | 80 | Demonseed | GoXY | Cartesian warp |
| 8 | (DJK)Lemming's Water | 89 | DJKnowone | GoXY | Cartesian warp: per-pixel jitter |
| 9 | g-life | 102 | Jay Protopapas | GoXY | Alife -- Cartesian warp: per-pixel jitter |
| 10 | Freezymelt | 141 | -- | GoXY | Cartesian warp: per-pixel jitter |
| 11 | Frontal Lobe | 147 | Erich Kodotai | GoXY | A phorm of the Julia fractal -- Cartesian warp: per-pixel jitter |
| 12 | Fractal Sweetness | 154 | Caleb Mulford | GoXY | Cartesian warp |
| 13 | Flee | 160 | Thomas Geier | GoXY | Cartesian warp: per-pixel jitter |
| 14 | Flamin Ice Cubes | 169 | -- | GoXY | Cartesian warp |
| 15 | Far Reaching | 174 | -- | GoD2XY | Cartesian warp: 2-channel feedback |
| 16 | Eyes | 183 | by Kasuha | GoD3XY | Cartesian warp: per-pixel jitter, 3-channel feedback |
| 17 | Drawn & Quartered | 197 | Demonseed | GoXY | A pull from the center out -- Cartesian warp: per-pixel jitter |
| 18 | Do not adjust your sets | 204 | Chris Sherrill | GoXY | Cartesian warp: per-pixel jitter |
| 19 | Directed Spread | 219 | -- | GoXY | Cartesian warp: per-pixel jitter |
| 20 | Diamond0 | 232 | Caleb Mulford | GoXY | Cartesian warp: radial zoom |
| 21 | Contrail | 238 | Andy | GoXY | Cartesian warp: per-pixel jitter |
| 22 | Wrap Your Brain Around This | 249 | Brad Anderson | GoXY | Cartesian warp |
| 23 | Whirlpool in the Waves | 258 | -- | GoXY | Cartesian warp: per-pixel jitter |
| 24 | Waterfall Of Life | 267 | Demonseed | GoXY | Quantum Theta  by Andy -- Cartesian warp: per-pixel jitter |
| 25 | Uber Incognito | 278 | Uberbach | GoXY | Cartesian warp |
| 26 | Uber Focus | 287 | Uberbach | GoD3XY | Cartesian warp: per-pixel jitter, 3-channel feedback |
| 27 | Uber Concert | 296 | Uberbach | GoXY | Cartesian warp: per-pixel jitter |
| 28 | Tropic Of Capricorn | 304 | E. Kodotai | GoXY | Cartesian warp: per-pixel jitter |
| 29 | Traffic Flow | 312 | -- | GoXY | Cartesian warp: per-pixel jitter |
| 30 | Thick River | 321 | -- | GoXY | Cartesian warp |
| 31 | Thick River | 327 | -- | GoXY | Cartesian warp |
| 32 | Tan Turn | 333 | -- | GoXY | Cartesian warp |
| 33 | St. Elmo's Fire | 340 | lunabunny | GoXY | Cartesian warp: per-pixel jitter |
| 34 | SOLs Tinsle | 348 | Brad Anderson | GoXY | Cartesian warp: per-pixel jitter |
| 35 | Sound of Lights Point and Hang | 355 | Brad Anderson | GoXY | Cartesian warp: per-pixel jitter |
| 36 | Smoke in the Mist | 365 | Chris Sherrill | GoXY | Cartesian warp: per-pixel jitter |
| 37 | quadrophilia | 371 | Jay Protopapas | GoXY | Cartesian warp: radial zoom, angular spin, periodic ripple/kaleidoscope |
| 38 | Pscyco Linear Spread | 377 | Chris Sherrill | GoXY | Cartesian warp |
| 39 | Once Upon a Time | 383 | Thomas Geier | GoXY | Cartesian warp |
| 40 | Nowhere | 389 | -- | GoXY | Cartesian warp |
| 41 | Lucretia | 395 | lunabunny | GoXY | Cartesian warp: per-pixel jitter |
| 42 | D_Julia B | 403 | Mats Nordstrom | GoXY | Cartesian warp: complex-plane (Julia-like) iteration |
| 43 | MESS | 412 | Gwyn Perry | GoXY | ANIMATION STUDENT AT UWCN -- Cartesian warp: per-pixel jitter |
| 44 | Gravity | 418 | -- | GoXY | Cartesian warp: per-pixel jitter |
| 45 | Gail Force Winds | 424 | Demonseed | GoXY | Gravity -- Cartesian warp: per-pixel jitter |