# griddy 0.2.0

## Test environments

* local macOS Sequoia 15.4.1, R 4.5.0
* GitHub Actions:
  * macOS latest, R release
  * Windows latest, R release
  * Ubuntu latest, R devel
  * Ubuntu latest, R release
  * Ubuntu latest, R oldrel-1

## R CMD check results

0 errors | 0 warnings | 0 notes

## Submission

This release adds expected sojourn times, mean first-passage times, scalar
Markov mobility indices, and tests of whether transition dynamics differ
across regimes. It also speeds up transition tabulation and spatial-lag
computation, and fixes `spatial_markov()`, which matched spatial weights to
units by row position and so gave wrong results without an error when the
weights were not sorted by unit id. It now matches them by id. Existing calls
keep working; where the weights carry no ids, `spatial_markov()` still matches
by position and now warns. There are no other changes to existing interfaces
or outputs.

## Reverse dependencies

The current CRAN index reports no reverse dependencies.

# griddy 0.1.0 

## Test environments

* local macOS Sequoia 15.4.1, R 4.5.0
* GitHub Actions:
  * macOS latest, R release
  * Windows latest, R release
  * Ubuntu latest, R devel
  * Ubuntu latest, R release
  * Ubuntu latest, R oldrel-1

## R CMD check results

0 errors | 0 warnings | 0 notes

## Submission

Initial release for griddy, a tidy/sf-oriented port of PySAL's giddy. 

## Reverse dependencies

The current CRAN index reports no reverse dependencies.
