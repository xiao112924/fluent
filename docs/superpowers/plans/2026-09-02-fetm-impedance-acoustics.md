# FETM Impedance Acoustics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use task-by-task TDD and independent review.

**Goal:** Implement OpenPulse-style FETM + impedance acoustic pressure propagation and validate it on the 2.8 pressure-transfer data.

**Spec:** `docs/superpowers/specs/2026-09-02-fetm-impedance-acoustics-design.md`

1. Add/test `fetm_acoustic_admittance.m`.
2. Add/test `acoustic_termination_impedance.m` with passive checks.
3. Add/test `solve_fetm_impedance_pressure.m` and dispatch from `solve_fluid_harmonic.m` using one hard pressure boundary only.
4. Add `example_fetm_impedance.m`; keep base default unchanged.
5. Diagnose measured `Pout/Pin`: exact inferred impedance, passive classification, broadband constant/RLC fit, optional one global proportional loss.
6. Re-identify structural boundary only if the passive acoustic model passes the pressure-transfer plausibility gate.
7. Run full regression, check HBM untouched and forbidden scaling absent, write report, keep on feature branch.
