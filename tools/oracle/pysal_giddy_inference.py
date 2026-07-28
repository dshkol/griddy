"""Optional PySAL giddy inference oracle generation.

Development infrastructure only; excluded from the package build. Run in an
environment with giddy and libpysal installed to generate static homogeneity
test fixtures for R tests. Uses the same usjoin setup as
pysal_giddy_oracle.py so the fixtures share the spatial count matrices.
"""

from pathlib import Path

import numpy as np
import pandas as pd


def main() -> None:
    try:
        import libpysal
        from giddy.markov import Spatial_Markov, kullback
    except Exception as exc:  # pragma: no cover - development helper
        raise SystemExit(f"Install libpysal and giddy first: {exc}") from exc

    f = libpysal.io.open(libpysal.examples.get_path("usjoin.csv"))
    pci = np.array([f.by_col[str(y)] for y in range(1929, 2010)]).T
    rpci = pci / pci.mean(axis=0)
    w = libpysal.io.open(libpysal.examples.get_path("states48.gal")).read()
    w.transform = "r"

    spatial = Spatial_Markov(rpci, w, fixed=True, k=5, m=5)
    kb = kullback(spatial.T)

    out_dir = Path("tests/testthat/fixtures/pysal")
    out_dir.mkdir(parents=True, exist_ok=True)

    pd.DataFrame(
        {
            "Q": [spatial.Q],
            "Q_p_value": [spatial.Q_p_value],
            "LR": [spatial.LR],
            "LR_p_value": [spatial.LR_p_value],
            "dof": [spatial.dof_hom],
            "kullback": [kb["Conditional homogeneity"]],
            "kullback_dof": [kb["Conditional homogeneity dof"]],
            "kullback_p_value": [kb["Conditional homogeneity pvalue"]],
        }
    ).to_csv(out_dir / "pysal_spatial_homogeneity.csv", index=False)


if __name__ == "__main__":
    main()
