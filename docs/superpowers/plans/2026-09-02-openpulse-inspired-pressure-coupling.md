# OpenPulse-inspired Pressure Coupling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a physics-based selectable pressure-to-structure coupling model inspired by OpenPulse while keeping the current linear `endpoint_constrained` pressure field and preserving HBM.

**Architecture:** Keep pressure-field generation and structural load conversion separate. `solve_fluid_harmonic.m` continues to produce complex nodal pressure; `pressure_to_structure_load.m` dispatches to either the existing `simple_thrust` model or a new `wall_stress_coupling` helper that computes endpoint axial wall resultants from geometry, Poisson ratio, external pressure, capped-end condition, and thin/thick-wall formulation. Existing configs remain backward compatible and HBM consumes the same harmonic load-vector interface.

**Tech Stack:** MATLAB, existing PipePulse Timoshenko FEM/AFT-HBM code, Python static/regression tests where MATLAB runtime is unavailable.

**Spec:** `docs/superpowers/specs/2026-09-02-openpulse-inspired-pressure-coupling-design.md`

## Global Constraints

- Keep `cfg.fluid.pressure_field_model = 'endpoint_constrained'` for the current 2.8 case.
- Do not introduce harmonic-dependent scale factors or experimental fitting.
- Missing `cfg.coupling.pressure_load_model` must preserve the legacy `simple_thrust` behavior.
- Preserve HBM interfaces and nonlinear equations.
- Do not change `Kt`, `Kr`, `Ct`, `Cr`, pressure harmonics, or damping to improve agreement during this task.
- New physics must depend only on material, geometry, pressure, external pressure, and end-condition parameters.

---

### Task 1: Add regression tests for pressure-load model dispatch

**Files:**
- Modify: `tests_py/test_package.py`
- Modify later: `src/pressure_to_structure_load.m`

**Interfaces:**
- Consumes: existing `pressure_to_structure_load(mesh,cfg,fluidSol)`.
- Produces: regression expectations that absent/explicit `simple_thrust` use the current `-p*A_i*t/+p*A_i*t` implementation and that a `wall_stress_coupling` branch exists.

- [ ] **Step 1: Write the failing tests**

Add source-level regression checks that require:

```python
text = (ROOT / "src" / "pressure_to_structure_load.m").read_text(encoding="utf-8")
assert "pressure_load_model" in text
assert "simple_thrust" in text
assert "wall_stress_coupling" in text
```

Also retain checks for the legacy force expressions:

```python
assert "f1 = -p1*A*t" in text
assert "f2 = +p2*A*t" in text
```

- [ ] **Step 2: Run the test to verify RED**

Run:

```bash
python -m pytest -q tests_py/test_package.py
```

Expected: FAIL because `pressure_load_model` / `wall_stress_coupling` are not yet present.

- [ ] **Step 3: Do not implement yet; commit only after Task 2 GREEN**

The failure establishes the feature boundary for the production change.

---

### Task 2: Implement isolated wall-pressure axial resultant helper and dispatcher

**Files:**
- Create: `src/wall_pressure_axial_resultant.m`
- Modify: `src/pressure_to_structure_load.m`
- Test: `tests_py/test_package.py`

**Interfaces:**
- Produces:

```matlab
N = wall_pressure_axial_resultant(p, Di, Do, nu, external_pressure, capped_end, wall_formulation)
```

where `p` may be complex and `N` has the same scalar/array shape as `p`.

- [ ] **Step 1: Extend the failing tests for the helper formula**

Require the helper file to contain the thick-wall expression:

```matlab
Aw = pi/4*(Do^2-Di^2);
sigma_axial = (p*Di^2 - external_pressure*Do^2)/(Do^2-Di^2);
N = Aw*(capped_end - 2*nu)*sigma_axial;
```

and a thin-wall branch using the OpenPulse-style expression:

```matlab
stress_axial = (p*Di^2 - external_pressure*Do^2)/(Do^2-Di^2);
N = Aw*(capped_end*stress_axial - nu*p*(Do/(Do-Di)-1));
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
python -m pytest -q tests_py/test_package.py
```

Expected: FAIL because the helper does not exist.

- [ ] **Step 3: Implement the minimal helper**

Create `src/wall_pressure_axial_resultant.m` with strict validation for:

```matlab
wall_formulation = lower(string(wall_formulation));
```

Accepted values: `"thick_wall"`, `"thin_wall"` only. Reject `Do <= Di`, non-finite `nu`, and unsupported formulations with explicit `PipePulse:` error IDs.

- [ ] **Step 4: Add dispatcher in `pressure_to_structure_load.m`**

Resolve model as:

```matlab
if isfield(cfg.coupling,'pressure_load_model') && ~isempty(cfg.coupling.pressure_load_model)
    loadModel = lower(string(cfg.coupling.pressure_load_model));
else
    loadModel = "simple_thrust";
end
```

For `simple_thrust`, leave the current lines unchanged.

For `wall_stress_coupling`, compute `N1`, `N2` from the helper and assemble:

```matlab
f1 = -N1*t;
f2 = +N2*t;
```

Read `nu` from `cfg.solid.nu`, external pressure from `cfg.coupling.external_pressure` with default `0`, capped-end from `cfg.coupling.capped_end` with default `true`, and formulation from `cfg.coupling.wall_formulation` with default `"thick_wall"`.

- [ ] **Step 5: Run tests to verify GREEN**

Run:

```bash
python -m pytest -q tests_py/test_package.py
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/wall_pressure_axial_resultant.m src/pressure_to_structure_load.m tests_py/test_package.py
git commit -m "feat: add wall stress pressure coupling"
```

---

### Task 3: Expose configuration without changing the pressure field

**Files:**
- Modify: `example_case.m`
- Modify: `README.md`
- Test: `tests_py/test_package.py`

**Interfaces:**
- Produces these configuration keys:

```matlab
cfg.coupling.pressure_load_model = 'wall_stress_coupling';
cfg.coupling.wall_formulation = 'thick_wall';
cfg.coupling.capped_end = true;
cfg.coupling.external_pressure = 0;
```

- [ ] **Step 1: Write the failing config test**

Require `example_case.m` to explicitly include the four fields above and still include:

```matlab
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

- [ ] **Step 2: Run RED test**

Run:

```bash
python -m pytest -q tests_py/test_package.py
```

Expected: FAIL because the new config is absent.

- [ ] **Step 3: Add the configuration block**

Place it beside the existing `cfg.coupling.include_momentum` / viscous-shear settings. Do not alter pressure coefficients, boundary constants, or damping.

- [ ] **Step 4: Document both pressure-load models in README**

Document that `simple_thrust` is legacy/backward compatible and `wall_stress_coupling` is the new physics-first current example selection. State explicitly that this change does not add per-harmonic calibration.

- [ ] **Step 5: Run GREEN test and commit**

Run:

```bash
python -m pytest -q tests_py/test_package.py
```

Expected: PASS.

Commit:

```bash
git add example_case.m README.md tests_py/test_package.py
git commit -m "docs: expose pressure coupling model"
```

---

### Task 4: Numerical A/B diagnostic for the current 2.8 case

**Files:**
- Create: `validation/pressure_coupling_comparison.md`
- Create locally/generated: `validation/pressure_coupling_node49.csv`
- Create locally/generated: `validation/pressure_coupling_whole_pipe.csv`

**Interfaces:**
- Consumes the same geometry, pressure harmonics, `Kt/Kr/Ct/Cr`, damping, and `endpoint_constrained` field for both load models.
- Produces per-harmonic load-norm ratios and response comparisons at node 49 and across all 112 nodes.

- [ ] **Step 1: Compute the analytical thick-wall force ratio for the current pipe**

For `external_pressure=0`, `capped_end=true`:

```text
N/(p*Ai) = Aw*(1-2*nu)*(Di^2/(Do^2-Di^2)) / Ai
```

Record the expected geometry/material-only ratio before running the dynamic model.

- [ ] **Step 2: Run the Python mirror for `simple_thrust`**

Reproduce the existing current baseline at node 49. Treat mismatch from the known baseline as a test failure before comparing the new model.

- [ ] **Step 3: Run the same mirror for `wall_stress_coupling`**

Change only the pressure-to-structure axial resultant. Keep all harmonic pressures and structural parameters identical.

- [ ] **Step 4: Export diagnostics**

For each harmonic export:

```text
order, frequency_Hz, simple_load_norm_N, wall_load_norm_N, load_ratio,
simple_node49_g, wall_node49_g, response_ratio
```

For all nodes export per-harmonic mean/max response and dominant-order counts.

- [ ] **Step 5: Compare to experiment diagnostically**

Report RMSE/MAPE for both models, but do not tune any parameter based on the result.

- [ ] **Step 6: Write `validation/pressure_coupling_comparison.md`**

State whether the new model improves physical generality, how much it changes force magnitude, and whether current experimental fit improves or worsens. Flag that experimental fit is not an acceptance criterion.

---

### Task 5: HBM and package regression

**Files:**
- Modify only if required by a failing test: `src/solve_pipepulse_hbm.m`, `run_hbm.m`, `run_hbm_sweep.m`
- Test: `tests_py/test_package.py`

**Interfaces:**
- HBM continues to consume `linearResult.F(:,h)` / existing linear harmonic load vectors; no new HBM API is permitted.

- [ ] **Step 1: Add regression assertions**

Require HBM entry points and AFT files to remain present and verify no new pressure-coupling-specific branch is inserted into the nonlinear solver.

- [ ] **Step 2: Run full tests**

Run:

```bash
python -m pytest -q tests_py
```

Expected: all tests PASS.

- [ ] **Step 3: Inspect changed files**

Confirm no frequency-dependent factors, no modification to harmonic pressure coefficients, no `propagation_loss_scale` tuning, and no boundary re-identification.

- [ ] **Step 4: Commit regression/documentation results**

```bash
git add validation README.md tests_py src example_case.m
git commit -m "test: validate wall stress pressure coupling"
```

---

### Task 6: Review gate before making the new model a repository-wide default

**Files:**
- No production change unless separately approved.

**Interfaces:**
- Produces a recommendation only.

- [ ] **Step 1: Review Task 4 results against the spec success criteria**

Check physical parameterization, numerical stability for harmonics 1–8, legacy reproducibility, HBM preservation, and absence of per-frequency fitting.

- [ ] **Step 2: Decide one of two outcomes**

1. Keep `wall_stress_coupling` explicitly selected in the current example while legacy configs default to `simple_thrust`; or
2. Propose a separate follow-up change making `wall_stress_coupling` the global default.

Do not silently make outcome 2 in this implementation.
