# OpenPulse-Consistent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `openpulse_consistent` physics profile to PipePulse, validate it against the current Workbench modal family, and only then perform a joint boundary-condition identification against both modal and 1-8 harmonic response data.

**Architecture:** Keep the existing Timoshenko/HBM structure and `endpoint_constrained` pressure field. Add focused switches for OpenPulse-style fluid added mass, thin-wall capped-end pressure loading, pressure-consistent prestress/geometric stiffness, and corrected liquid sound speed. Preserve all legacy behavior behind existing/default profiles for exact regression comparison.

**Tech Stack:** MATLAB source, Python regression tests/mirror calculations, SciPy-based identification mirror, GitHub feature branch.

**Spec:** `docs/superpowers/specs/2026-09-02-openpulse-consistent-design.md`

## Global Constraints

- Do not change HBM interfaces or nonlinear-force code.
- Do not introduce harmonic-specific multipliers.
- Do not use the 1.62 pressure amplification.
- Keep `cfg.fluid.pressure_field_model = 'endpoint_constrained'` during this implementation.
- Do not use propagation-loss calibration.
- Do not merge automatically to `main` before validation review.

---

### Task 1: Add OpenPulse-compatible fluid added mass

**Files:**
- Modify: `src/timoshenko_beam_element.m`
- Modify: `example_case.m`
- Create/Test: `tests_py/test_openpulse_consistent_profile.py`

**Interfaces:**
- Consumes: existing fluid density/internal area values.
- Produces: `cfg.structural.fluid_mass_model = 'legacy' | 'openpulse_translational'`.

- [ ] **Step 1: Write failing tests** asserting that the new profile exists and selects `openpulse_translational`, while the legacy default remains unchanged.
- [ ] **Step 2: Run the new test** and confirm it fails because the configuration/branch does not exist.
- [ ] **Step 3: Implement the minimum mass-matrix branch** so fluid mass contributes only to XYZ translational consistent mass in `openpulse_translational`; do not add fluid rotary inertia in that branch.
- [ ] **Step 4: Run the new tests and existing regression tests** and require all to pass.
- [ ] **Step 5: Commit** with message `feat: add OpenPulse translational fluid mass model`.

### Task 2: Implement the OpenPulse thin-wall capped-end dynamic pressure resultant

**Files:**
- Modify: `src/pressure_to_structure_load.m`
- Modify: `src/wall_pressure_axial_resultant.m`
- Modify: `example_case.m`
- Test: `tests_py/test_wall_stress_pressure_coupling.py`
- Test: `tests_py/test_openpulse_consistent_profile.py`

**Interfaces:**
- Consumes: complex nodal pressure, Di, Do, nu, external pressure, capped-end flag.
- Produces: OpenPulse-equivalent local axial nodal resultant for `thin_wall` and `thick_wall` branches.

- [ ] **Step 1: Add a failing thin-wall unit test** using the exact OpenPulse source equation:

```text
sigma_axial = (p_i*Di^2 - p_o*Do^2)/(Do^2-Di^2)
N = A_wall*(capped_end*sigma_axial - nu*p_i*(Do/(Do-Di)-1))
```

- [ ] **Step 2: Run the focused test** and observe failure.
- [ ] **Step 3: Implement the thin-wall branch** without adding a separate `pAi` term.
- [ ] **Step 4: Add a regression check** that `control_volume` remains bitwise/numerically unchanged and the previous thick-wall branch still reproduces its reference result.
- [ ] **Step 5: Run focused + full tests** and require all to pass.
- [ ] **Step 6: Commit** with message `feat: add OpenPulse thin-wall pressure coupling`.

### Task 3: Add OpenPulse zero-flow liquid wave-speed profile

**Files:**
- Modify: `src/solve_fluid_harmonic.m` or the existing acoustic-property helper used by it.
- Modify: `example_case.m`
- Test: `tests_py/test_openpulse_consistent_profile.py`

**Interfaces:**
- Produces: `cfg.fluid.wave_speed_model = 'legacy' | 'openpulse_compliance'`.

- [ ] **Step 1: Write a failing test** for

```text
c_corr = c_fluid/sqrt(1 + Di*Kf/(E*t))
```

using the current 13/16-mm steel/oil case.
- [ ] **Step 2: Run the test** and confirm the OpenPulse profile is absent.
- [ ] **Step 3: Implement the zero-flow branch** with `k=omega/c_corr` and `Z=rho*c_corr`; no extra Womersley attenuation in this profile.
- [ ] **Step 4: Run full regression tests** and require legacy acoustic behavior to remain selectable.
- [ ] **Step 5: Commit** with message `feat: add OpenPulse liquid compliance wave speed`.

### Task 4: Reproduce OpenPulse static pressure/stress-stiffening logic

**Files:**
- Modify: current static prestress assembly/solver file(s).
- Modify: current Timoshenko geometric-stiffness helper if needed.
- Modify: `example_case.m`
- Create/Test: `tests_py/test_openpulse_prestress.py`

**Interfaces:**
- Produces: `cfg.prestress.model = 'legacy' | 'openpulse'`.
- Uses the same pressure resultant helper as Task 2.

- [ ] **Step 1: Write failing tests** for a straight two-node element that verify the pressure resultant is the same thin-wall/capped-end quantity used by the dynamic branch.
- [ ] **Step 2: Add a failing test** for the OpenPulse axial quantity

```text
Te = E*A/L*(u2-u1) - Fp
```

and its multiplication of the existing Timoshenko geometric matrix.
- [ ] **Step 3: Run tests** and confirm failure before implementation.
- [ ] **Step 4: Implement the OpenPulse prestress branch** while keeping `legacy` untouched.
- [ ] **Step 5: Run focused and full regression tests**.
- [ ] **Step 6: Commit** with message `feat: add OpenPulse-consistent prestress model`.

### Task 5: Add the `openpulse_consistent` profile dispatcher

**Files:**
- Modify: `example_case.m`
- Modify: central config/default helper if present.
- Test: `tests_py/test_openpulse_consistent_profile.py`

**Interfaces:**
- Produces `cfg.model.physics_profile = 'openpulse_consistent'` setting:
  - `axial_fsi_model='openpulse_wall'`
  - `wall_formulation='thin_wall'`
  - `capped_end=true`
  - `fluid_mass_model='openpulse_translational'`
  - `prestress.model='openpulse'`
  - `wave_speed_model='openpulse_compliance'`
  - `pressure_field_model='endpoint_constrained'`

- [ ] **Step 1: Write failing profile-selection tests** including the no-1.62/no-propagation-loss constraints.
- [ ] **Step 2: Implement profile application** in one focused helper or existing config block.
- [ ] **Step 3: Run all tests**.
- [ ] **Step 4: Commit** with message `feat: add OpenPulse-consistent physics profile`.

### Task 6: Fixed-boundary validation gate

**Files:**
- Create: `validation/openpulse_consistent/README.md`
- Create: numerical-result CSVs/plots generated by the Python mirror.
- No production MATLAB changes unless a verified implementation bug is found.

**Interfaces:**
- Fixed boundary: `Kt=1.598676e7`, `Kr=1.237086e3`, `Ct=758.545`, `Cr=1.900684`, `zeta=0.05`.
- Workbench modes: `[71.25,402.65,413.42,880.32,905.92,1501.43,1503.75]` Hz.

- [ ] **Step 1: Reconstruct the modified formulation in the Python mirror** and verify its legacy profile still reproduces the known current baseline before trusting new results.
- [ ] **Step 2: Compute total mass and first seven prestressed modes** under `openpulse_consistent`.
- [ ] **Step 3: Compute node-49 -X acceleration for harmonics 1-8** using original/unamplified pressure.
- [ ] **Step 4: Compute dynamic load norms/phases** versus legacy `control_volume`.
- [ ] **Step 5: Apply the gate:** if the modal family is materially degraded versus the current validated structural baseline, stop and report; do not identify boundaries.
- [ ] **Step 6: Commit validation artifacts** if the model passes the gate.

### Task 7: Joint boundary-condition identification

**Files:**
- Create/Modify: boundary-identification script used for Python mirror validation.
- Create: `validation/openpulse_consistent/identified_parameters.csv`
- Create: `validation/openpulse_consistent/identified_response.csv`
- Create: `validation/openpulse_consistent/modal_after_identification.csv`
- Create: comparison stem plot.

**Interfaces:**
- Variables: `Kt, Kr, Ct, Cr, zeta`.
- Experimental amplitudes: `[0.84,0.68,0.61,0.38,0.12,0.25,0.165,0.115] g`.
- Modal reference: Workbench seven-mode vector above.

- [ ] **Step 1: Define a bounded log-parameter objective** that combines log-amplitude error and normalized modal-frequency error; use one common parameter set for all harmonics.
- [ ] **Step 2: Run a local solve from the previous preferred boundary** and record bound hits.
- [ ] **Step 3: Run an independent global/secondary search** to reduce local-minimum risk.
- [ ] **Step 4: Recompute 1-8 response, RMSE, relative RMSE, MAPE, modal error, and parameter ratios** at the selected optimum.
- [ ] **Step 5: Reject the identified solution** if it reaches clearly nonphysical bounds or destroys modal agreement merely to improve spectral fit.
- [ ] **Step 6: Save results and plot** using the preferred stem-spectrum style.
- [ ] **Step 7: Commit** with message `validation: identify OpenPulse-consistent boundary`.

### Task 8: Final verification and report

**Files:**
- Create: `validation/openpulse_consistent/report.md`
- Modify: README only if the new profile is recommended after validation.

- [ ] **Step 1: Run the full Python regression suite fresh.**
- [ ] **Step 2: Verify no HBM files changed.**
- [ ] **Step 3: Search the branch for forbidden `harmonic_scale`, extra `1.62`, or propagation-loss tuning in the OpenPulse profile.**
- [ ] **Step 4: Compare feature branch to base and inspect all changed files.**
- [ ] **Step 5: Write the final report** covering physics changes, modal results, 1-8 harmonic results, identification parameters, bound hits, and recommendation on whether to promote the profile.
- [ ] **Step 6: Do not merge to `main`; present the results for review.**
