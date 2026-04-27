# Supporting Gap Audit Notes: R Support For Geospatial Distribution Dynamics

Date: 2026-04-26

Status: superseded as the primary verdict by `audit.md`. This file records the first audit pass and useful source notes. The current decision is **pass on workflow/product gap, not on methods gap**: `estdaR` and `spdyn` are prior R implementations and validation comparators, but they do not close the maintained tidy/`sf` user-product gap.

## Bottom Line

Original outcome: **partial pass**. Revised after comparing with `audit.md`: **workflow/product pass with R-side prior art**.

The gap is narrower than the initial scope brief implied. R does have a GitHub package, `amvallone/estdaR`, that directly implements a substantial part of the PySAL spatial dynamics family: classic Markov matrices, spatial Markov matrices, LISA Markov matrices, significant-state LISA Markov, spatial homogeneity tests, steady-state distributions, and mobility measures.

That said, I did not find a maintained CRAN package that provides a cohesive, modern `sf`/tidy workflow for geospatial distribution dynamics comparable to PySAL `giddy`. The standalone package case should therefore be reframed from "R lacks these methods" to "R lacks a maintained, documented, `sf`-native, visualization-forward workflow for these methods."

## Audit Checks

### `sfdep`

`sfdep` is the closest maintained spatial-analysis neighbor. Its stated purpose is to provide an `sf` and tidyverse-friendly interface to `spdep`, with core functionality around neighbors, weights, spatial lags, and local indicators of spatial association. Its reference index includes spacetime support, emerging hotspot analysis, `local_moran()`, `st_lag()`, neighbors, and weights, but not spatial Markov, LISA Markov, transition matrices, or regional distribution dynamics.

Sources:

- https://sfdep.josiahparry.com/
- https://search.r-project.org/CRAN/refmans/sfdep/html/00Index.html
- https://rdrr.io/cran/sfdep/man/local_moran.html

Implication: `sfdep` supplies several required building blocks and may be the right upstream home for one or two verbs, but it does not appear to cover the full workflow.

### `estdaR`

`estdaR` is the most important audit result. It is a GitHub package for exploratory spatio-temporal data analysis in R and appears directly aimed at the same methodological family. Its function index includes:

- `mkv()`: Markov transition probability matrix
- `sp.mkv()`: spatial Markov transition probability matrix, citing Rey (2001)
- `lisamkv()`: LISA Markov transition matrix
- `sig.lisamkv()`: LISA Markov with a non-significant state
- `sp.homo.test()`: homogeneity tests for spatial Markov transition probabilities
- `sp.tau()`: global indicators of mobility association
- `st.st()`, `prais()`, `shorrock()`, `theta()`, and related rank/mobility helpers

The package README says it is still in development and not intended for CRAN in the short run. The repository has no releases, has 11 stars, and the docs indicate version `0.0.0.9000`. Documentation pages are sparse in places, with several "for later" details sections. The API is matrix/listw oriented rather than `sf`/tidy long-data oriented.

Sources:

- https://github.com/amvallone/estdaR
- https://rdrr.io/github/amvallone/estdaR/
- https://rdrr.io/github/amvallone/estdaR/man/sp.mkv.html
- https://rdrr.io/github/amvallone/estdaR/src/R/sp.mkv.R
- https://rdrr.io/github/amvallone/estdaR/man/lisamkv.html
- https://rdrr.io/github/amvallone/estdaR/man/sig.lisamkv.html

Implication: a future package must cite and compare against `estdaR`; it should not claim to be the first R implementation of spatial Markov or LISA Markov.

### `spDym`

`amvallone/spDym` appears to be an older, smaller precursor or related package. It includes `mkv()`, `lisamkv()`, `discret()`, a `usjoin` dataset, and plotting helpers, but fewer functions than `estdaR` and older generated docs.

Sources:

- https://rdrr.io/github/amvallone/spDym/
- https://rdrr.io/github/amvallone/spDym/man/

Implication: relevant historically, but `estdaR` is the stronger comparator.

### `spMC`

`spMC` is on CRAN and R-universe, but it targets continuous-lag spatial Markov chains for categorical random fields, transiograms, simulation, and transition-probability maps. This is a different method family from Rey-style regional income distribution dynamics conditioned on spatial lags.

Sources:

- https://cran.r-project.org/package=spMC
- https://drwolf85.r-universe.dev/spMC

Implication: mention as a name collision/search comparator, but it does not collapse the `griddy` scope.

### `markovchain`

`markovchain` is a maintained CRAN package for discrete-time Markov chains, including fitting, transition matrices, simulation, steady states, first passage times, and statistical tests. It is not spatial and does not provide `sf`, spatial-lag conditioning, LISA state construction, or map-ready geospatial workflow.

Sources:

- https://www.rdocumentation.org/packages/markovchain/versions/0.10.3

Implication: use as a comparator or optional validation source, not as a replacement.

### PySAL `giddy`

PySAL `giddy` remains the canonical implementation and methodological oracle. Its docs explicitly cover classic Markov, spatial Markov, and LISA Markov methods for regional income dynamics; the spatial Markov API includes classification controls, spatial lag conditioning, homogeneity tests, long-run distributions, and first mean passage time.

Sources:

- https://pysal.org/giddy/
- https://pysal.org/giddy/notebooks/MarkovBasedMethods.html
- https://pysal.org/giddy/generated/giddy.markov.Spatial_Markov.html

Implication: still the right oracle, but `estdaR` should become a second R-side comparator.

## Revised Gap Statement

Weak version, now rejected:

> R lacks implementations of spatial Markov and LISA Markov methods.

Better version:

> R has scattered or development-stage implementations of spatial Markov, LISA Markov, and mobility diagnostics, especially in `estdaR`, plus strong generic ingredients in `sfdep`, `spdep`, and `markovchain`. The remaining gap is a maintained, well-documented, `sf`/tidy, visualization-forward workflow that makes geospatial distribution dynamics usable from long panel data and map-ready geometries.

## Scope Consequences

- Do not position `griddy` as a first R implementation.
- Add `estdaR` as a required comparator in the scope brief, README, and validation plan.
- Keep v0.1 narrow: classification, classic Markov, spatial Markov, basic rank mobility, and plotting remain defensible only if they materially improve ergonomics.
- Defer LISA Markov to v0.2 unless the prototype shows a compelling applied need. `estdaR` already covers LISA Markov directly, so an early duplicate would weaken the package case.
- Treat `sfdep` as a serious upstream option. If the prototype stabilizes into one spatial Markov helper plus a vignette, a contribution or companion article may be better than a standalone package.
- Use `estdaR` outputs as an additional oracle or regression comparator where licensing and implementation details permit.

## Decision

Proceed to the applied `.Rmd` prototype, but with a stricter burden of proof:

1. The prototype must show that the long-data `sf` workflow is substantially easier than using `estdaR` plus `spdep` manually.
2. The package plan should be renamed from "gap verification passed" to "workflow gap partially verified."
3. The next scoping revision should explicitly acknowledge `estdaR` and remove any language implying no R implementation exists.
