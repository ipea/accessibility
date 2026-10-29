## Submission

This is a minor release (1.6.0). It fixes several bugs (notably in
`constrained_accessibility()` with grouped data and multiple decay values,
and integer overflow with large counts) and includes a few documented
breaking changes in edge cases (e.g. `NA` opportunities are now treated as 0
and integer inputs return doubles). See NEWS.md.

## R CMD check results

── R CMD check results ─────────────────────────────────────────────────── accessibility 1.6.0 ────
Duration: 2m 25.9s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## Test environments

- local: Windows 11, R 4.5.1
- win-builder: R-devel, R-release (TODO)
- GitHub Actions: ubuntu-latest (devel, release, oldrel), macOS-latest
  (release), windows-latest (release) (TODO: confirm green)

## Notes

- Package maintainer changed from Daniel Herszenhut to Rafael Pereira

## Reverse dependencies

We checked the one reverse dependency, r5r (Suggests). It only calls
`cumulative_cutoff()` in a vignette chunk that is not evaluated, so it is not
affected by this release.
