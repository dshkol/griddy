# AGENTS.md

Guidance for AI coding agents contributing to griddy. If you are *using*
griddy on behalf of a user rather than developing it, read the
[usage guide for LLMs and agents](https://dshkol.github.io/griddy/articles/llm-usage.html)
instead.

## What this project is

griddy is an R package for exploratory spatial distribution dynamics on long
`sf` panels. It covers classification, classic and spatial Markov chains,
chain summaries, homogeneity tests, rank mobility, and `ggplot2` plots. The
methods come from Rey (2001), Rey, Kang, and Wolf (2016), and the literature
they build on. griddy's contribution is the R implementation: long data keyed
by explicit `id`, `time`, and `value` columns, tidy outputs, and class,
transition, and spatial-lag labels that stay attached to the results.

griddy is not a port of PySAL giddy. giddy is the validation oracle, not the
specification. Results that giddy also computes are checked against static
fixtures generated from giddy 2.3.9. griddy's API follows R and `sf`
conventions, and it deliberately differs from giddy where giddy is wrong (see
the Kullback test in `?homogeneity_test`). Do not describe griddy as a port,
and do not frame changes as "giddy compatibility".

## Commands

```r
devtools::load_all()
devtools::test()                      # all tests
devtools::test(filter = "inference")  # tests/testthat/test-inference.R
devtools::document()                  # after any roxygen change
devtools::check()                     # must report 0 errors, 0 warnings, 0 notes
pkgdown::check_pkgdown()              # every exported topic is in _pkgdown.yml
pkgdown::build_site()                 # see "Website" below
```

Without an R session tool, use `Rscript -e "..."`.

## Architecture

- `R/classify.R`: `classify_dynamics()`.
- `R/markov.R`: `markov_dynamics()`, `transition_matrix()`, `steady_state()`,
  `class_intervals()`, `lag_intervals()`.
- `R/spatial-markov.R`: `spatial_markov()`.
- `R/ergodic.R`: `sojourn_time()`, `first_passage()`, `mobility_index()`.
- `R/inference.R`: `homogeneity_test()`, with the Pearson Q, likelihood-ratio,
  and Kullback tests.
- `R/rank-mobility.R`: `rank_mobility()`.
- `R/plots.R`: `plot_transition_matrix()`, `plot_spatial_markov()`,
  `plot_rank_mobility()`.
- `R/data.R`: the bundled `usjoin` panel.
- `tools/oracle/`: scripts that generate validation fixtures from PySAL giddy
  (Python) and from estdaR and spdyn (R).

## Conventions that matter

- **Fixtures.** Validation fixtures live in `tests/testthat/fixtures/`, which
  is Rbuildignored, as is `tests/testthat/test-oracles-optional.R`. Only that
  file may read fixtures. A shipped test that reads a fixture passes
  `devtools::test()` but fails `R CMD check` on the built tarball.
- **Regenerating giddy fixtures.** Run `tools/oracle/pysal_giddy_*.py` from the
  repository root, in a virtual environment with `giddy==2.3.9`, `libpysal`,
  `pandas`, and `scipy`. Check the diff: values that should not change must
  come out byte-identical.
- **New statistics** need a reference value from a publication or an oracle in
  a test, not only a self-consistency check.
- **Documentation.** Every exported function has roxygen documentation and an
  entry in `_pkgdown.yml`. Run `devtools::document()` after editing roxygen.
- **Style.** Base pipe `|>` only. Tidy evaluation for `id`, `time`, and
  `value` arguments.
- **NEWS.md.** Add a bullet for every user-facing change under the version
  being developed.

## Website

- The site deploys from the committed `docs/` folder on `main`. Rebuild it
  with `pkgdown::build_site()` and commit `docs/`.
- A complete build needs `CENSUS_API_KEY` (tidycensus), `CM_API_KEY`
  (cancensus), and estdaR installed. Without them, the census articles and the
  estdaR benchmark render without output, and committing that build removes
  them from the live site.
- pkgdown renders every `.md` file in the repository root as a site page,
  whatever `.gitignore` and `.Rbuildignore` say. Keep working notes, drafts,
  and briefs in the gitignored `notes/` folder. Before committing a rebuild,
  check `git status docs` for pages that should not be there.
- pkgdown 2.2.0 and later also writes `llms.txt` and a Markdown copy of every
  page.

## Writing

- User-facing prose in vignettes, articles, help pages, and NEWS follows
  `vignettes/articles/giddy-coverage.Rmd`: short declarative sentences,
  concrete specifics, attribution stated once.
- Cite methods precisely. The degrees-of-freedom adjustment in the
  homogeneity tests is Bickenbach and Bode (2003).

## Boundaries

- Do not open issues, pull requests, or comments on repositories other than
  dshkol/griddy, including PySAL giddy. Draft them in `notes/` and let the
  maintainer file them.
- Do not merge pull requests or push to `main` without the maintainer's
  go-ahead.
