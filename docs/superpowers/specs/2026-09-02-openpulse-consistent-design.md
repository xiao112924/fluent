# OpenPulse-consistent design

Date: 2026-09-02
Repository: `xiao112924/fluent`
Branch: `feature/wall-stress-pressure-coupling`

## Goal

Revise PipePulse using OpenPulse source-supported structural/acoustic formulations without harmonic-specific fitting, while preserving the current stable `endpoint_constrained` pressure field for the first validation stage.

## Source-supported OpenPulse behavior to reproduce

1. Pipe and bend defaults use `wall_formulation = thin`, `capped_end = true`.
2. Dynamic acoustic-to-structural load for pipe elements uses the thin-wall branch from `force_vector_acoustic_gcs`.
3. Static pressure load for stress stiffening uses the same thin/thick wall and capped-end formulation through `force_vector_stress_stiffening`.
4. Geometric stiffness uses the OpenPulse axial quantity
   `Te = E*A/L*(u2-u1) - Fp`,
   then multiplies the Timoshenko geometric matrix.
5. Internal fluid added mass contributes to the translational inertia block only; no additional fluid rotary inertia is added by OpenPulse.
6. `damped_liquid` with zero volumetric flow rate reduces to undamped propagation with pipe-wall-compliance-corrected sound speed.
7. Global viscous damping uses `C = alpha*M + beta*K`; the current 5% Rayleigh setup can therefore be mapped directly.

## First-stage PipePulse model

Add a new explicit compatibility mode:

```matlab
cfg.model.physics_profile = 'openpulse_consistent';
```

This profile sets:

```matlab
cfg.coupling.axial_fsi_model = 'openpulse_wall';
cfg.coupling.wall_formulation = 'thin_wall';
cfg.coupling.capped_end = true;
cfg.coupling.external_pressure = 0;
cfg.structural.fluid_mass_model = 'openpulse_translational';
cfg.prestress.model = 'openpulse';
cfg.fluid.wave_speed_model = 'openpulse_compliance';
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

The pressure field remains `endpoint_constrained` during this stage so the known double-hard-pressure near-half-wave seventh-harmonic artifact is not reintroduced.

## Dynamic pressure load

For thin wall and capped end:

```text
sigma_axial = (p_i*Di^2 - p_o*Do^2)/(Do^2-Di^2)
N = A_wall * (sigma_axial - nu*p_i*(Do/(Do-Di)-1))
```

The element local axial load vector is `[-N1, +N2]` transformed to global coordinates. No extra `pAi` load is added in this profile.

## Fluid added mass

OpenPulse-consistent profile adds `rho_f*Ai` only to the three translational inertial terms. Existing PipePulse fluid rotary-inertia contribution remains available under the legacy profile for A/B comparison.

## Static prestress and geometric stiffness

Static mean pressure uses the same thin-wall/capped-end pressure resultant as the dynamic branch. The static equilibrium is solved with the actual end stiffnesses. The geometric axial quantity is

```text
Te = E*A/L * (u2-u1) - Fp
```

where `Fp` is the local pressure-induced axial resultant from the same OpenPulse wall formula. The existing Timoshenko geometric matrix shape is retained, but scaled by `Te/L` consistently with the OpenPulse source formulation.

## Wave speed

With zero mean flow:

```text
c_corr = c_fluid / sqrt(1 + Di*Kf/(E*t))
k = omega/c_corr
Z = rho_f*c_corr
```

No Womersley/empirical propagation attenuation is added in `openpulse_consistent` when mean flow is zero.

## Validation gate

Before any boundary identification, fix the previously preferred boundary:

- Kt = 1.598676e7 N/m
- Kr = 1.237086e3 N*m/rad
- Ct = 758.545 N*s/m
- Cr = 1.900684 N*m*s/rad
- zeta = 5%

Then compare:

1. total mass;
2. first seven prestressed structural modes against Workbench `[71.25, 402.65, 413.42, 880.32, 905.92, 1501.43, 1503.75]` Hz;
3. node-49 -X acceleration for harmonics 1-8;
4. dynamic load norms and phases versus the current legacy model;
5. numerical stability and absence of NaN/singularity.

Boundary identification proceeds only if the modal family is not materially degraded.

## Boundary identification objective

Identify one common set `Kt, Kr, Ct, Cr, zeta` for all eight harmonics. Use a joint objective combining response-amplitude mismatch and modal mismatch so the optimizer cannot improve spectral fit by destroying the structural modal family.

No harmonic-specific amplitude multipliers, no 1.62 scale, no propagation-loss tuning, and no HBM changes are permitted.

## Deliverables

- new `openpulse_consistent` profile;
- regression/unit tests;
- fixed-boundary modal and 1-8 harmonic comparison;
- joint boundary identification if modal gate passes;
- report with identified parameters, bound hits, per-order errors, RMSE, relative RMSE, MAPE, and post-identification modal comparison;
- no automatic merge to `main` before review.
