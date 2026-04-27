# Pre-Scoping Document: `griddy`, Geospatial Distribution Dynamics for R

## Status

This document is conditional. It is not yet a full package scope brief.

The central claim is that R lacks a cohesive, modern, `sf`/tidy workflow for PySAL `giddy`-style geospatial distribution dynamics. If that claim fails, the rest of the package plan should be discarded or reframed as a contribution/tutorial, not a standalone package.

The next step is a gap audit. Only after that audit should this become a real v0.1 scope brief.

Audit pass completed on 2026-04-26. See `audit.md` for the current audit and `gap_audit.md` for supporting notes. Result: **pass on the workflow/product gap, not on a methods gap**. R has academic-supplement implementations of the methods, especially `estdaR` and `spdyn`, but no maintained, CRAN-grade, tidy/`sf`-native package for spatial distribution dynamics. The package case is an ergonomics, validation, visualization, and distribution case, not a novelty claim.

## Gap Audit First

Before package design, verify the gap directly.

Required checks:

- Inspect current `sfdep` source and docs for temporal regime-transition workflows, spatial Markov chains, and LISA Markov equivalents.
- Search CRAN, GitHub, R-universe, and package docs for "spatial Markov", "LISA Markov", "regime transition", "regional income dynamics", "Rey 2001", and "distribution dynamics".
- Check Sergio Rey's repositories and paper supplements for R reference implementations.
- Check whether examples exist in `spdep`, `sfdep`, teaching packages, dissertation repos, or chapter packages that substantially reduce the need for a package.
- Check whether `markovchain` plus existing `spdep`/`sfdep` examples already provide enough glue that a package would be thin.

Possible audit outcomes:

- **Pass:** no maintained R package covers spatial Markov and geospatial distribution dynamics as a cohesive `sf` workflow. Proceed to the applied `.Rmd` prototype and then revisit package scope.
- **Partial pass:** R has functions but not workflow, visualization, or ACS/public-data ergonomics. Consider a workflow package, pkgdown site, or `sfdep` contribution rather than a full standalone package.
- **Fail:** a maintained package or clear package family already covers the space. Do not build a standalone package; write notes, contribute upstream, or stop.

The rest of this document assumes the audit passes or partially passes.

## Reviewer Brief

This is a conditional v0.1 scoping document for a proposed R package, tentatively named `griddy`.

The package would bring a focused subset of PySAL `giddy`-style geospatial distribution dynamics workflows to R's `sf`/tidy data ecosystem. The intent is not methodological novelty. The intent is ecosystem translation, ergonomic integration, and visualization-first workflows for longitudinal spatial data.

Reviewer questions:

- Is the R gap real, or are the relevant methods already well covered by existing R packages?
- Is the v0.1 scope correctly narrow?
- Is this better as a standalone package, an extension to an existing R package, or a tutorial/workflow site?
- Should this start as a package, or as a worked `sfdep` + `markovchain` article that proves audience value first?
- Is the function surface coherent for R users?
- Is the PySAL `giddy` oracle strategy strong enough?
- What should be deferred to avoid becoming an unfocused PySAL clone?
- Are there etiquette or naming issues with building an R package inspired by `giddy`?

Push back hard. The prior is that LLM-assisted gap analyses overstate gaps, especially in mature geospatial and econometrics ecosystems.

## Context

PySAL `giddy` is a Python package for geospatial distribution dynamics: the analysis of how spatial units move through distributions over time, and how those movements relate to spatial context.

The canonical examples are regional income dynamics: states, counties, or regions are classified into income quantiles over time, and analysts ask whether places transition upward, downward, remain trapped, converge, diverge, or change spatial association regimes.

The methods are descriptive and exploratory rather than predictive. They sit between spatial exploratory data analysis, economic mobility analysis, and temporal visualization.

R has strong ingredients:

- `sf`, `terra`, `stars` for spatial data
- `spdep` and `sfdep` for spatial weights and local spatial statistics
- `markovchain` for generic Markov chain methods
- `TraMineR` for sequence analysis
- `ggplot2`, `tmap`, `gganimate`, and `plotly` for visualization
- `tidycensus` for longitudinal ACS-style public data workflows
- `spopt` for PySAL-inspired spatial optimization in R

Working hypothesis after audit: R has code that computes many of these methods, but it does not appear to have a cohesive, maintained, CRAN-grade equivalent to PySAL `giddy`: a package that treats spatial distribution dynamics as a first-class workflow with `sf` objects, tidy long data, transition matrices, spatial Markov models, regime transitions, rank mobility, and map-ready output.

This is now a workflow/product hypothesis, not a methodological-availability hypothesis. The next gate is the applied prototype: if the workflow does not feel useful to non-methodologists, a package would add little beyond existing academic implementations.

## Methodological Foundation

Primary references:

- Rey, S. J. (2001). Spatial empirics for economic growth and convergence. *Geographical Analysis*, 33(3), 195-214. https://doi.org/10.1111/j.1538-4632.2001.tb00444.x
- Rey, S. J., Kang, W., & Wolf, L. (2016). The properties of tests for spatial effects in discrete Markov chain models of regional income distribution dynamics. *Journal of Geographical Systems*, 18(4), 377-398. https://doi.org/10.1007/s10109-016-0234-x
- Kang, W., Rey, S., Stephens, P., Malizia, N., Wolf, L. J., Lumnitz, S., Gaboardi, J., Laura, J., Schmidt, C., Knaap, E., & Eschbacher, A. (2019). `pysal/giddy`: giddy 2.2.1. Zenodo. https://doi.org/10.5281/zenodo.3351744
- PySAL `giddy` documentation and notebooks: https://pysal.org/notebooks/explore/giddy/intro.html and https://pysal.org/giddy/api.html

Core method families in PySAL `giddy`:

- Classic discrete Markov chains for class transitions over time
- Spatial Markov chains, where transition probabilities are conditioned on spatial lag classes
- LISA Markov chains, where states are local Moran / Moran scatterplot regimes
- Full-rank and geographic-rank Markov methods
- Mobility measures derived from transition matrices
- Rank mobility and local indicators of mobility association
- Directional LISA rose diagrams
- Alignment-based sequence methods

## Proposed Package: `griddy`

Working name: `griddy`.

Rationale:

- Memorable and adjacent to `giddy` without reusing the same name
- Suggests grids, spatial units, and movement
- Light enough for a visualization-forward package

Risks:

- The name is derivative of `giddy`; this is acceptable only if attribution is explicit and the package is positioned as an R implementation inspired by PySAL `giddy`.
- "Griddy" also refers to a dance/celebration, which is not a technical issue but may affect searchability.

Alternative names:

- `geodynr`
- `spmobility`
- `sptransition`
- `lisadyn`

Current preference: keep `griddy` as a working name only. Re-evaluate before public commits. Do not use `spdyn`; that name is already occupied by an R-Forge package implementing exploratory space-time dynamics methods.

## Post-Audit Prototype Gate

If the audit passes or partially passes, write one worked `.Rmd` before package implementation.

Use existing R tools plus approximately 150 lines of helper functions.

Target article:

> Did this neighborhood actually move, or did its spatial context change?

The article should use a small longitudinal ACS or county/state panel and show:

- classification choices,
- classic transition matrix,
- spatial Markov conditional transition matrices,
- one transition heatmap,
- one map of class movement or rank mobility,
- enough interpretation to prove the workflow is useful to non-methodologists.

If the article is compelling and the helpers stabilize, package the helpers. If the article is a slog, the audience signal is weak and a package will not fix it.

## Packaging Path Decision

After the audit/prototype, choose one path:

1. Standalone package if the workflow is cohesive and not a natural fit for existing packages.
2. `sfdep` PR only if the prototype collapses to one or two low-level verbs. Adding spatial Markov to `sfdep` would be a real scope expansion, not a small patch.
3. Article/bookdown/pkgdown site if the value is mostly educational composition of existing tools.

The rest of this document describes the standalone package path, but that should not be treated as predetermined.

## Scope: v0.1

v0.1 should be deliberately narrow. The first release should prove that R can reproduce the most useful and most visual `giddy` workflows without trying to cover the whole package.

### 1. Tidy Classification of Spatial Units Over Time

Convert longitudinal numeric values into discrete classes suitable for transition analysis.

Supported classification modes:

- Fixed quantile classes pooled across all years
- Year-specific quantile classes
- User-supplied cutpoints
- Existing categorical states

Output should be a tidy table keyed by unit and time, with class IDs, labels, original values, and optional geometry.

### 2. Classic Markov Transition Matrices

Estimate transition counts and transition probabilities between classes over consecutive time periods.

Core outputs:

- Transition count matrix
- Transition probability matrix
- Row-normalized transition probabilities
- Initial and terminal class distributions
- Optional steady-state distribution

### 3. Spatial Markov

Condition class transitions on spatial context.

Workflow:

1. For each time period, calculate the spatial lag of the numeric value.
2. Classify spatial lags into context classes.
3. Estimate one transition matrix per spatial-lag class.
4. Compare conditional transition matrices against the pooled transition matrix.

This is the core "space matters in distributional dynamics" method and should be in v0.1 if anything beyond classic Markov is included.

### 4. Basic Rank Mobility

Compute simple rank-change diagnostics:

- Rank by value within each time period
- Change in rank between adjacent periods or endpoints
- Absolute and signed rank mobility
- Optional percentile rank mobility

This is not the full PySAL rank-method suite. v0.1 should include only the simple, useful version for maps and exploratory analysis.

### 5. Visualization Helpers

Visualization should be first-class but not dependency-heavy.

v0.1 plots:

- Transition matrix heatmap
- Spatial Markov faceted transition heatmaps
- Rank mobility map
- Optional unit trajectory plot for selected geographies

All plotting functions should return `ggplot2` objects.

### 6. Built-In Example Data

Include small, static example data:

- A compact state-level or county-level panel suitable for CRAN examples
- Geometry simplified enough to keep package size reasonable
- A variable like income, poverty, rent, population change, or unemployment

Avoid live API calls in CRAN examples. Use `tidycensus` only in vignettes or pkgdown articles.

## Scope: v0.2 Candidates

### 1. LISA Markov

Track transitions among local spatial association regimes.

States:

- High-high
- Low-low
- Low-high
- High-low
- Optionally insignificant / not classified, depending on permutation support

Initial implementation should support deterministic quadrant classification from standardized value and standardized spatial lag. Permutation-filtered significant LISA states can be included only if the implementation is straightforward through `spdep`/`sfdep`.

Core outputs:

- LISA state per unit/time
- LISA transition type per unit/time interval
- Transition count matrix
- Transition probability matrix
- Map-ready transition labels

## Scope: Explicitly Out of v0.1

- Directional LISA rose diagrams
- LISA Markov, unless the prototype shows it is trivial and audience-critical
- Full PySAL rank-method suite
- Mean first passage time
- Sequence alignment / optimal matching
- Animated maps
- Bayesian or model-based transition methods
- Spatial regression or spatial panel models
- Spatial optimization, regionalization, facility location, or route optimization
- Network-based dynamics
- Forecasting
- Automatic ACS/tidycensus data fetching
- Full PySAL `giddy` parity

These are not rejected permanently. They are deferred to keep v0.1 coherent.

## Scope: Explicitly Not This Package

- A replacement for PySAL `giddy`
- A replacement for `spdep` or `sfdep`
- A replacement for `markovchain`
- A replacement for `TraMineR`
- A spatial econometrics package
- A spatial optimization package
- A general-purpose spatiotemporal data cube package

`griddy` should compose existing R infrastructure into geospatial distribution dynamics workflows.

## Candidate Function Surface

Proposed v0.1 user-facing functions:

```r
# Classification
classify_dynamics(data, id, time, value,
                  method = c("pooled_quantile", "year_quantile", "fixed"),
                  k = 5, breaks = NULL, labels = NULL)

# Classic Markov
markov_dynamics(classes, id, time, state)
transition_matrix(x, type = c("probability", "count"))
steady_state(x)

# Spatial Markov
spatial_markov(data, id, time, value, nb,
               k = 5, lag_k = 5,
               class_method = "pooled_quantile")

# Rank mobility
rank_mobility(data, id, time, value,
              compare = c("adjacent", "endpoint"))

# Visualization
plot_transition_matrix(x)
plot_spatial_markov(x)
plot_rank_mobility(x, geometry = NULL)
```

Approximate count: 8 user-facing functions.

This is still an upper bound. If implementation pressure is high, cut `steady_state()` and trajectory-related output before cutting `spatial_markov()`.

Naming is unresolved. The example above intentionally drops the `grd_` prefix because heavy prefixing may feel unidiomatic in R and `grd` suggests raster grids. If collision risk becomes real, reconsider a prefix after the package name is final.

## Object Model

Use lightweight S3 classes, not heavy custom data containers.

Proposed classes:

- `grd_classes`: classified longitudinal observations
- `grd_markov`: transition counts/probabilities plus metadata
- `grd_spatial_markov`: list-like object containing conditional transition matrices
- `grd_rank_mobility`: rank-change table

Objects should contain ordinary tibbles/matrices internally and should be easy to inspect with `str()` and `as.data.frame()`.

No special geometry class should be required. Functions should accept `sf` objects and preserve geometry when practical, but the analytical core should work on data frames.

## Validation Strategy

Validation should be multi-layered.

### 1. PySAL `giddy` Oracle Tests

Use PySAL `giddy` as the primary development oracle.

Targets:

- Classic Markov transition counts and probabilities
- Spatial Markov conditional transition matrices
- Steady-state distributions
- Rank mobility outputs if implemented

Reference datasets:

- PySAL `usjoin.csv` state per-capita income example
- PySAL example weights used in `giddy` notebooks
- Small hand-built toy panels

Development-only Python oracle scripts can live under `tools/oracle/` during development, but should not ship as required package infrastructure. If included in the repository, they should be excluded from the CRAN build via `.Rbuildignore`.

Commit static oracle outputs as CSV/RDS fixtures after generation so ordinary R tests do not require Python, `reticulate`, or PySAL. The Python oracle should be reproducible development infrastructure, not a test-time dependency.

### 2. Hand-Checkable Toy Cases

Create small fixtures where expected outputs are obvious:

- Two classes, three units, two periods
- No transitions
- All units transition upward
- Reducible transition matrix
- Empty class rows
- Spatial lag classes with known neighbors
- Spatial lag classes with manually constructed high/low values and lags

These should form the stable core unit tests.

### 3. Cross-Package Checks

Use existing R packages for component validation:

- `markovchain` for transition matrices and steady states
- `spdep` / `sfdep` for spatial lags and local Moran components
- `estdaR::mkv()`, `estdaR::sp.mkv()`, and `estdaR::lisamkv()` as R-side prior-art comparators
- `spdyn::markov()` and `spdyn::spMarkov()` as additional R-side comparators
- Base R / `Matrix` eigen decompositions for stationary distributions

Do not make heavy packages hard dependencies unless needed.

### 4. Invariants

Core invariants:

- Transition count rows sum to observed transitions out of each class.
- Transition probability rows sum to 1 for non-empty rows.
- Empty rows are handled explicitly and documented.
- Spatial Markov conditional transition counts sum to pooled transition counts when aggregated over conditioning states.
- Rank changes sum to zero within any two-period comparison if ranks are complete and untied.
- Results are stable under row reordering when IDs and time are supplied.
- Plotting functions do not change analytical outputs.

### 5. Snapshot Tests For Plots

Use lightweight visual tests sparingly. Prefer testing plot data layers rather than rendered images.

Examples:

- transition heatmap data has expected rows/columns
- rank mobility plot uses expected rank-change values

## Architecture And Dependencies

Hard dependencies:

- R >= 4.2
- `sf`
- `dplyr`
- `tibble`
- `rlang`
- `ggplot2`
- `Matrix`

Likely imports or suggests:

- `spdep` or `sfdep` for spatial weights/lags/local Moran
- `classInt` for classification modes
- `tidyr`
- `purrr`
- `testthat`

Suggests:

- `tidycensus` for vignettes
- `tmap` for optional maps
- `ggalluvial` for optional transition-flow plots
- `reticulate` only for development/oracle workflows, not package functionality
- `knitr`, `rmarkdown`, `pkgdown`

Avoid in v0.1:

- Rust/C++ unless profiling proves a need
- Python runtime dependency
- Heavy animation stack
- Database dependencies
- Live ACS/API dependency in tests

## Vignettes And Site Strategy

CRAN-safe vignettes:

1. "Did This Neighborhood Move, Or Did Its Context Change?"
   - uses built-in small data
   - leads with an applied question rather than method names
   - shows classification, classic Markov, spatial Markov, transition heatmap, and one map

2. "Spatial Markov For R Users"
   - uses built-in geometry/weights
   - avoids live downloads

Pkgdown-only articles:

1. "Neighborhood Change With ACS And `tidycensus`"
   - live ACS/tidycensus example
   - maps class transitions and rank mobility

2. "Validating Against PySAL `giddy`"
   - explains oracle scripts and expected tolerances
   - not evaluated on CRAN

3. "Choosing Classifications"
   - pooled quantiles vs year-specific quantiles vs fixed thresholds
   - emphasizes interpretability and pitfalls

## Etiquette And Attribution

The ethical stance should be explicit.

`griddy` should state:

- Methods are established in the spatial distribution dynamics literature.
- The package is inspired by and validated against PySAL `giddy`.
- It is an R-native implementation for `sf`/tidy workflows, not a claim of methodological novelty.
- PySAL `giddy` remains the canonical Python implementation.
- Prior R-side implementations exist, especially `estdaR` and `spdyn`; `griddy` targets a maintained, user-facing, `sf`/tidy workflow rather than first implementation status.

Do not ask permission before prototyping. A prototype provides something concrete to evaluate and avoids creating unnecessary social overhead.

After a working v0.1 prototype:

- Open an issue or discussion in the PySAL `giddy` repository.
- Explain scope and attribution.
- Ask whether they have concerns about naming, compatibility claims, or validation language.
- Offer links back to PySAL documentation.

Do not try to revive `estdaR` or `spdyn` before prototyping. Both are useful prior art and validation references, but neither appears positioned to absorb a tidy/`sf`, CRAN-targeted user workflow.

If code is ported line-by-line from PySAL, license and attribution requirements become stricter. Prefer implementing from papers, docs, and observed oracle outputs rather than copying source.

## Gap Analysis

### What Seems Real After The Audit

R has the pieces but not the workflow:

- Academic R implementations exist, especially `estdaR` and `spdyn`, but they are not maintained, CRAN-grade, tidy/`sf`-native user products.
- `sfdep` and `spdep` cover spatial weights, lags, and local spatial statistics, but not transition dynamics through distributions over time.
- Generic Markov chains exist, but not applied spatial Markov workflows tied to long `sf` panels and maps.
- Sequence analysis exists, but not geospatial distribution dynamics as a named package concept.
- Visualization packages exist, but not purpose-built maps/heatmaps/trajectory plots for these methods.

### What Could Make The Gap Weak

The gap may collapse if:

- A maintained, discoverable R package already implements spatial Markov and LISA Markov cleanly for tidy/`sf` inputs.
- Existing `spdep` examples are sufficient for most users.
- The user base for descriptive regional mobility analysis is too small.
- The package becomes a thin wrapper around `spdep` and `markovchain` without enough opinionated workflow value.

### Differentiation

The package should differentiate by:

- End-to-end `sf`/tidy workflows
- `id`/`time`/`value` semantics instead of implicit matrix row and column positions
- Preserved and map-ready row identity in transition-level outputs
- Labeled transition states such as `Q1 -> Q3` or `HH -> HL`, not integer movement codes
- Surfaced value and spatial-lag cutpoints, so labels like `Lag 3` are interpretable
- Lightweight S3 objects with `print()`, `as.data.frame()`, and plotting methods instead of bare lists
- PySAL-compatible validation
- Strong visual defaults
- Clear handling of classification choices
- Public-data examples using ACS/county/tract panels
- Conservative v0.1 scope

## Relationship To Existing Packages

### PySAL `giddy`

Primary inspiration and oracle. `griddy` should not compete rhetorically; it should bridge the method family into R.

### `spopt`

Not overlapping materially. `spopt` is spatial optimization: regionalization, facility location, routing, corridors, Huff models, and market analysis. `griddy` is exploratory distribution dynamics. Avoid adding optimization features.

### `spdep` / `sfdep`

Foundational dependencies or comparators for weights, lags, and local spatial association. `griddy` should not reimplement their low-level spatial statistics unless necessary.

`sfdep` is not a direct competitor: it answers "what is the spatial relationship or local statistic now?", while `griddy` should answer "how do places move through distributions over time, and does spatial context change those movements?" It remains a possible home only if the prototype collapses to one or two low-level verbs.

### `estdaR` / `spdyn`

Prior R-side implementations and validation comparators. They cover important method pieces, including classic Markov and spatial Markov; `estdaR` also covers LISA Markov and mobility measures. Their APIs are matrix/data-frame and `listw` oriented, not long `sf`/tidy workflows, and neither appears to be a maintained CRAN-grade user product.

Concrete `estdaR` gaps that `griddy` should avoid:

- `sf` example data are stripped to wide matrices for analysis.
- Unit identity is implicit row position rather than explicit IDs.
- LISA Markov moves are integer codes rather than labeled origin-destination states.
- Spatial-lag class names do not expose cutpoints.
- Results are bare lists without S3 methods.
- Normalization is user-written boilerplate rather than a documented workflow step.
- Loading the package masks common `spdep` function names.

Treat both as prior art to cite, not competitors to dismiss or projects to revive.

### `markovchain`

Comparator for generic Markov calculations. `griddy` adds spatial conditioning, LISA states, tidy longitudinal inputs, and map-ready output.

### `TraMineR`

Potential comparator for sequence methods. v0.1 should avoid sequence alignment to prevent scope creep.

### `tidycensus`

Data source for examples, not a dependency for core functions.

## Open Design Questions

### 1. Classification Defaults

Default proposal: pooled quantiles across all time periods.

Reason: pooled cutpoints make class meanings comparable over time. Year-specific quantiles are useful for rank-relative mobility but can hide absolute change.

Need clear docs because classification choice materially changes conclusions.

### 2. Weights API

Options:

- Accept `spdep` neighbor/listw objects
- Accept sparse matrices
- Derive neighbors from `sf` geometry

Default proposal: accept `nb`/`listw` first, add geometry-derived helpers later.

Reason: avoids hiding consequential spatial-weight choices.

### 3. LISA Markov Timing

Options:

- Defer all LISA Markov work to v0.2
- Include deterministic quadrants only in v0.1
- Include permutation-filtered significant states in v0.1

Default proposal: defer LISA Markov to v0.2 unless the prototype shows it is essential to the applied story.

Reason: LISA Markov introduces significance, permutation, and quadrant-convention questions. Spatial Markov is the cleaner v0.1 centerpiece.

### 4. Stationary Distributions

Default proposal: include steady-state distributions if easy; cut mean first passage time from v0.1.

Reason: transition matrices are core; Markov diagnostics are secondary for the first release.

### 5. Plot Naming

Options:

- `plot_*()` functions
- `autoplot()` methods
- both

Default proposal: explicit `plot_*()` functions in v0.1, `autoplot()` later.

Reason: explicit names are easier for users and docs.

## Risk Register

### Gap Risk

The methods gap is already smaller than the initial prior. Mitigation: frame the project around the workflow/product gap, cite `estdaR` and `spdyn` as prior R-side work, and stop if the prototype does not produce a clearly better applied workflow.

### Scope Creep

PySAL `giddy` is broad. v0.1 must not chase full parity.

Mitigation: commit to classic Markov, spatial Markov, basic rank mobility, and minimal plots only. Treat LISA Markov as v0.2 unless the prototype proves it is essential.

### Classification Misuse

Users may overinterpret transitions created by arbitrary bins.

Mitigation: document classification choices prominently and provide sensitivity examples.

### Spatial Weights Misuse

Results depend heavily on the weights matrix.

Mitigation: require explicit weights for spatial methods in v0.1; do not silently infer queen contiguity unless the user asks.

### Etiquette Risk

PySAL maintainers may view the name or scope as too close.

Mitigation: cite heavily, avoid copying code, validate against `giddy`, engage after prototype, and rename if credible concerns arise.

### Audience Risk

The audience for geospatial distribution dynamics may be narrower than the audience for ACS MOE propagation.

Mitigation: treat audience risk as the first-order risk, not a footnote. The initial article/prototype must lead with concrete examples: neighborhood poverty trajectories, rent burden mobility, county economic convergence, urban recovery, tract-level demographic change. If those examples do not land, the package should not proceed.

## Decision Points

Before coding:

1. Complete the gap audit against `sfdep`, CRAN/GitHub/R-universe, and Rey-related R materials.
2. Build the single-file workflow prototype.
3. Decide whether `spdep` is an Import or Suggests.
4. Decide whether example data should be states, counties, or tracts.
5. Decide whether to use `griddy` or a less derivative/search-noisy name. Do not use `spdyn`.
6. Decide standalone package vs `sfdep` PR vs article/site.

Recommended decisions:

- Proceed with `griddy` only as a local working name.
- Use pooled quantiles as default classification.
- Require explicit weights for spatial methods.
- Center v0.1 on classic Markov, spatial Markov, basic rank mobility, and plots.
- Defer LISA Markov unless the prototype proves it is essential.
- Use PySAL `giddy` as development oracle but not a runtime dependency.
- Build an applied prototype before engaging PySAL maintainers or creating a public package repo.

## Minimal v0.1 Definition Of Done

The package is v0.1-ready when:

- `classify_dynamics()` handles long data and `sf` objects.
- `markov_dynamics()` reproduces PySAL classic Markov transition counts/probabilities on `usjoin`.
- `spatial_markov()` reproduces PySAL conditional transition matrices on a documented example.
- R-side checks against `estdaR` and `spdyn` are documented where their APIs support comparable inputs.
- At least one map and one transition heatmap are included in docs.
- Tests cover hand-checkable toy cases and PySAL oracle fixtures.
- README explicitly cites PySAL `giddy`, the foundational papers, and prior R implementations (`estdaR`, `spdyn`).
- No Python code is required for package use.

## Current Recommendation

This is a plausible package candidate.

It has:

- A memorable working name, though final naming is unresolved
- A known methodological foundation
- A strong Python oracle
- A likely R workflow gap
- Natural visual outputs
- Domain fit with ACS, cities, regional inequality, and neighborhood change

The gap audit supports proceeding, with precision: the methods already exist in academic R code, but not as a maintained tidy/`sf` user workflow. The remaining first-order concern is audience value. Write the applied workflow prototype next. If it is compelling, proceed with a narrow v0.1 package; if it feels like a thin wrapper or a methods exercise, stop at an article/site.
