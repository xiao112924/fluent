# OpenPulse-consistent validation and boundary identification

## Implemented physics

The feature branch now contains an `openpulse_consistent` profile with:

- Timoshenko pipe structure retained.
- Fluid added mass mapped to translational DOFs in the OpenPulse style.
- Dynamic pressure-to-structure load using OpenPulse thin-wall, capped-end wall resultant.
- Static pressure load using the same wall resultant.
- Prestress axial quantity `Te = EA/L*(u2-u1) - Fp`.
- OpenPulse wall-compliance liquid wave-speed branch.
- `endpoint_constrained` pressure field retained.
- No harmonic-specific multipliers, no 1.62 scaling, and no propagation-loss tuning.

## Structural validation gate

The Workbench modal vector was produced with the Stage-C supports (`Kt=1.565e8 N/m`, `Kr=241.7 N*m/rad`), so it is not used as an identification objective for a different candidate support.

Using the same Stage-C supports:

| Mode | Workbench Hz | Legacy Hz | OpenPulse-consistent Hz | OpenPulse error |
|---:|---:|---:|---:|---:|
| 1 | 71.25 | 72.39 | 72.49 | +1.74% |
| 2 | 402.65 | 415.07 | 415.15 | +3.10% |
| 3 | 413.42 | 422.16 | 422.27 | +2.14% |
| 4 | 880.32 | 901.04 | 901.22 | +2.37% |
| 5 | 905.92 | 936.78 | 937.14 | +3.45% |
| 6 | 1501.43 | 1523.96 | 1524.62 | +1.54% |
| 7 | 1503.75 | 1539.39 | 1540.18 | +2.42% |

The OpenPulse-consistent mass/prestress changes alter the legacy Stage-C modal family by less than 0.14% per mode. Therefore the structural implementation passes the modal-consistency gate.

Total filled-pipe mass in the mirror remains approximately `0.329901 kg`.

## Fixed preferred boundary response

With `Kt=1.598676e7`, `Kr=1.237086e3`, `Ct=758.545`, `Cr=1.900684`, `zeta=5%`:

`[0.280375, 0.221682, 0.109752, 0.063000, 0.045677, 0.097752, 0.083381, 0.027736]` g

## Unified boundary identification

Selected global+local result:

- `Kt = 7.387163e+06 N/m`
- `Kr = 3.782186e+03 N*m/rad`
- `Ct = 1.000863e+00 N*s/m`
- `Cr = 4.147849e+00 N*m*s/rad`
- `zeta = 0.00050192 = 0.0502%`

Response:

`[0.309972, 0.329007, 0.109799, 0.138787, 0.040825, 0.138342, 0.127942, 0.065166]` g

Metrics:

- RMSE = `0.303130 g`
- Relative RMSE = `57.15%`
- MAPE = `54.58%`

The optimizer pushes `Ct` essentially to its lower bound (~1 N*s/m) and `zeta` essentially to its lower bound (~0.05%). This is a compensation signature rather than a credible physical identification.

## Decision

`openpulse_consistent` should remain a diagnostic/comparison profile, not the default predictive profile.

OpenPulse's smaller wall-resultant load is intended to operate with its own acoustic FETM pressure solution and acoustic boundary impedances. Pairing that structural load with the bounded linear `endpoint_constrained` pressure field under-excites the current experiment. The boundary parameters cannot repair the missing excitation transfer without becoming nonphysical.

The next physically justified improvement is acoustic source/termination impedance modeling using independently known impedance/flow information, not another pressure multiplier and not per-harmonic fitting.

Numerical validation here uses a Python mirror because native MATLAB is unavailable.
