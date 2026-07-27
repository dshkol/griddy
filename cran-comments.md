## Test environments

* local macOS Sequoia 15.4.1, R 4.5.0
* GitHub Actions:
  * macOS latest, R release
  * Windows latest, R release
  * Ubuntu latest, R devel
  * Ubuntu latest, R release
  * Ubuntu latest, R oldrel-1
* win-builder:
  * R-devel
  * R-release

## R CMD check results

0 errors | 0 warnings | 1 note

* HTML validation was skipped locally because the installed HTML Tidy is not
  recent enough.

## Submission

This is a patch release with internal performance improvements. Transition
tabulation and spatial-lag computation are vectorized (replacing per-unit and
per-period grouped operations). Outputs are unchanged and the public API is
unmodified.

## Reverse dependencies

There are currently no reverse dependencies on CRAN.
