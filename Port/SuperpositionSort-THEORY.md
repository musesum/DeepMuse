# SuperpositionSort — Theory

Lower bounds and conjectures for cellular sorting of a texel grid into a target
image, and a comparison of measured step counts (versions 2–7) against those
bounds. Terms are kept plain. Claims are tagged as *proven*, *observed*, or
*conjecture*.

---

## 0. Setup and notation

- Grid: `W × H` texels on a torus (edges wrap). Each cell holds a value; sorting
  permutes values until each sits at its target cell.
- Reach `c`: the update rule reads and writes within a neighborhood of radius `c`
  texels. A value can move at most `c` cells per frame.
- Diameter `D`: the largest shortest-path distance between two cells. On a
  `W × H` torus a value can be pushed either way around each axis, so the worst
  wrap distance per axis is half the side, and

  `D = (W + H) / 2`.

  For the square working grid `W = H = 512`, `D = 512`.
- Frame: one synchronous update of every cell.

---

## 1. Light-cone lower bound (proven)

**Claim.** Any local rule with reach at most `c` needs at least `D / c` frames to
sort from arbitrary input.

**Argument.** Information (a value, or the knowledge of where it must go) moves at
most `c` cells per frame — this is the discrete light cone of a reach-`c` rule.
After `t` frames the content of any cell can only depend on, and can only have
been delivered to, cells within distance `c · t` of its origin. Choose an input
that places some value at maximum distance from its target: on the torus such a
pair exists at distance `D = (W + H)/2`. To seat that value the rule must transport
it `D` cells, which takes at least

  `t ≥ D / c`   frames.

Since the input was legal and arbitrary, no rule of reach `c` can beat `D / c` in
the worst case. The bound is a pure transport argument — it assumes nothing about
congestion, collisions, or occupancy, so it holds for every variant below and is
the floor that all of them obey.

**Key inequality.**

```
frames ≥ D / c        with D = (W + H) / 2
```

For `512 × 512`, `c = 1`: `frames ≥ 512`.

---

## 2. Exclusion (occupancy-1) rules add congestion

When a cell may hold at most one value, values cannot pass through one another;
they queue. The transport floor of §1 still holds, but a second cost appears:
displacement now competes for cells.

**Proven (odd–even transposition).** The odd–even transposition sort on a line of
`n` cells sorts any input in at most `n` compare-exchange sweeps. Each sweep is a
reach-1 exchange, and a value advances at most one cell per sweep. A value needing
displacement `d` therefore costs on the order of one sweep per cell of travel; with
the standard two-phase (odd sites, then even sites) schedule this is realized as
about **two frames per cell of displacement**, because each cell participates in an
exchange on only every other phase. This factor-2 is proven for the 1-D exclusion
schedule and is the reason exclusion variants land near `2 · D` rather than `D`.

**Key inequalities.**

```
frames ≥ D / c                         (transport floor, §1)
frames ≈ 2 · (displacement in cells)    (odd–even realization, exclusion)
```

**Observed, not proven.** The general claim that *every* occupancy-1 local rule on
the 2-D torus is bounded below by a constant strictly greater than the bare
transport floor — i.e. that congestion forces `frames ≥ α · D` with `α > 1` for all
exclusion rules and all inputs — is not proven here. Only the odd–even schedule's
`≈ 2` factor is established. For the multi-axis 2-D routing used in the app, the
factor above the floor is measured, not derived. Treat the "roughly `2 · D`"
behavior of the exclusion variants as an observation consistent with the 1-D proof,
not as a theorem about 2-D exclusion in general.

---

## 3. Superposition (multi-occupancy) conjecture

Superposition drops exclusion: a cell may hold several values "in flight" at once
(the implementation gives each cell **four flight slots**). Values in different
slots pass through one another without queuing, so congestion of the §2 kind is
removed for up to four coincident occupants.

**Conjecture (ballistic collapse).** With four flight slots and no exclusion,
generic inputs collapse to the sorted target in

```
frames = D / c + (lower-order terms)
```

i.e. the transport floor plus corrections that grow slower than `D` (slot
contention when more than four values coincide, boundary/settle effects). The
worst case is conjectured to stay within a **constant factor** of the floor:

```
frames ≤ K · (D / c)      for some constant K independent of grid size.
```

**Status.** This is a *conjecture*, not a proof. What is defensible: (a) the floor
`D/c` is proven (§1) and cannot be beaten; (b) removing exclusion removes the
proven source of the factor-2 in §2; (c) with four slots, a value travels
ballistically until it either seats or meets a fifth coincident value. What is
*not* proven: that slot contention stays a lower-order term for generic inputs,
and that no adversarial input forces super-constant overhead. The `K` is
unestablished. Label any statement of the form "superposition reaches the floor"
as a conjecture until a contention bound is proven.

---

## 4. Polar variant

Instead of a Cartesian grid, arrange cells in concentric rings; ring `r` has
circumference `2 · π · r`. Sorting now has a radial component (move a value to its
target ring) and an angular component (rotate it within the ring).

**Radial travel bound.** A value's radial distance is bounded by the number of
rings, which is `R = ` half the short side of the enclosing frame:

```
R = min(W, H) / 2
```

Radial transport therefore costs at least `R / c` frames by the same light-cone
argument as §1, applied along the radial axis.

**Conjecture (polar ballistic).** With superposition slots and no radial exclusion,
radial collapse is conjectured to reach `R / c + lower-order terms`, the analog of
§3 along the radial axis; angular settling adds a term bounded by the largest ring's
circumference divided by `c`. As in §3, the constant-factor worst case is a
conjecture, not proven.

**Area-per-ring mismatch (consequence for the target image).** Ring `r` holds about
`2 · π · r` cells: outer rings hold many cells, inner rings hold few. A source image
sampled on a uniform Cartesian grid does not map one-to-one onto rings of unequal
capacity. Consequences:

- The center is over-represented per unit area (few cells cover a large angular
  span each) and the rim under-represented, or the reverse, depending on the
  sampling — either way the mapping is non-area-preserving.
- The target image must be **resampled into ring capacities** (`≈ 2 π r` samples on
  ring `r`) rather than copied from a square raster, or the reconstructed image
  distorts radially. This resampling is a property of the geometry, independent of
  the sort's speed, and must be applied before any polar sort can reproduce a given
  picture faithfully.

**Key inequalities.**

```
frames ≥ R / c ,   R = min(W, H) / 2         (radial transport floor)
cells(ring r) ≈ 2 · π · r                     (capacity; drives resampling)
```

---

## 5. Measured step counts vs. bounds

Working grid: side `512`, torus diameter `D = 512`, reach `c = 1`, so the proven
transport floor is `D / c = 512` frames and the exclusion reference (§2) is
`2 · D = 1024` frames.

| Version | Measured steps | Regime | vs floor (512) | vs 2·D (1024) | Note |
|---------|----------------|--------|----------------|---------------|------|
| v2 | 172 (long-range) | long-range reach `c > 1` | 0.34× | 0.17× | below the `c=1` floor because reach exceeds 1 texel; consistent with `D/c` for `c > 1` |
| v3 | 1972–2065 | exclusion | 3.85–4.03× | 1.93–2.02× | ≈ 2·(2·D); near the exclusion reference doubled |
| v4 | 2308–2556 | exclusion | 4.51–4.99× | 2.25–2.50× | above v3; more congestion overhead |
| v5 | 1896–2057 | exclusion | 3.70–4.02× | 1.85–2.01× | best exclusion result; ≈ 2·D lower end |
| v6 | 2986–3082 | exclusion | 5.83–6.02× | 2.92–3.01× | ≈ 3·(2·D) |
| v7 | 3082–3226 | exclusion | 6.02–6.30× | 3.01–3.15× | highest; congestion-dominated |

Readings:

- **v2** sits below the `c = 1` floor, which is only possible because its reach
  exceeds one texel; divide by its true `c` to compare against `D/c`. It is the only
  version operating in the long-range regime and the only one near the transport
  floor.
- **v3–v7** are exclusion variants. All land at a multiple of the `2·D = 1024`
  reference: roughly `2×` (v3, v5), `2.25–2.5×` (v4), `3×` (v6, v7). The multiple
  above `2·D` is the multi-axis / multi-pass congestion overhead that §2 flags as
  *observed, not proven*.
- No version yet realizes the §3 superposition conjecture. If that conjecture holds,
  a four-slot superposition variant should land near `D/c ≈ 512` (plus lower-order
  terms) — between v2's long-range result and the exclusion cluster, and about `4×`
  faster than v6/v7.

---

## 6. Summary of what is proven vs. conjectured

- **Proven:** transport floor `frames ≥ D/c`, `D = (W+H)/2` (§1); odd–even
  exclusion realizes `≈ 2` frames per cell of displacement (§2); polar radial floor
  `frames ≥ R/c`, `R = min(W,H)/2` (§4); ring capacity `≈ 2πr` (§4).
- **Observed (not proven):** the factor by which 2-D exclusion variants (v3–v7)
  exceed `2·D` — the multi-axis congestion overhead.
- **Conjecture:** superposition collapse to `D/c + lower-order`, constant-factor
  worst case (§3); the polar analog (§4).
