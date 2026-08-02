"""Optional PySAL giddy inference oracle generation.

Development infrastructure only; excluded from the package build. Run in an
environment with giddy and libpysal installed to generate static homogeneity
test fixtures for R tests. Uses the same usjoin setup as
pysal_giddy_oracle.py so the fixtures share the spatial count matrices.
"""

from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import chi2


def kullback_with_origin_margins(F: np.ndarray) -> tuple[float, int, float]:
    """Kullback conditional-homogeneity test using initial-state totals."""

    def xlogx(values: np.ndarray) -> float:
        positive = values > 0
        return float(np.sum(values[positive] * np.log(values[positive])))

    pooled = F.sum(axis=0)
    statistic = 2 * (
        sum(xlogx(regime) for regime in F)
        - sum(xlogx(regime.sum(axis=1)) for regime in F)
        - xlogx(pooled)
        + xlogx(pooled.sum(axis=1))
    )
    statistic = max(0.0, statistic)
    strata, states, _ = F.shape
    dof = states * (strata - 1) * (states - 1)
    return statistic, dof, float(chi2.sf(statistic, dof))


def main() -> None:
    try:
        import libpysal
        from giddy.markov import Spatial_Markov
    except Exception as exc:  # pragma: no cover - development helper
        raise SystemExit(f"Install libpysal and giddy first: {exc}") from exc

    f = libpysal.io.open(libpysal.examples.get_path("usjoin.csv"))
    pci = np.array([f.by_col[str(y)] for y in range(1929, 2010)]).T
    rpci = pci / pci.mean(axis=0)
    w = libpysal.io.open(libpysal.examples.get_path("states48.gal")).read()
    w.transform = "r"

    spatial = Spatial_Markov(rpci, w, fixed=True, k=5, m=5)
    kb_statistic, kb_dof, kb_p_value = kullback_with_origin_margins(spatial.T)

    out_dir = Path("tests/testthat/fixtures/pysal")
    out_dir.mkdir(parents=True, exist_ok=True)

    pd.DataFrame(
        {
            "Q": [spatial.Q],
            "Q_p_value": [spatial.Q_p_value],
            "LR": [spatial.LR],
            "LR_p_value": [spatial.LR_p_value],
            "dof": [spatial.dof_hom],
            "kullback": [kb_statistic],
            "kullback_dof": [kb_dof],
            "kullback_p_value": [kb_p_value],
        }
    ).to_csv(out_dir / "pysal_spatial_homogeneity.csv", index=False)


if __name__ == "__main__":
    main()
