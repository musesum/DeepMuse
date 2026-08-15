# Port/Integration.md — add ONE new cell rule end-to-end

Worked example: adding a hypothetical rule named `wave`
(metal file `cell.rule.wave.metal`, kernel `waveKernel`).

## Kernel signature convention (invariant across all `cell.rule.*.metal`)

```metal
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

kernel void waveKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],   // input  = pipe.cell.real
 texture2d<half, access::write> outTex  [[ texture(1) ]],   // output = pipe.cell.out
 constant float&                version [[ buffer(0)  ]],   // rule variant knob
 uint2 gid [[thread_position_in_grid]])
{
    const uint xs = outTex.get_width();    // grid W (pipeSize 2048)
    const uint ys = outTex.get_height();   // grid H (pipeSize 2048)
    // read neighbors from inTex.read(uint2).b  (0…1 → ×255/256 for cell state)
    // ... rule math, may use `version` for variant selection ...
    // pack: fb=cell value, fg=255-value, (fa<<8)+fr = HiC high counter
    outTex.write(half4(fr,fg,fb,fa), gid);
}
```

Invariants (verified across fred/slide/ave/zha/fade/melt/tunl/mod/erode):
- **texture(0)** = read input, **texture(1)** = write output.
- **buffer(0)** = `constant float& version`. This is the ONLY buffer CellNode
  binds. (`cell.rule.melt.metal:13` declares `buffer(1) bits` but it is never
  bound — do not rely on buffers > 0 without also editing CellNode.)
- **`uint2 gid [[thread_position_in_grid]]`** — no threadgroup uniform struct;
  no `MetalShaderTypes.h` uniform is used by cell rules.
- Pixel type may be `half` or `float` (both appear); texture format is
  `MuComputePixelFormat = .bgra8Unorm` (`Mu/MuVision/.../Extensions/MTL+ext.swift:10`),
  presented as RGBA in-shader.
- Toroidal neighbor indexing (n/s/e/w[/nw/ne/se/sw]) is hand-rolled per kernel
  via the `ew/ns/nwsw/nese` macro block (copy from `cell.rule.fred.metal:21-77`).
- State packing (`.b` primary, `.g` inverse, `.r`+`.a` HiC) is a convention, not
  enforced — match it so `pipe.color` mapping reads sane values.

### Threadgroup dispatch (fixed, in CellNode's superclass)

`Mu/MuVision/.../Pipeline/ComputeNode.swift:40-47`:
```
threadSize  = 16 × 16 × 1
threadCount = ⌈W/16⌉ × ⌈H/16⌉ × 1     // 128×128 at pipeSize 2048
encoder.dispatchThreadgroups(threadCount, threadsPerThreadgroup: threadSize)
```
No kernel-side action needed; new rules inherit this dispatch.

### Ping-pong texture mechanism

`Mu/MuVision/.../Pipeline/CellNode.swift:52-68`:
```
version˚.updateMtlBuffer(); encoder.setBuffer(version˚, index: 0)
encoder.setTexture(realTex˚, index: 0)   // input
encoder.setTexture(outTex˚,  index: 1)   // output
super.computeShader(encoder)             // dispatch pass 1
// optional extra passes when loops > 0:
for counter in 1...loops {
    encoder.setTexture(fakeTex˚, index: (counter+0)%2)
    encoder.setTexture(outTex˚,  index: (counter+1)%2)
    super.computeShader(encoder)
}
```
Texture bind paths resolve via `superBindPath` (`CellNode.swift:23-27`):
`fake`,`real`,`out` resolve at the shared **`pipe.cell`** scope;
`version`,`loops` resolve at the per-rule leaf. A new rule reuses the shared
`pipe.cell.fake/real/out` textures and only supplies its own `version`/`loops`.

## Flo path root / current naming (destination)

- Flo tree root object = `Flo("√")` (`Deep/Muse/Sky/SkyModel.swift:54`).
- **No `SW` flo node exists.** "SW" in code = menu quadrant South-West
  (`RootVm([.S,.W,.L])`, `Mu/MuMenu/.../Menu/Menus.swift:45`), whose branch
  `WNames` contains the string `"cell"` (`Menus.swift:41`).
- Two distinct `cell` nodes:
  1. **Menu tree** top-level node `cell` — from `Resources/cell.flo.h`, loaded
     as script `"cell"` (`Deep/Muse/Sky/SkyArchive.swift:12,14`). Holds the
     visible sliders; each binds to the pipeline via `<> pipe.cell˚<rule>.version`.
  2. **Pipeline tree** node `pipe.cell` with child subtree
     **`pipe.cell.rule.<name>`** — from `Resources/pipe.flo.h:13-28`. Each rule
     leaf declares `version` + `loops` buffers.
- The `˚` operator = find-descendant: `pipe.cell˚slide` ⇒ `pipe.cell.rule.slide`;
  `pipe.cell.rule˚loops` ⇒ every `loops` under `rule`.
- Solo/auto-switch semantics (`pipe.flo.h:25-26`): `*(-> *(on 0))` solos one
  rule; `˚version(-> ..(on 1))` turns a rule `on` when its `version` changes.

## The 5 edit sites to add rule `wave`

### 1. Metal kernel (create file)
`/Users/warren/Dev/Deep/Deep/Muse/Metal/cell.rule.wave.metal` — kernel
`waveKernel`, signature above.

### 2. Xcode target membership (project.pbxproj)
Mechanism = **explicit `PBXFileReference` + `PBXBuildFile` pairs** (NO
`PBXFileSystemSynchronizedRootGroup`; no folder reference). File:
`/Users/warren/Dev/Deep/Deep/Muse/DeepMuse.xcodeproj/project.pbxproj`.
Four insertions, mirroring `cell.rule.fred.metal`:

- **PBXBuildFile** (near line 26):
  ```
  <UID_A> /* cell.rule.wave.metal in Sources */ = {isa = PBXBuildFile; fileRef = <UID_B> /* cell.rule.wave.metal */; };
  ```
  existing analog: `project.pbxproj:26`
  ```
  806B2DDB2C2CED5D0054C979 /* cell.rule.fred.metal in Sources */ = {isa = PBXBuildFile; fileRef = 806B2DCD2C2CED5D0054C979 /* cell.rule.fred.metal */; };
  ```
- **PBXFileReference** (near line 82):
  ```
  <UID_B> /* cell.rule.wave.metal */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.metal; path = cell.rule.wave.metal; sourceTree = "<group>"; };
  ```
  existing analog: `project.pbxproj:82`
- **PBXGroup children** (near line 185, the Metal group):
  ```
  <UID_B> /* cell.rule.wave.metal */,
  ```
  existing analog: `project.pbxproj:185`
- **PBXSourcesBuildPhase files** (near line 322):
  ```
  <UID_A> /* cell.rule.wave.metal in Sources */,
  ```
  existing analog: `project.pbxproj:322`

`<UID_A>`/`<UID_B>` = two fresh 24-hex-char IDs. (Metal shaders compile into the
app's `.metallib`; `Shader.makeLibrary` also has a runtime-source fallback
`MuVision.read(fileName,"metal")` — but cell rules ship precompiled, so target
membership is required.)

### 3. MuSky/MuVision Swift registration (TWO switch sites)
- **`Deep/Muse/Sky/SkyPipeline.swift:45-46`** — add `"wave"` to the case that
  routes flo node names to `CellNode`:
  ```
  case "slide","zha","ave","fade","melt","tunl","fred","wave"
      : pipeNode = CellNode(self, flo˚)
  ```
- **`Mu/MuVision/Sources/MuVision/Pipeline/CellNode.swift:29-38`** — add the
  name → (file, kernel) mapping:
  ```
  case "wave" : shader = Shader(pipeline, file: "cell.rule.wave", kernel: "waveKernel")
  ```

> **Superseded — see "2026-07-11 restructure" below.** This 2-site pattern
> covers a GATHER-style rule that reuses `CellNode`'s fixed 16×16 full-frame
> dispatch. The `wave` rule actually shipped is a SCATTER kernel (1D,
> `uniforms.num` threads) and does not fit that shape: it registers as its
> own `PipeNode` subclass (`WaveNode`) in `SkyPipeline.swift`'s switch, not
> as an added `CellNode.swift` case. `shape` and `field` followed the same
> own-subclass path for the same reason (per-kernel buffer(1) subsets /
> algo-selected pipeline states, not a single fixed kernel).

### 4. Pipeline flo leaf (pipe.cell.rule.wave)
`/Users/warren/Dev/Deep/Mu/MuSky/Sources/MuSky/Resources/pipe.flo.h:24` (append
after `fred`, before the `*`/`˚version` lines 25-26):
```
wave (on 0) { version (buffer, x 0…3 : 0)   loops (buffer, y 0…32=0) }
```
`version` range/default defines the variant knob; `loops` defines extra passes.

### 5. Menu node + icon (cell.flo.h)
`/Users/warren/Dev/Deep/Mu/MuSky/Sources/MuSky/Resources/cell.flo.h:37` (append
inside the `cell { }` block):
```
wave ('Cellular Automata Wave rule',
      seg, x 0_3=0,           // seg=segmented; use `val, x 0…1=…` for a slider
      img "icon.cell.wave",
      <> pipe.cell˚wave.version)
```
**Menu icon requirement:** `img "icon.cell.wave"` must resolve to an imageset in
`/Users/warren/Dev/Deep/Mu/MuSky/Sources/MuSky/Resources/Sky.xcassets/`
(pattern: `icon.cell.<name>.imageset/`, mirror `icon.cell.fred.imageset/`).
Missing icon degrades gracefully but shows blank; SF-symbol fallback map is
`Mu/MuMenu/.../Icon/IconView.swift:16` (`"icon.cell"` only, not per-rule).

## Cross-reference index — every mention of cell paths (feeds SW.cell→SW.rule rename)

### flo scripts (`Mu/MuSky/Sources/MuSky/Resources/`)
| file:line | reference | which `cell` |
|---|---|---|
| `cell.flo.h:1` | `cell (columns 2, svg …) {` | menu node decl |
| `cell.flo.h:6` | `<> pipe.cell˚slide.version` | menu→pipe bind |
| `cell.flo.h:11` | `<> pipe.cell˚zha.version` | menu→pipe bind |
| `cell.flo.h:16` | `<> pipe.cell˚ave.version` | menu→pipe bind |
| `cell.flo.h:21` | `<> pipe.cell˚fade.version` | menu→pipe bind |
| `cell.flo.h:26` | `<> pipe.cell˚melt.version` | menu→pipe bind |
| `cell.flo.h:31` | `<> pipe.cell˚tunl.version` | menu→pipe bind |
| `cell.flo.h:36` | `<> pipe.cell˚fred.version` | menu→pipe bind |
| `pipe.flo.h:4` | `in (texture, <- cell.out)` | pipe.draw ← cell.out |
| `pipe.flo.h:13` | `cell (on 1) {` | pipe.cell node decl |
| `pipe.flo.h:14` | `fake (texture, <- draw.out)` | pipe.cell.fake |
| `pipe.flo.h:15` | `real (texture, <- (draw.out, camera.out))` | pipe.cell.real |
| `pipe.flo.h:16` | `out (texture)` | pipe.cell.out |
| `pipe.flo.h:17` | `rule (on 1) {` | pipe.cell.rule subtree |
| `pipe.flo.h:18-24` | `slide/zha/ave/fade/melt/tunl/fred (on …){version loops}` | 7 rule leaves |
| `pipe.flo.h:25` | `*(-> *(on 0))` | rule solo wire |
| `pipe.flo.h:26` | `˚version(-> ..(on 1))` | version→auto-on wire |
| `pipe.flo.h:30` | `in (texture, <- (camera.out, cell.out))` | pipe.color ← cell.out |
| `camera.flo.h:23` | `<> (pipe.camix.mixcam, pipe.cell.rule˚loops)` | camera mix.y → all loops |

### Swift + assets
| file:line | reference |
|---|---|
| `Deep/Muse/Sky/SkyPipeline.swift:45-46` | `case "slide","zha","ave","fade","melt","tunl","fred": CellNode` |
| `Mu/MuVision/.../Pipeline/CellNode.swift:29-38` | switch `pipeFlo˚.name` → `Shader(file:"cell.rule.<n>", kernel:"<n>Kernel")` |
| `Deep/Muse/Sky/SkyArchive.swift:12` | `scriptNames = […,"cell",…]` (visionOS) |
| `Deep/Muse/Sky/SkyArchive.swift:14` | `scriptNames = […,"cell",…]` (iOS) |
| `Mu/MuMenu/.../Menu/Menus.swift:30` | `vNames [ … "cell" … ]` (visionOS) |
| `Mu/MuMenu/.../Menu/Menus.swift:35` | `vNames [ … "cell" … ]` (iOS) |
| `Mu/MuMenu/.../Menu/Menus.swift:41` | `WNames = [ … "cell" … ]` (SW branch) |
| `Mu/MuMenu/.../Icon/IconView.swift:16` | `"icon.cell": "circle.grid.3x3.fill"` (SF fallback) |
| `Sky.xcassets/icon.cell.<rule>.imageset/` | 9 per-rule menu icons (ave/brush/drift/fade/fred/gas/melt/mod/pixsort/scroll/slide/tunl/zha) |

Rename note: renaming the **menu** `cell` node → `rule` touches `cell.flo.h:1`,
the file name `cell.flo.h`→`rule.flo.h`, `SkyArchive.swift:12,14` ("cell"→"rule"
in scriptNames), `Menus.swift:30,35,41` ("cell"→"rule"), and `IconView.swift:16`
key. The **pipeline** `pipe.cell` node is separate; its rename would additionally
touch every `pipe.cell…` binding in `cell.flo.h`, `pipe.flo.h`, `camera.flo.h`
listed above, plus the `CellNode` file-name strings.

> **Outcome — see "2026-07-11 restructure" below.** The rename was tried
> (`cell.flo.h` → `rule.flo.h`) and reverted. New menu content lives under a
> nested `more { field wave rules shapes }` branch inside the existing `cell`
> node instead; `cell.flo.h`, `scriptNames`, `WNames`/`vNames` all still say
> `"cell"`.

## Headless flo parse-validation (MuFlo)

No CLI / executable target in MuFlo (`Package.swift` = 1 library + 1 testTarget).
Validation is via the test target using the parser directly:
- API: `FloParse().parseRoot(Flo("√"), scriptString) -> Bool`, then compare
  `root.scriptAll` with `Parsin.testCompare(expected, actual)`.
- Reference test: `Mu/MuFlo/Tests/MuFloTests/MuFloTests.swift:1155` (`testExpr8`)
  parses a cell-shaped script
  `slide(pipe 1, file "kernel.cell.slide", kernel "slideKernel") { version(buffer_0, x 0…7 : 3) loops(y 0…20) }`.
- Run headless: `cd /Users/warren/Dev/Deep/Mu/MuFlo && swift test`
  (or `swift test --filter MuFloTests.testExpr8`).
- Note: `testExpr8` demonstrates an alternate flo style where the node itself
  carries `file`/`kernel`/`pipe` attributes. DeepMuse's live `pipe.flo.h` does
  NOT use this; it relies on the hard-coded `CellNode.swift` switch instead. A
  ported rule may be validated syntactically by feeding the new `pipe.flo.h`
  block through `parseRoot`, but the file→kernel binding is only exercised at
  app runtime, not by the parser.

---

## 2026-07-11 restructure

Status: implemented, build green, simulator-validated (see "Verification"
below). Supersedes the worked-example/rename-note assumptions above where
noted; original sections left intact as history.

### Menu script reverted to `cell.flo.h`

`rule.flo.h` (see Rename note, §"Flo path root") was tried and reverted back
to `cell.flo.h`. Current tree, `Mu/MuSky/Sources/MuSky/Resources/cell.flo.h`:
```
cell { slide zha ave fade melt tunl fred,
       more("…") { field("F") wave("W") rules("R") shapes("S") } }
```
All new WinSky-port content (field/wave/rules/shapes) lives under the 8th
`more` child, not as top-level `cell` siblings. The four new branches use
`text` letter icons (`MuMenu.IconType.text`), not `img`/`svg`. `happy` is
absent from the menu. `SkyArchive.swift:12,14` `scriptNames` and
`Menus.swift:30,35,41` `WNames`/`vNames` still read `"cell"` — no rename
propagated.

### MuMenu constraint (root cause of a previously reported bug)

`MenuTree.makeOptionalControl()` (`Mu/MuMenu/Sources/MuMenu/Node/
MenuTree.swift:72`) emits a control leaf beside non-leaf siblings when a flo
node carries **both** value exprs and children. Menu branch nodes must be
homogeneous: a branch is either a control leaf or a pure container, never
both. Consequence: no menu branch node in `cell.flo.h` carries value exprs
directly — `field`/`wave`/`rules`/`shapes` (and `more` itself) are pure
containers; every selectable value is a leaf underneath.

### Pipeline registration: `shape`/`wave`/`field` are NOT `CellNode` cases

Contrary to the §3 worked example above, none of the three new subsystems
extend `CellNode.swift`'s per-name kernel switch. Each registers as its own
`PipeNode` subclass directly in `SkyPipeline.swift:45-50`:
```
case "slide","zha","ave","fade","melt","tunl","fred",
     "drift","warren","noise"          : pipeNode = CellNode  (self, flo˚)
case "shape"                           : pipeNode = ShapeNode (self, flo˚)
case "wave"                            : pipeNode = WaveNode  (self, flo˚)
case "field"                           : pipeNode = FieldNode (self, flo˚)
```
`"happy"` was removed from this switch (and from `pipe.flo.h` and
`cell.flo.h`); `cell.rule.happy.metal` and `CellNode.swift`'s `"happy"` case
remain in the tree, unwired — same precedent as `erode`/`mod`.

- **`shape`** (`Mu/MuVision/Sources/MuVision/Pipeline/ShapeNode.swift`, new)
  merges the four former hybrid rules `simple`/`spiral`/`circle`/`floral`
  into one `pipe.cell.rule.shape` node. `version` (buffer 0…5) selects the
  `simple` preset; `algo` (0…3) selects spiral/circle/floral's compute
  pipeline state at dispatch time; each kernel gets its own `buffer(1)` float
  subset (spiral 5 fields / circle 6 / floral 23, floral gated by
  `randomOn`). Uses the same `fake`/`real`/`out`/loops textures and loop
  mechanism as `CellNode`, including the loop-count snapshot fix (`loopCount`
  read once before the dispatch loop, since the flo closure can mutate
  `loops` off the encode thread). `CellNode.swift`'s own
  `simple`/`spiral`/`circle`/`floral` cases are left in place, dormant —
  `SkyPipeline` no longer routes those names to `CellNode`.
- **`wave`** — see `B3.waves.notes.md`'s "2026-07-11 correction" section for
  the uniform-layout and dispatch changes; registration-level summary here:
  own `WaveNode` class, 1D scatter dispatch, not `CellNode`.
- **`field`** — own `FieldNode` class (not detailed further here; no
  divergence from `B4.fields.notes.md` was reported).

### Wave pipe leaf: `ux`/`uy`/`num` merged into `uxyn`

The worked-example-style separate scalar leaves are not what shipped. Actual
`pipe.flo.h` leaf:
```
wave (on 0) { version (buffer, x 0…1 : 0)
              algo (buffer, x 0…67 : 0)
              uxyn (x -1…1=0, y -1…1=0, z 1…4096=100)
              ur (x -1…1=0) ua (x -1…1=0)
              seed (buffer, x 0…1000000 : 0) }
```
`uxyn` is one `xyz`-typed leaf (`x`=ux, `y`=uy, `z`=num, num clamped ≥1); the
menu leaf under `more.wave` is typed `xyz` to match. `WaveNode` reads
`uxyn˚?.xyz` and takes `.z` as `num`. `WaveUniforms`' 44-byte buffer(0)
layout is unchanged (`ux`/`uy`/`num` are still three separate float fields
in the Metal struct — only the flo-leaf/menu surface merged, not the GPU
struct).

### New pipe activation edge

`pipe.flo.h`'s `rule` node gained a second auto-activation wire beside
`˚version(-> ..(on 1))`:
```
˚algo(-> ..(on 1)) // touching an `algo` selector auto switches rule
```
Touching an `algo` leaf (shape/wave/field all have one; the seven legacy
rules do not) solo-activates its rule the same way touching `version` always
did.

### Threadgroup dispatch: `WaveNode` adds a second dispatch path

The "Threadgroup dispatch" section above (fixed 16×16 `dispatchThreadgroups`
in `ComputeNode.swift:40-47`) still describes `CellNode`'s (and `ShapeNode`'s
and `FieldNode`'s) full-frame gather dispatch unchanged. `WaveNode` does not
use it — it dispatches its own 1D `uniforms.num`-thread scatter in
`WaveNode.computeShader`, and that new path hit two Metal API defects, both
found by adversarial review plus `MTL_DEBUG_LAYER=1` validation on
simulator, both fixed:
1. `dispatchThreads` (non-uniform threadgroups) is unsupported on the
   simulator feature set. Fixed to uniform `encoder.dispatchThreadgroups`
   with a round-up (`(num + tgWidth - 1) / tgWidth` groups); the kernel
   already guarded `gid >= num`, so the padding threads are inert.
2. `access::read_write` on a `bgra8Unorm` texture argument fails
   `validateComputeFunctionArguments`. Fixed by splitting `waveKernel`'s
   texture arg into `access::read` at `texture(0)` and `access::write` at
   `texture(1)`; `WaveNode` binds `pipe.cell.out` to **both** slots so each
   thread still reads-then-writes its own point in place. `wsWritePoint`'s
   signature changed accordingly, from one `read_write` texture to
   `(texIn, texOut)`.

### `logShader` override

`WaveNode`/`ShapeNode`/`FieldNode` all now override `logShader` (the
`CellNode` idiom two sections up) so the per-frame 🚰 chain log shows them.
`WaveNode`'s override logs `(⟲addr)` in place (single texture, no
ping-pong) rather than the `(in⟶out)` form the gather nodes use.

### Verification

Three simulator runs, zero Metal API-validation assertions:
- wave-only chain: `draw ⟹ wave(⟲…) ⟹ color`
- shape-only chain, `algo=3` (floral): `draw ⟹ shape(…⟶…) ⟹ color`
- baseline `slide` chain (regression check on the unmodified `CellNode` path)

All 13 flo scripts parse (`cell ✓`, i.e. `cell.flo.h` round-trips through
`FloParse` unchanged in shape).

---

## 2026-07-11 Refactor.h — xyzw consolidation

Status: implemented, build green, simulator-validated (see "Verification"
below). Companion to the "2026-07-11 restructure" section above — that pass
registered `shape`/`wave`/`field` as standalone `PipeNode` subclasses; this
pass consolidates the `shape` rule's parameter surface into component leaves
and adds the MuMenu control type that surface needed.

### Menu: field/wave/shapes moved into `more.flo.h`, `cell.flo.h` flattened to 10 leaves

`field`/`wave`/`shapes` now live in `Mu/MuSky/Sources/MuSky/Resources/more.flo.h`
under a top-level `mic{...}` node, not under `cell.flo.h`'s `more{...}` child
described in the "Menu script reverted to `cell.flo.h`" section above — that
`cell.more{...}` branch is gone. Live `cell.flo.h`:
```
cell (columns 2, svg "icon.cellular.automata") {
    slide zha ave fade melt tunl fred, drift warren noise
}
```
10 leaves: the 7 legacy rules plus `drift`/`warren`/`noise`. All ten route
through `CellNode` per `Deep/Muse/Sky/SkyPipeline.swift`'s routing case
(`case "slide","zha","ave","fade","melt","tunl","fred","drift","warren","noise":
pipeNode = CellNode(...)`), unchanged from the prior pass except for the
`drift`/`warren`/`noise` additions.

### Shapes params consolidated into component leaves bound to `pipe.cell˚shape.*`

Live `more.flo.h` `mic.shapes` block:
```
shapes (sym "snowflake", 'procedural shape fields') {
    algo   (seg, x 0_3=0,  <> pipe.cell˚shape.algo)
    preset (seg, x 0_5=1,  <> pipe.cell˚shape.version)
    cone    (xyzw, x 0…40=5, y 0…40=5, z 50…400=100, w 50…400=100,
             <> pipe.cell˚shape.cone)
    petal   (xyzw, x 0_14=1, y 0_7=1, z 0…50=0, w 0…50=0,
             <> pipe.cell˚shape.petal)
    spiral  (xyzw, x -50…50=-50, y -50…50=-50, z 400…1000=800, w 400…1000=800,
             <> pipe.cell˚shape.spiral)
    column  (xyz,  x 0_8, y 2_9, z 6…306=306,
             <> pipe.cell˚shape.column)
    circle  (seg,  x 0_24=1,
             <> pipe.cell˚shape.circle)
}
```
Component→field mapping (`Mu/MuVision/Sources/MuVision/Pipeline/ShapeNode.swift`,
`floralFields`): `cone` x=cone1Scale y=cone2Scale z=cone2Strength
w=cone1Strength; `petal` x=petal1Num y=petal2Num z=petal2Petalz
w=petal1Petalz; `spiral` x=petal1Spiralz y=petal2Spiralz z=petal2Strength
w=petal1Strength (this `spiral` leaf is the `Floral` petal-spiral term —
same name, unrelated to the `spiral` shape kernel at `algo=1`); `column`
x=columnNum y=columnRays z=columnStrength; `circle` (seg) x=circleRays.
On-flags are no longer leaves — `ShapeNode` derives them every frame from
the driving component: `cone1On←cone.x>0`, `cone2On←cone.y>0`,
`petal1On←petal.x>0`, `petal2On←petal.y>0`, `columnOn←column.x>0`,
`circleOn←circle.x>0`.

### `randomOn` / floral reroll retired

`randomOn` is gone from the pipe node, `ShapeNode`, and the kernel struct.
`Deep/Muse/Metal/cell.rule.floral.metal`'s `FloralUniforms` is now 22 floats
/ 88 bytes (previously 23 floats / 92 bytes with a leading inert `randomOn`
field; struct comment now reads "reroll-trigger field removed 2026-07-11
(Refactor.h)"). Floral renders deterministically from its uniforms every
frame, same as `spiral`/`circle` always did — the host-side reroll pass
`Port/B2.shapes.notes.md` proposed was never built; see the correction
appended to that file. `Mu/MuVision/Sources/MuVision/Pipeline/CellNode.swift`
carries no `simple`/`spiral`/`circle`/`floral`/`happy` cases and no
per-shape `floats` buffer machinery — those four rules are exclusively
`ShapeNode`'s.

### `ShapeNode` buffer(1) assembly

`ShapeNode` builds each kernel's buffer(1) array from an ordered
`[Field(node, comp, onFlag)]` list per variant (`node` indexes the five
driving component flos `cone`/`petal`/`spiral`/`column`/`circle`; `comp` is
`"x"`/`"y"`/`"z"`/`"w"`), reading `Flo.val(comp)` fresh every
`computeShader` call: `field.onFlag ? (v > 0 ? 1 : 0) : v`. Kernel struct
field counts are unchanged in shape from `Port/B2.shapes.notes.md`'s
originally-documented layouts: `SpiralUniforms` 5 floats, `CircleUniforms`
6 floats, `FloralUniforms` 22 floats (down from 23 — the removed field is
`randomOn`, see above).

### New MuMenu control: `.xyzw`

Fourth-axis control added under `Mu/MuMenu`:
- `NodeType.xyzw` (`Sources/MuMenu/Node/NodeType.swift`) — raw value
  `"xyzw"`, `isControl == true`.
- `LeafXyzwVm` (`Sources/MuMenu/Leaf/LeafXyzwVm.swift`, subclass of
  `LeafXyzVm`) and `LeafXyzwView` (`Sources/MuMenu/Leaf/LeafXyzwView.swift`)
  — layout is `LeafXyzView` plus a bottom `runW` row.
  `BranchVm.leafVm(...)` instantiates it with runways
  `[.runX, .runY, .runZ, .runW, .runXY]`.
- `runW` is a horizontal runway whose thumb carries `w` in its own `x`-slot
  (`LeafThumb` stays SIMD3, no new axis added to it).
  `LeafRunways.setThumbPoint` isolates `runW` from x/y/z/xy touch dispatch
  with a same-type guard: `if (thumbType == .runW) != (type == .runW) { continue }`.
- The `w` slider renders on its own bottom row, horizontally aligned with
  the `x` slider via an invisible, hit-test-disabled `LeafHeaderDeltaView`
  twin that reserves the same leading width the live header occupies in the
  row above (`LeafXyzwView.swift`).
- `PanelVm`'s `aspect`/`thumbDiameter`/`runwayLength`/panel-size switches
  gained `.xyzw`/`.runW` cases (bottom-row height added to the xyz aspect
  ratio; watchOS and non-watchOS both covered).

### Adversarial review fixes (landed with the feature)

- `LeafVm.setRanges()` (`Sources/MuMenu/Leaf/LeafVm.swift`) captured only
  `["x","y","z"]`; `"w"` fell through and got min-clamped on every write.
  Fixed to `["x","y","z","w"]`.
- `LeafRunways.setThumbFlo`'s `.runXY` case
  (`Sources/MuMenu/Leaf/LeafRunways.swift`) dropped `z`/`tz` from
  `setValueTween`, so the model/bind `z` value collapsed to its range
  minimum on every sync. This is also what corrupted `wave`'s `uxyn.z`
  (`num`) bind — `uxyn` is `xyz`-typed and syncs through the same `.runXY`
  thumb — described in `Port/B3.waves.notes.md`'s "2026-07-11 correction"
  section. Fixed: `.runXY` now carries `vz`/`tz` through
  (`case .runXY : thumb.setValueTween(vx, vy, vz, tx, ty, tz)`).
- `BranchView.swift`'s vertical-scroll-layout node-type set gained
  `.xyzw` (previously only `.xy`/`.xyz`/`.arch`/`.peer`), so a 4-axis leaf
  in a vertical panel scrolls instead of clipping.
- `LeafVm.setNormalized` gained a `"w"` case (writes `runW`'s thumb
  `.value.x`/`.tween.x`) and mirrors `z` into the `runXY` thumb's
  `.value.z`/`.tween.z` alongside the existing `runZ` write, matching the
  `setThumbFlo` fix above.

### Verification

Validated simulator runs, `MTL_DEBUG_LAYER=1`, fresh installs, zero Metal
API-validation assertions:
- shape `algo=1` (spiral) — component-subset params driven through
  `cone`/`circle` leaves — `draw ⟹ shape(…⟶…) ⟹ color`.
- shape `algo=3` (floral, 22-float `FloralUniforms`) —
  `draw ⟹ shape(…⟶…) ⟹ color`.

Baseline (unmodified legacy-rule chain) re-verified after the above.

---

## 2026-07-11 shapes de-globalization

Status: implemented, build green, simulator-validated, opus-review PASS.
Retires the shared-global `algo`/preset design from the "Refactor.h" pass
above in favor of four independent per-shape pipe branches.

### Menu: four per-shape branches, shared globals retired

`more.flo.h`'s `mic{}` node now declares one branch per shape, each with its
own unique pipe node — the former shared `cone`/`column`/`circle` globals
and the `algo`/preset leaves are retired:
```
circular { cone(xyzw → ˚shape.circular) }                    // circle kernel
zigular  { cone(xyzw, z=circleRays 0_24 → ˚shape.zigular) }   // spiral kernel, y inert
simple   { preset(seg 0_5 → ˚shape.simple) }
petal    { petal(xyzw, y default 0 → ˚shape.petal),
           spiral(xyzw → ˚shape.spiral) }                     // floral kernel
```

### Selection: no algo leaf, edge-driven solo

`ShapeNode` registers flo closures on the five param nodes rather than
reading a shared `algo` leaf. A `.user`/`.remote` visit sets `algo`
(0/1/2/3/3 per branch) with `.fire`; the pipe edge `˚algo(-> ..(on 1))`
solo-activates the corresponding shape rule. Archive restore (`.model`
visits) deliberately does not trigger selection — `algo`'s own restored
value re-solos via that same edge, not via the restore visit. Opus review
traced the visit path end-to-end: the menu `<>` sync arrives as
`[.user,.model]`, the sibling `algo` node is never pre-visited, and the
shared-visit mechanism blocks edge re-entry.

### simpleKernel preset feed

`simpleKernel`'s preset is fed from `shape.simple.x` via `setBytes` when
`algo==0`; the `version` buffer is bound otherwise. `shape.version` is
vestigial — retained only as a re-solo trigger.

### Floral via petal shape: petals only

Floral rendered through the `petal` shape renders petals only.
`FloralUniforms` slots 0-11 (cone1/cone2/circle/column) are held constant 0
by `ShapeNode`.

### Petal investigation (WinSky source)

`pixel/Rule.cpp:523-599`, `tree_demo.sky:1810-1850`: `petal1`/`petal2` were
never a standalone shape in WinSky — they are floral sub-controls. WinSky's
`iPetalStrength / 1000` is integer division: strength 400..999 produces
amplitude 0, so petals are invisible except at exactly 1000; the Metal
port's float division restored visibility across the full range. The
`petal2` block overwrites `petal1`'s `rPetalValue` — kept kernel-faithful
rather than fixed. Menu default `petal.y=0` keeps `petal1`'s sliders live.

### simple investigation (WinSky source)

`Rule::simple`'s only control is `simpleVersion` 0..5 (hardcoded `SetXYPO`
coefficients). The per-rule `mix{plane,bits,op}` tree block is a universal
display bit-plane mixer (`pic/MixSet.cpp`), superseded by DeepMuse
color/tile — not ported; nothing simple-specific was lost.

### Fidelity note: zigular range exceeds WinSky spiral

`zigular.z` range 0…24 exceeds WinSky spiral's `circleRays` range 1..9,
producing brightness divergence at the high end. Deliberate, per Dev hint
referencing the old `shape.circle` range.

### Refactor.h staleness

`/Users/warren/Dev/Deep/Deep/Muse/Refactor.h` is an uncompiled design-spec
scratch file, not compiled into the build. Its shapes block is stale
relative to shipped code: duplicated `petal1` lines and placeholder ranges
were corrected during implementation and not backported to the scratch
file.

## Addendum 2026-07-11 (eve): shapes flatten, spiral seam, dual-thumb pad, MuFlo same-target fix

- Shapes menu flattened to four leaves (circular xyzw / zigular xyz / simple seg / petal xyzw); pipe `shape.spiral` node removed — single petal drives floral petal1 [On=y>0, Num=y, Spiralz=x, Petalz=z, Strength=w], petal2 constant 0. ShapeNode selects → algo 0/1/2/3.
- cell.rule.spiral.metal ray term `trunc(rAngle/(2π)·256·rays)` replaces WinSky `ScaleTo(...,255)·rays`: integer ray counts wrap ≡0 mod 256 at the atan2 branch cut — removes the disjoint center-to-top line (which also bled into circular via HiC feedback). Divergence documented in the kernel header; unused scaleTo retained for provenance.
- MuMenu xyzw pad hosts dual thumbs (runXY + runWZ, w=x-slot z=y-slot); activePad picks the filled pair, dotted inactive thumb underneath, tap-to-swap. Legacy xy/xyz dispatch untouched (hasWZ-gated).
- MuFlo: repeated target path within one edge scope (`<> (t(x: w), t(y: z))`) previously clobbered to last-wins at PARSE (PathExprs keyed by path string; camera.mix→canvas.color lost `x: w`). Fixed via PathExprs curKey cursor + prepend-merge (parser attaches edge Exprs before filling tokens). Tests: testAssignSameTarget / testAssignSameTargetOrdering. slide/zha `loops` comps z→y so `mix ˚loops(y: y)` reaches the default rule.
- Pre-existing MuFlo findings (documented, unfixed): reverse `<>` named maps not inverted; wildcard edges share one Exprs instance; EdgeDef.init(from:) copy-loop dead code.

### Iteration 2 (same day): tap-to-swap geometry, torus fold, camera-mix exoneration

- LeafRunways.thumb(_:contains:) rewritten: center-anchored circular hit test, per-type value slots, inverse of normalizePoint. The prior top-left-anchored rect missed thumbs by a full radius — dotted-thumb tap-to-swap could never fire.
- Spiral ray term v2: `trunc(atan2(|dx|,|dy|)/(π/2)·256·rays)` — quarter-folded (even in both axes): no branch cut, tiles the torus (no seams on 4 edges under repeat/shift), continuous for fractional rays (`0_24` rangei scales without rounding — reason the v1 integer-only fix failed live). Rays now render as 4-fold mirrored fans — the only spoke form that tiles.
- camera.mix: full-fidelity MuFlo graph tests (buffer + `^-` plugin + wildcard ˚loops + same-target maps, `<>` and `->`) pass — flo layer exonerated. Residual in-app failure paths: (1) w/z unreachable while swap was broken; (2) SkyArchive snapshots regenerated by the PRE-fix parser carry the lossy edge text — restore re-applies the bug; clear archive / fresh install.

### Addendum 2026-07-11 (night): floral fold, touch tolerance, cross-menu hide, field xyzw

- cell.rule.floral.metal: all four angular terms quarter-folded (aq = atan2(|dx|,|dy|)) — petal field tiles the torus, no branch cut, fractional-param safe; petal2-overwrites-petal1 and struct layout preserved.
- LeafRunways: slider grab-radius floor (Menu.radius) + two-pass beginRunway (exact first, slider-outset fallback) — z sliders now finger-grabbable.
- TreeVm.hideOverlappedTrees: expanding one corner menu over the other triggers the other's standard hide (sideAxis lookup; RootVm.menuVms is frozen-empty — do not use).
- mic.field → single xyzw leaf (algo/fader/a0/a1); seed control removed. Seed WAS used (host rnd a[] for 10 algos; per-pixel noise algos 0/8/18) — now fixed at the old default 1, so default output identical.

### Addendum 2026-07-11 (late): live mic.input

- `mic.input(xy)` menu leaf (<> sky.mic.input): y volume gates the mic (0 = off — engine stopped, session deactivated), x log-sweeps a band-pass 20 Hz…22 kHz. WaveAudioTap is LIVE: input→BandPassFilter→gain Mixer→AmplitudeTap(512-sample ring)+FFTTap(512 bins — setBytes 4KB limit forbids more); zero-volume output Mixer prevents speaker echo. Lifecycle serialized (user/remote/bind visits); denied latch prevents retry thrash. WaveNode pulls mag/fft per frame via the injected static provider (still no MuAudio dependency edge); magCount/fftCount uniforms now live. Gaps 1–2 of Port/Stubs.md closed.

### Addendum 2026-07-12: zha "flash" root cause + scoped leaf fires

- The flash was palette clobber, not zha: camera.mix's canvas.color maps (both live after the same-target merge fix) fired with default w/z=0 on EVERY leaf drag because xyzw leaves fired all four comps; color→plane/xfade snapped per event. LeafXyzwVm now scopes user/remote fires to the touched runway's comps (model/bind stays full-width sneak); untyped/none fires are no-ops. slide/zha loops stay z-comp per Dev's revert — the `˚loops(y: y)` map is inert for them by MuFlo semantics (setters derive from the target's own comp walk).
