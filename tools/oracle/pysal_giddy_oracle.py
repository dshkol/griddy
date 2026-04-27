"""Optional PySAL giddy oracle generation.

This script is development infrastructure only. It is intentionally excluded
from the package build. Run it in an environment with giddy and libpysal
installed to generate static fixtures for R tests.
"""

from pathlib import Path

import numpy as np
import pandas as pd


def main() -> None:
    try:
        import libpysal
        from giddy.markov import Markov, Spatial_Markov
    except Exception as exc:  # pragma: no cover - development helper
        raise SystemExit(f"Install libpysal and giddy first: {exc}") from exc

    f = libpysal.io.open(libpysal.examples.get_path("usjoin.csv"))
    pci = np.array([f.by_col[str(y)] for y in range(1929, 2010)]).T
    rpci = pci / pci.mean(axis=0)
    w = libpysal.io.open(libpysal.examples.get_path("states48.gal")).read()
    w.transform = "r"

    classic = Markov(pd.qcut(rpci.flatten(), 5, labels=False, duplicates="drop").reshape(rpci.shape))
    spatial = Spatial_Markov(rpci, w, fixed=True, k=5, m=5)

    out_dir = Path("tests/testthat/fixtures/pysal")
    out_dir.mkdir(parents=True, exist_ok=True)

    pd.DataFrame(classic.transitions).to_csv(out_dir / "pysal_classic_counts.csv", index=False)
    pd.DataFrame(classic.p).to_csv(out_dir / "pysal_classic_probabilities.csv", index=False)

    for idx, matrix in enumerate(spatial.T, start=1):
        pd.DataFrame(matrix).to_csv(out_dir / f"pysal_spatial_counts_lag_{idx}.csv", index=False)
    for idx, matrix in enumerate(spatial.P, start=1):
        pd.DataFrame(matrix).to_csv(out_dir / f"pysal_spatial_probabilities_lag_{idx}.csv", index=False)


if __name__ == "__main__":
    main()
