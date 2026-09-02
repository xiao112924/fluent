# Consistent axial FSI coupling design

Date: 2026-09-02
Repository: `xiao112924/fluent`
Branch: `feature/wall-stress-pressure-coupling`

## Goal

Build a consistent axial fluid-structure interaction (FSI) formulation that separates dynamic pressure traction, pressure-induced pipe-wall axial/Poisson coupling, static prestress/geometric stiffness, and bend-direction resultants without double counting pressure contributions or using harmonic-by-harmonic fitting.

The result must remain reusable for arbitrary pipe geometries and preserve the current Timoshenko structural solver and AFT-HBM interfaces.

## What OpenPulse directly supports

The OpenPulse source shows that its acoustic solution is assembled into structural harmonic loads through `force_vector_acoustic_gcs(...)`; static stress-stiffening loads are assembled through a separate structural path. Its pipe acoustic-load routine uses internal/external pressure, capped-end state, Poisson ratio, pipe-wall area, and thin/thick-wall formulation to form an equivalent local axial structural load.

For the thick-wall branch, the structure-side quantity is

\[
\sigma_{ax}=\frac{p_iD_i^2-p_oD_o^2}{D_o^2-D_i^2},
\]

with an equivalent resultant proportional to

\[
A_w(c_{end}-2\nu)\sigma_{ax}.
\]

OpenPulse does not establish that this term should be added to a separate `p A_i` thrust term. Therefore `pA_i + N_wall` is explicitly rejected as an implementation assumption.

## PipePulse design extension

The new `consistent_fsi` model is not copied from OpenPulse. It is a PipePulse design intended to make pressure-to-structure mapping internally consistent with the existing beam/control-volume discretization.

The key principle is to distinguish fluid pressure traction from pipe-wall constitutive correction instead of treating two alternative equivalent-force formulas as additive external loads.

## Three-model reference interface

```matlab
cfg.coupling.axial_fsi_model = 'control_volume';
% 'control_volume' | 'openpulse_wall' | 'consistent_fsi'
```

### 1. `control_volume`

Legacy PipePulse reference:

\[
\mathbf f_1=-p_1A_i\mathbf t,
\qquad
\mathbf f_2=+p_2A_i\mathbf t.
\]

This remains unchanged as a regression baseline.

### 2. `openpulse_wall`

OpenPulse-inspired equivalent-load reference:

\[
\mathbf f_1=-N_{wall,1}\mathbf t,
\qquad
\mathbf f_2=+N_{wall,2}\mathbf t.
\]

This remains available for comparison. Prior identification showed that directly replacing the legacy thrust with this branch under-excites the current test case and drives identified damping toward lower bounds.

### 3. `consistent_fsi`

Recommended new model. It separates a pressure-traction term and a constitutive wall-coupling term at element level, then assembles them through one consistent operator so the same physical pressure contribution is not counted twice.

## Consistent element formulation

For a two-node beam element with unit tangent \(\mathbf t\), internal area \(A_i\), wall area \(A_w\), and complex nodal pressures \(p_1,p_2\):

### A. Pressure traction contribution

Retain the fluid control-volume traction contribution:

\[
\mathbf f^{p}_1=-p_1A_i\mathbf t,
\qquad
\mathbf f^{p}_2=+p_2A_i\mathbf t.
\]

Its assembly already has the desired geometric property: collinear internal contributions cancel and tangent changes leave a bend resultant.

### B. Wall constitutive coupling contribution

Pressure also changes pipe-wall axial strain/stress through Poisson coupling and end condition. This effect must not be added as another full `openpulse_wall` external force. Instead it is represented as an equivalent axial initial-strain contribution in the beam formulation.

Define a pressure-induced axial free strain

\[
\varepsilon_p=\frac{\sigma_{ax,p}}{E},
\]

where the pressure-induced constitutive term is derived from the same thin/thick-wall relation used in the OpenPulse reference branch, but only the constitutive part independent of the beam mechanical axial strain is retained.

The axial relation is written conceptually as

\[
N=EA(\varepsilon_{mech}-\varepsilon_p).
\]

The equivalent initial-strain vector is

\[
\mathbf f^{\varepsilon}=\int_0^L B_x^TEA\varepsilon_p\,dx.
\]

For varying complex nodal pressure, `consistent_fsi` uses linear interpolation of \(\varepsilon_p(x)\) and two-point Gauss integration. No harmonic-specific scale factor is permitted.

### C. Total dynamic load

\[
\mathbf F_{dyn}=\mathbf F^{p}+\mathbf F^{\varepsilon},
\]

where \(\mathbf F^{\varepsilon}\) is an initial-strain equivalent vector, not the prior complete `openpulse_wall` external-force vector.

This distinction is the central safeguard against double counting.

## Static prestress consistency

Static mean pressure remains separate from dynamic harmonic pressure.

The static axial force used in geometric stiffness must be derived from the same constitutive split:

1. mean pressure traction,
2. mean pressure-induced wall initial strain / axial constitutive term,
3. mechanical restraint reaction from the actual end support stiffness,
4. resulting net pipe-wall axial force used in geometric stiffness.

The static solver must not simultaneously apply a full `pA_i` end thrust and an already capped-end-inclusive wall resultant if those terms represent the same end-load physics.

A compatibility mode retains the old prestress implementation for A/B comparison.

## Configuration

```matlab
cfg.coupling.axial_fsi_model = 'consistent_fsi';
cfg.coupling.wall_formulation = 'thick_wall';
cfg.coupling.capped_end = true;
cfg.coupling.external_pressure = 0;

cfg.prestress.model = 'consistent_fsi';
% 'legacy' | 'consistent_fsi'
```

Backward compatibility:

- Missing `axial_fsi_model` -> `control_volume`.
- Missing `prestress.model` -> `legacy`.

No existing case silently changes behavior.

## Pressure field

This change does not alter the current pressure field:

```matlab
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

\[
\hat p(s)=\hat P_{out}+\frac{s}{L}(\hat P_{in}-\hat P_{out}).
\]

The known double-hard-pressure acoustic BVP / half-wave seventh-harmonic issue must not be reintroduced.

## Code boundaries

Modify:

- `src/pressure_to_structure_load.m`: dispatch `control_volume`, `openpulse_wall`, `consistent_fsi`.
- static prestress assembly/solver files: add `legacy` vs `consistent_fsi` static-pressure treatment.
- `example_case.m`: expose explicit selection.

Create focused helpers:

- `src/pressure_wall_free_strain.m`: pressure -> pressure-induced axial free strain / constitutive term.
- `src/pressure_initial_strain_load.m`: integrate the axial initial-strain equivalent nodal load for one beam element.

No HBM-specific code is added. HBM continues to consume the same assembled harmonic structural force vectors.

## Validation sequence

Validation occurs before any new boundary identification.

### Stage 1 — unit/regression tests

1. `control_volume` reproduces the current force vector exactly.
2. `openpulse_wall` reproduces the already implemented reference branch.
3. Zero pressure gives zero `consistent_fsi` dynamic load.
4. Zero Poisson coupling removes the initial-strain correction while preserving pressure traction.
5. Two collinear equal-pressure elements cancel internal pressure-traction resultants.
6. A bend leaves the expected vector pressure resultant from tangent change.
7. No harmonic-specific multiplier exists.

### Stage 2 — fixed-boundary comparison

Keep the previously preferred boundary fixed:

\[
K_t=1.598676\times10^7\,N/m,
\quad
K_r=1.237086\times10^3\,N\,m/rad,
\]
\[
C_t=758.545\,N\,s/m,
\quad
C_r=1.900684\,N\,m\,s/rad,
\quad
\zeta=5\%.
\]

Compare `control_volume`, `openpulse_wall`, and `consistent_fsi` for force norms, node-49 -X acceleration, whole-pipe mean/max response, and dominant harmonic counts for harmonics 1-8.

### Stage 3 — modal consistency

With `consistent_fsi` static prestress enabled, compare against the latest Workbench reference:

\[
71.25,\ 402.65,\ 413.42,\ 880.32,\ 905.92,\ 1501.43,\ 1503.75\;Hz.
\]

Boundary identification is forbidden if the structural modal family is materially degraded relative to the current validated baseline.

### Stage 4 — unified boundary identification

Only if Stages 1-3 pass, identify one common set

\[
K_t,K_r,C_t,C_r,\zeta
\]

against all 1-8 experimental harmonic amplitudes simultaneously. Report bound hits, per-order error, RMSE, relative RMSE, MAPE, post-identification modal frequencies, and comparison with the previous preferred boundary.

## Acceptance criteria

`consistent_fsi` is promoted only if:

1. implemented load decomposition avoids double counting;
2. no harmonic-dependent fitted factor is introduced;
3. legacy `control_volume` regression is exact;
4. HBM interfaces stay unchanged;
5. fixed-boundary modal results remain close to the validated Workbench family;
6. harmonics 1-8 compute without singular/NaN behavior;
7. boundary re-identification, if performed, does not require clearly nonphysical bound-hitting parameters merely to compensate for a globally weakened/strengthened load.

Experimental agreement is important but may not override the physical consistency checks.

## Explicit non-goals

- No `pA_i + full_openpulse_wall_force` additive model.
- No arbitrary scalar blend between models.
- No harmonic-by-harmonic fit.
- No extra 1.62 pressure scaling.
- No propagation-loss tuning.
- No return to double-pressure acoustic BVP as default.
- No HBM rewrite.
- No automatic merge to `main` before validation review.
