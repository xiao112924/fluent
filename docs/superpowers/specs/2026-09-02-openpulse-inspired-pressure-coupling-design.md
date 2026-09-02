# OpenPulse-inspired pressure/structure coupling design

Date: 2026-09-02
Repository: `xiao112924/fluent`

## Goal

Improve PipePulse toward a physics-based model that can be reused for arbitrary piping geometries, without per-frequency amplitude fitting and without requiring Workbench calibration for every new case.

The first implementation must keep the current `endpoint_constrained` pressure field as the default acoustic field so that the known seventh-harmonic double-pressure-boundary resonance artifact is not reintroduced. The change focuses first on how the internal pressure field is converted into structural pipe loads.

## Reference learned from OpenPulse

OpenPulse uses a 1D acoustic formulation (FETM) and applies the resulting acoustic pressure field to a Timoshenko structural pipe model. Its structural acoustic-load routine does not reduce pressure loading to only `p*A_i`. For pipe elements it forms an axial wall stress from internal/external pressure, distinguishes capped/open-end behavior, and includes Poisson coupling. It supports both thin-wall and thick-wall formulations.

For the thick-wall pipe formulation, the OpenPulse-style equivalent axial wall stress is

\[
\sigma_{ax}=\frac{p_i D_i^2-p_o D_o^2}{D_o^2-D_i^2}
\]

and the local axial equivalent force is

\[
N_p=A_w(c_{end}-2\nu)\sigma_{ax}
\]

where `c_end=1` for capped-end behavior and `0` otherwise. The element nodal load is assembled as `[-N_p,+N_p]` in the element axial direction and then transformed to global coordinates. The thin-wall branch uses the corresponding thin-wall Poisson expression.

OpenPulse also has acoustic terminal-impedance concepts (specific/radiation impedance), but those are deliberately postponed to a later phase because the present PipePulse case has measured complex inlet and outlet pressures and a prior double-Dirichlet acoustic model generated a near-half-wave seventh-harmonic singular amplification.

## Approaches considered

### A. Directly replace the current pressure load with OpenPulse-style wall-stress coupling

Pros: smallest implementation, immediately removes the current `p*A_i` simplification.

Cons: difficult to compare old/new behavior and risky for regression because the current model is already used in existing validation cases.

### B. Add selectable structural pressure-coupling models — recommended

Keep the pressure-field model and the pressure-to-structure model as separate choices.

Add:

- `simple_thrust`: current behavior, `F1=-p1*A_i*t`, `F2=+p2*A_i*t`.
- `wall_stress_coupling`: new physically richer model using pipe-wall axial stress, Poisson effect, external pressure, capped-end option, and thin/thick-wall selection.

The default for old configurations remains backward-compatible. The current example case will explicitly select the new model only for controlled comparison before any later decision to make it the general default.

Pros: isolates the physics change, supports A/B tests, avoids hiding changes in existing cases, and provides a clean interface for future FETM pressure fields.

Cons: one extra configuration layer.

### C. Replace the full acoustic subsystem with OpenPulse-style FETM + impedance boundaries immediately

Pros: closest to OpenPulse's complete architecture.

Cons: too large for one change, requires defensible terminal acoustic impedances, and risks reintroducing the seventh-harmonic resonance artifact before the structural load formulation is validated.

Decision: implement approach B first.

## Configuration design

Add a configuration block under `cfg.coupling`:

```matlab
cfg.coupling.pressure_load_model = 'simple_thrust';
% 'simple_thrust' | 'wall_stress_coupling'

cfg.coupling.wall_formulation = 'thick_wall';
% 'thick_wall' | 'thin_wall'

cfg.coupling.capped_end = true;
cfg.coupling.external_pressure = 0;   % Pa, complex/real allowed if needed later
```

Backward compatibility rule: if `pressure_load_model` is absent, use `simple_thrust`.

No harmonic-dependent scale factors are permitted.

## Structural pressure-load model

### Legacy simple thrust

For each beam element:

\[
\mathbf f_1=-p_1 A_i\mathbf t,
\qquad
\mathbf f_2=+p_2 A_i\mathbf t.
\]

This remains unchanged for regression.

### New wall-stress coupling

For each element endpoint `j=1,2`, use its local complex internal pressure `p_j` and external pressure `p_o`.

Pipe-wall area:

\[
A_w=\frac{\pi}{4}(D_o^2-D_i^2).
\]

For thick wall:

\[
\sigma_{ax,j}=\frac{p_jD_i^2-p_oD_o^2}{D_o^2-D_i^2}
\]

\[
N_j=A_w(c_{end}-2\nu)\sigma_{ax,j}.
\]

For thin wall, follow the OpenPulse thin-wall expression, preserving endpoint complex pressure.

The resulting nodal forces are

\[
\mathbf f_1=-N_1\mathbf t,
\qquad
\mathbf f_2=+N_2\mathbf t.
\]

Adjacent element vectors continue to cancel on straight segments and naturally produce resultant forces at bends.

## Separation of responsibilities

- `solve_fluid_harmonic.m`: pressure field only. No structural-load physics.
- `pressure_to_structure_load.m`: dispatch by pressure-load model.
- New helper(s): compute wall-pressure axial resultant per endpoint, with thin/thick-wall formulas isolated and unit-testable.
- HBM continues to consume the linear harmonic load vectors generated by the selected pressure-load model; no change to nonlinear AFT equations is required.

## Acoustic field strategy

Phase 1 retains:

```matlab
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

The model remains

\[
\hat p(s)=\hat P_{out}+\frac{s}{L}(\hat P_{in}-\hat P_{out}).
\]

This is acknowledged as an engineering approximation, not a final wave-propagation model.

A later separate phase may add an FETM acoustic solver using complex wavenumber and terminal impedance. That phase must use physically defined impedance/flow/pressure boundary conditions and must not use two ideal pressure Dirichlet conditions as a default.

## Validation plan

Implementation follows TDD.

1. Regression test: `simple_thrust` reproduces current force vectors exactly.
2. Formula test: thick-wall wall-stress result agrees with a hand-calculated straight-pipe case.
3. Formula test: thin-wall branch agrees with its analytical expression.
4. Limit/behavior test: `capped_end` and Poisson ratio change the axial force in the expected direction.
5. Geometry test: two collinear equal-pressure elements cancel internally; a bend leaves the correct vector resultant.
6. Harmonic case test: current 2.8 case runs all 1–8 harmonics without NaN/Inf.
7. HBM regression: HBM entry points still load and use the generated harmonic loads without interface breakage.
8. Compare current case at node 49 and whole-pipe statistics for `simple_thrust` vs `wall_stress_coupling`.
9. Compare both against experiment, but experimental agreement is diagnostic only; it must not determine per-harmonic parameters.

## Success criteria

The change is accepted if:

- no per-harmonic fit/scale is introduced;
- legacy model reproduces current results;
- new model is controlled entirely by geometric/material/pressure/end-condition parameters;
- the current case computes stably through 1–8 harmonics;
- HBM remains operational;
- results and force ratios are documented, even if the current experiment fit becomes worse;
- code structure leaves a clean future path for FETM/impedance acoustic boundaries.

## Explicit non-goals for this change

- No fitting of `Kt`, `Kr`, `Ct`, `Cr` to compensate for the new load formulation.
- No frequency-by-frequency correction factors.
- No artificial acoustic loss multiplier to suppress the seventh harmonic.
- No immediate replacement of `endpoint_constrained` with the earlier double-pressure acoustic BVP.
- No rewrite of the HBM nonlinear solver.
