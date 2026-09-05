# Hydraulic Acoustic Network Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Implement a reusable nodal hydraulic-acoustic network solver and connect it to PipePulse pressure-to-structure coupling while preserving all legacy modes and HBM.

**Architecture:** Assemble a complex nodal admittance matrix from FETM pipe elements, series impedances, shunt compliances, terminations, and source equivalents. Solve pressure with mixed prescribed-pressure and flow-source conditions, then map structural-node pressures back through the existing load assembly.

**Tech Stack:** MATLAB, Python static/regression tests, SciPy/Python numerical mirror for validation.

**Spec:** `docs/superpowers/specs/2026-09-05-hydraulic-acoustic-network-design.md`

## Global Constraints

- No harmonic-by-harmonic scale factor.
- No extra 1.62 pressure multiplier.
- No fitted propagation-loss table.
- Do not change HBM interfaces/files.
- Preserve `endpoint_constrained`, `acoustic_bvp`, and `fetm_impedance`.
- Do not promote an incomplete 2.8 external-loop fit as a physical identification.

---

### Task 1: General acoustic network assembler

**Files:**
- Create `src/acoustic_network_element_admittance.m`
- Create `src/assemble_acoustic_network.m`
- Create `tests_py/test_acoustic_network_core.py`

- [ ] Add failing static/numeric tests for two-node series impedance, shunt compliance, and FETM pipe formula.
- [ ] Implement element admittance helper.
- [ ] Implement nodal assembly for pipe/series/shunt/termination elements.
- [ ] Run focused tests, then full regression.

### Task 2: Mixed acoustic source handling

**Files:**
- Create `src/apply_acoustic_network_sources.m`
- Modify `src/assemble_acoustic_network.m`
- Test `tests_py/test_acoustic_network_core.py`

- [ ] Add failing tests for prescribed pressure, volume-flow RHS injection, and Thevenin-to-Norton equivalence.
- [ ] Implement source assembly and prescribed-DOF elimination metadata.
- [ ] Verify passive source impedance requires positive real part unless explicitly marked active.

### Task 3: Automatic structural-mesh to acoustic-network conversion

**Files:**
- Create `src/build_acoustic_network_from_mesh.m`
- Test `tests_py/test_acoustic_network_topology.py`

- [ ] Add failing tests for straight chain and branched mesh topology.
- [ ] Convert every structural pipe element to an acoustic FETM element using its actual `Di`, `Do`, length, and material/fluid wave-speed model.
- [ ] Preserve shared nodes so bends/tees naturally conserve volume flow.

### Task 4: Network pressure solver and PipePulse dispatcher

**Files:**
- Create `src/solve_acoustic_network_harmonic.m`
- Modify `src/solve_fluid_harmonic.m`
- Create `example_acoustic_network.m`
- Test `tests_py/test_acoustic_network_solver.py`

- [ ] Add failing test for new `pressure_field_model='acoustic_network'` dispatcher.
- [ ] Solve mixed boundary conditions by complex sparse partition/elimination.
- [ ] Return pressure and element volume-flow diagnostics in the existing `fluidSol` shape.
- [ ] Keep all legacy branches unchanged.

### Task 5: Analytic/passive-network validation

**Files:**
- Create `validation/acoustic_network/report.md`
- Create validation CSVs/plots.

- [ ] Verify matched termination gives `|P2/P1|≈1`, phase `-kL`.
- [ ] Verify Thevenin/Norton equivalence.
- [ ] Verify symmetric branch produces symmetric branch response.
- [ ] Verify chamber compliance response and flow conservation.
- [ ] Verify auto-network reproduces existing `fetm_impedance` for an equivalent straight network.

### Task 6: Current 2.8 regression and structural coupling

**Files:**
- Create `validation/acoustic_network/2p8_comparison.csv`
- Create comparison plot.

- [ ] Reproduce historical `endpoint_constrained` node-49 response exactly in Python mirror.
- [ ] Run `acoustic_network` with anechoic termination and with broadband passive physical termination examples.
- [ ] Map network pressures through current structural pressure load and record 1-8 response.
- [ ] Do not identify structural boundaries unless the acoustic model has enough physical external-network inputs.

### Task 7: Final verification and recommendation

- [ ] Run full Python regression suite fresh.
- [ ] Check no HBM files changed.
- [ ] Scan for forbidden harmonic scaling / 1.62 / propagation-loss tuning.
- [ ] Inspect branch diff against base.
- [ ] Write final report explaining which mode is recommended for measured-endpoint reproduction and which mode is recommended for predictive network simulation.
- [ ] Leave feature branch unmerged for user review.
