# Gap Audit: `griddy`

Audit run 2026-04-26. Timeboxed. Records every package/resource checked, verdict against the rubric, link, one-line note.

## Rubric

A package "covers" the spatial distribution dynamics space if all four hold:
- (a) named exported function or worked vignette computes spatial Markov conditional transition matrices;
- (b) feature work or release in the last 24 months (not just reactive ecosystem-fix commits);
- (c) on CRAN, or with stated production intent and discoverable docs (vignette, pkgdown, or equivalent);
- (d) used by anyone outside the author's lab — citations or downstream packages depending on it count.

Failing (c) or (d) means the package is methodological infrastructure for its authors, not a user-facing product. It can serve as an oracle but does not close the gap from a griddy-audience perspective.

The gap is decomposed into three independent classes:
1. **Methodological gap** — does R code compute the matrices at all?
2. **Workflow gap** — sf/tidy-native, ID/time semantics, map output?
3. **Product gap** — CRAN-grade R package a non-author would discover, install, and use?

## Verdict

**Pass.** No maintained, CRAN-grade, tidy/sf-native R package covers spatial distribution dynamics. Two academic-supplement packages (estdaR, spdyn) implement the methods and serve as useful oracles, but neither is positioned as a user product:

- estdaR's README explicitly states no plans to go to CRAN; it accompanies two 2020 papers.
- spdyn has been on R-Forge for twelve years at version 0.0-3, single maintainer, no vignette, no CRAN.

Both packages should be cited heavily as prior art. Neither competes for the audience griddy would target.

The applied-prototype gate is still the right next step — not because the methodological landscape is unclear, but because audience risk remains the first-order risk. The prototype's job is to prove the workflow is useful to non-methodologists.

## Findings

### estdaR — methodologically near-complete

- Repo: <https://github.com/amvallone/estdaR>
- Authors: Vallone (UCN Chile), Le Gallo, Chasco, Ayouba — all credible spatial econometrics researchers; Le Gallo is a Rey collaborator
- Last commit: **2024-03-24** (~25 months stale)
- Distribution: GitHub only, not CRAN, no R-universe
- Imports: `sf`, `spdep`, `ggplot2`, `gridExtra`, `RColorBrewer`, `gasfluxes` (the last is odd)

Exported functions (17): `mkv`, `sp.mkv`, `lisamkv`, `sig.lisamkv`, `d.LISA`, `quad`, `discret`, `sp.tau`, `tau`, `theta`, `prais`, `shorrock`, `st.st`, `homo.test`, `sp.homo.test`, `moran`, `geary`, `join.d`.

Map to griddy v0.1 + v0.2 + deferred:

| griddy proposal | estdaR equivalent |
|---|---|
| `classify_dynamics()` | `discret()` |
| `markov_dynamics()` / `transition_matrix()` | `mkv()` |
| `spatial_markov()` | `sp.mkv()` |
| LISA Markov (v0.2) | `lisamkv()`, `sig.lisamkv()` |
| `steady_state()` | `st.st()` |
| Directional LISA (deferred) | `d.LISA()` |
| Rank mobility | `tau()`, `sp.tau()`, `theta()`, `prais()`, `shorrock()` |
| Homogeneity tests (not in brief) | `homo.test()`, `sp.homo.test()` |

Coverage: **methodologically broader than the proposed griddy v0.1**.

Workflow check (read source of `mkv.R`, `sp.mkv.R`, `lisamkv.R`):
- Input: numeric matrix, n units × t periods. No long-form, no ID/time column semantics.
- Weights: `spdep::listw` only. No tidy weights API.
- Output: base R lists of matrices. No tibble, no sf preservation, no plot methods.
- Documentation: rough — "for later..", typos, minimal examples, no vignettes, no pkgdown site.
- Visualization: none, despite ggplot2 in Imports.

Additional API-level friction from a runtime pass:
- `us48` ships as an `sf` object, but the documented workflow immediately strips geometry to a wide matrix. `sf` is a hard dependency without an `sf`-preserving analysis path.
- Row identity is implicit. Results are keyed by matrix row position, not by `id`/`time`, so sorting or filtering before analysis makes "which unit moved?" hard to recover.
- `lisamkv$move` stores 16 origin-destination LISA transitions as integer codes without human-readable labels such as `HH -> HL`.
- `sp.mkv()` labels conditioning states as `Lag 1` through `Lag 5`, but does not surface the spatial-lag cutpoints behind those labels.
- Results are bare lists, not S3 classes with `print()`, `summary()`, `plot()`, or tidy coercion methods.
- Normalization steps such as per-year relative income are left to user incantations rather than exposed helpers.
- `library(estdaR)` masks common `spdep` functions including `geary` and `moran`.

Verdict against rubric: (a) ✓, (b) ✗ (last commit was a reactive `rgdal` dependency removal forced by spdep, not feature work; no feature work since 2020 paper publication), (c) ✗ (README explicitly disclaims CRAN intent; positioned as paper supplement), (d) unclear — citations to the 2020 papers don't translate to package usage.

**Methodological oracle, not a product.** Useful for cross-validation. Not competition.

### spdyn — narrower, more recent, sf-aware

- Project: <https://r-forge.r-project.org/projects/spdyn/>
- Site: <https://spdyn.r-forge.r-project.org/>
- Maintainer: Osmar Loaiza
- Last commit: **2024-10-28**, message "Updated functions for compatibility with 'sf' objects"
- Distribution: R-Forge, version 0.0-3, installable via `install.packages("spdyn", repos="http://R-Forge.R-project.org")`. Not on CRAN.

Exported functions (from R/ directory listing): `markov`, `spMarkov`, `mfpt`, `steadyState`, `clusterQuadrant`, `unimoran`, `unimoran.test`, `bimoran`, `bimoran.test`, `lisa.perm`, `bilisa.perm`, `roseDiagram`, `moran.scatterplot`, `initState`, `spInitStates`, plus print/plot methods (`plot.lisaPerm`, `print.moranPerm`).

Map to griddy proposal:

| griddy proposal | spdyn equivalent |
|---|---|
| `markov_dynamics()` | `markov()` |
| `spatial_markov()` | `spMarkov()` |
| `steady_state()` | `steadyState()` |
| Mean first passage (cut) | `mfpt()` |
| LISA Markov (v0.2) | not directly — has `clusterQuadrant` + `lisa.perm` components |
| Directional LISA rose (deferred) | `roseDiagram()` |
| Rank mobility | not present |

Has plot methods (`plot.lisaPerm`, `moran.scatterplot`) — narrower visualization than griddy proposes, but more than estdaR has.

Verdict against rubric: (a) ✓, (b) ✗ (Oct 2024 commit was a sf-compat fix — same reactive-maintenance pattern as estdaR; no feature work in years), (c) ✗ (R-Forge only, twelve years at version 0.0-3, no CRAN, no vignette, no pkgdown), (d) low — single-maintainer academic infrastructure with negligible discoverability.

**Methodological oracle, not a product.** Cite as prior art and validate against. The proposed alternative name `spdyn` is still occupied — drop from the candidate list regardless.

### rgeoda — covers LISA but not LISA Markov

- Anselin's R bindings to GeoDa libgeoda. CRAN, actively maintained.
- Inspected `R/lisa.R` directly: 21 functions, all cross-sectional LISA variants (local Moran, Geary, Getis-Ord, Join Count, quantile LISA, neighbor match test).
- **No spatial Markov, no LISA Markov, no temporal regime transitions.** The kill-check from the prior pass is negative.

Verdict: (a) ✗ fail. Not a competitor.

### sfdep — doesn't cover dynamics

- Parry's tidy spatial dependence package. CRAN.
- Functions are cross-sectional: contiguity, weights, lag, local Moran. No Markov, no temporal transitions.
- No open issues mentioning Markov / regime / dynamics that I could surface.

Verdict: (a) ✗ fail. Not a competitor. **Still a candidate home for a clean PR if griddy collapses to one or two verbs** — but adding spatial Markov to sfdep is a meaningful scope expansion of sfdep, not a small contribution.

### markovchain — generic, no spatial conditioning

- CRAN, active. General-purpose Markov chain calculations.
- No spatial conditioning, no LISA states, no sf integration. Comparator only.

Verdict: (a) ✗ fail. Not a competitor; useful as a cross-check for transition-matrix / steady-state numerics.

### spMC — different problem (geostatistical)

- CRAN, "Continuous-Lag Spatial Markov Chains".
- For categorical random fields (geostatistics-style — soil types, lithology). Not regional distribution dynamics.

Verdict: not in scope. Different method family despite the name overlap.

### samc — different problem (landscape connectivity)

- CRAN, "Spatial Absorbing Markov Chains".
- Landscape ecology / connectivity modeling with absorbing states for mortality. Not regional distribution dynamics.

Verdict: not in scope. Note the name-collision risk: a CRAN package with "spatial" + "Markov" in the name occupies adjacent search territory.

### msm / mstate — different problem (panel multistate)

- CRAN, both active. Multistate Markov for biostatistics panel data.
- No spatial conditioning. Different audience entirely.

Verdict: not in scope. Listed for completeness.

### Sergio Rey / Wei Kang R artifacts — none surfaced

- weikang9009 GitHub: 124 repos, all PySAL-side Python. No R artifact surfaced; full sweep would require paginated repo listing.
- No JSS / R Journal supplement surfaced for Rey 2001 or Rey 2016.

Verdict: no R-side reference implementation by the original methodologists.

### Geocomputation with R — no dedicated chapter

- Lovelace/Nowosad/Muenchow. No chapter dedicated to spatial Markov or distribution dynamics in current ToC.

Verdict: educational gap remains open.

### reticulate-via-PySAL wrapper — none found

- No R package surfaced that wraps `giddy` via `reticulate`.

Verdict: no Python-shaped R alternative competing for attention.

## Implications

### What this changes about the brief

1. **Methodological-gap framing is mostly fine but needs precision.** The brief's claim "R does not appear to have a cohesive, modern equivalent to PySAL `giddy`" is defensible if "modern equivalent" means a CRAN-grade tidy/sf-native package. It is misleading if read as "no R code exists." Tighten to: "R has academic-supplement implementations of the methods (estdaR, spdyn) but no maintained, CRAN-grade, tidy/sf-native package. griddy targets the package gap, not the methods gap."

2. **`spdyn` is taken as a name.** Cross it off the alternative-name list regardless.

3. **Validation strategy gains a free oracle.** PySAL `giddy` remains the primary oracle. **Add**: cross-check `estdaR::mkv()`, `estdaR::sp.mkv()`, `estdaR::lisamkv()`, `spdyn::spMarkov()` outputs on the same inputs. Three independent implementations agreeing is strong evidence the new code is correct. Disagreements with estdaR/spdyn that match giddy are documentable; disagreements with all three are bugs.

4. **Etiquette: cite as prior R-side work, not as competing products.** Both packages should appear in README's "Related work" / "Prior art" section with one-line summaries and links. Neither maintainer needs to be consulted before building a parallel package targeting a different audience — that's the standard pattern when paper supplements coexist with user-facing packages.

5. **Don't try to revive estdaR.** Earlier audit suggested opening a maintainer issue on `amvallone/estdaR`. Withdraw that. The README explicitly disclaims CRAN intent; a tidy/sf refactor PR has nowhere to land that reaches R users. Same logic for spdyn — twelve years at 0.0-3 on R-Forge is a clear signal that the maintainer is not pursuing a user-product trajectory.

6. **Differentiation framing.** "End-to-end sf/tidy workflows", "applied-question framing", "CRAN distribution", "modern visualization defaults" — these are the differentiators against the *methodological status quo*, which is "use Python, or use an academic GitHub package, or write your own." That is a reasonable user-product gap to address. The most load-bearing differentiators are the classification helper, ID/time-aware inputs, explicit weight/lag metadata, labeled transition outputs, and S3 result objects. Visualization helps, but the core value exists even for users who never plot.

7. **Oracle fixtures.** `estdaR` numerics look usable as oracle fixtures. Snapshot its stable outputs for `us48`/state-income workflows to static CSV/RDS files, validate them once against PySAL `giddy`, and keep ordinary CI independent of `estdaR` and Python.

### Decision tree

After this audit:

- **If the applied prototype clearly demonstrates audience value** (i.e., a non-methodologist reading "did this neighborhood actually move?" finds it compelling) → build griddy as a CRAN-targeted standalone package. README must cite estdaR and spdyn as prior R-side work.
- **If the prototype is a slog or audience reaction is flat** → no package. The methods already exist in academic R; without an audience pulling for them, a third academic-style package adds nothing.

The intermediate "contribute upstream instead" path is closed — neither prior package is positioned to absorb the work.

### Pre-committed kills (set before searching, evaluated now)

| Kill criterion | Triggered? |
|---|---|
| `rgeoda::lisa_markov()` or equivalent exists, maintained | No |
| `sfdep` has spatial Markov on roadmap or implemented | No |
| **Maintained, CRAN-grade R package covers spatial Markov on tidy/sf inputs** | **No** — this is the kill criterion that matters; not triggered |
| Academic-supplement R package covers the methods | Yes (estdaR, spdyn) — does not trigger kill |

Verdict: **pass**. Proceed to the applied prototype.

## Resources checked

| Resource | Status | Verdict |
|---|---|---|
| [estdaR](https://github.com/amvallone/estdaR) | GitHub, Mar 2024 | Methodological coverage, no workflow/sf-tidy |
| [spdyn](https://spdyn.r-forge.r-project.org/) | R-Forge, Oct 2024 | Methodological coverage, narrower, sf-aware |
| [rgeoda](https://github.com/GeoDaCenter/rgeoda) | CRAN, active | Cross-sectional LISA only |
| [sfdep](https://github.com/JosiahParry/sfdep) | CRAN, active | Cross-sectional only |
| [markovchain](https://cran.r-project.org/package=markovchain) | CRAN, active | Generic, no spatial |
| [spMC](https://cran.r-project.org/package=spMC) | CRAN | Geostatistical, different problem |
| [samc](https://cran.r-project.org/package=samc) | CRAN | Landscape connectivity, different problem |
| [msm](https://cran.r-project.org/package=msm), [mstate](https://cran.r-project.org/package=mstate) | CRAN | Biostat panel multistate, no spatial |
| [weikang9009 GitHub](https://github.com/weikang9009) | — | All Python, no R artifact |
| [Geocomputation with R](https://r.geocompx.org/) | Active | No dedicated chapter on dynamics |
| reticulate-via-giddy R wrapper | Searched | None found |
| JSS / R Journal supplements for Rey 2001/2016 | Searched | None found |

## Audit limits

- Did not page through all 124 of weikang9009's repos; spot-checked pinned only.
- Did not search Bioconductor (low prior; geocomp methods rarely live there).
- Did not search rOpenSci review queue.
- Did not exhaustively check sfdep open issues for "Markov" (READMEs/visible issues only).
- estdaR commit history was a shallow clone showing only one commit; relied on rdrr's "Built March 30, 2024" timestamp for currency.
- Did not run any of estdaR/spdyn locally; assessment of workflow gaps is based on source reading and DESCRIPTION/NAMESPACE inspection, which is sufficient for the verdict but does not test runtime behavior.

If any of the above turns up a maintained tidy/sf-native package the audit verdict shifts from partial pass to fail.
