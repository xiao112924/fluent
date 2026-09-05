# Hydraulic Acoustic Network Design

Date: 2026-09-05
Branch: `feature/wall-stress-pressure-coupling`

## Goal

Turn PipePulse from a single-path pressure-field model into a reusable hydraulic-acoustic network solver that can predict the complex pressure field of arbitrary connected pipe networks from physical source/termination/component parameters, then feed that pressure field into the existing structural/HBM solver without per-harmonic or per-geometry tuning.

## Design principles

1. Keep `endpoint_constrained` as a measured-endpoint engineering reference.
2. Keep `fetm_impedance` as a simple one-source/one-termination compatibility mode.
3. Add `acoustic_network` as the general predictive mode.
4. Use OpenPulse-style FETM pipe admittance for each pipe segment.
5. Assemble all acoustic components into one nodal complex-admittance system.
6. Support passive physical components and explicit active sources; never emulate an active source by allowing a passive termination to acquire negative resistance.
7. No harmonic-by-harmonic scale factors, no extra 1.62 multiplier, no fitted propagation-loss table.
8. Structural boundary parameters remain separate from acoustic-network parameters.
9. Existing Timoshenko structure and HBM interfaces remain unchanged.

## Acoustic state

Each acoustic node carries complex pressure `p`. External volume flow injection is positive into the network.

For each frequency:

`Y(omega) * p = q_source(omega)`

with pressure-source nodes handled as prescribed pressure DOFs by partition/elimination.

## Supported elements

### Pipe FETM

For pipe internal area `A`, corrected wave speed `c`, specific acoustic impedance `rho*c`, volume-flow characteristic impedance `Zv=rho*c/A`, and complex wave number `k`:

`Ye = i/(Zv*sin(kL))*[-cos(kL), 1; 1, -cos(kL)]`.

This is the same 1D FETM admittance form used by OpenPulse.

### Series impedance

A two-node element with volume-flow impedance `Zs(omega)` uses

`Y = (1/Zs)*[1,-1;-1,1]`.

Supported parameterizations:
- resistance: `Z=R`
- inertance: `Z=i*omega*Lh`
- series R-L: `Z=R+i*omega*Lh`
- user complex/table impedance

### Shunt compliance / chamber

A node connected to reference pressure through acoustic compliance `Cq` adds

`Yc=i*omega*Cq`.

For a rigid liquid chamber of volume `V`, `Cq=V/Kf`. A gas accumulator can be supplied through an equivalent linearized compliance.

### Termination impedance

A node termination with volume-flow impedance `Zt` adds `1/Zt` to the nodal diagonal. Existing anechoic/normalized RLC/specific impedance forms remain usable.

## Sources

### Prescribed pressure source

One or more nodes can have prescribed complex pressure spectra. This is a true Dirichlet source and is eliminated from the free system.

### Prescribed volume-flow source

A complex volume-flow spectrum is added directly to the RHS at a node.

### Thevenin pressure source

A pump/source pressure `Ps(omega)` behind source impedance `Zs(omega)` is represented by a Norton equivalent:

- add `1/Zs` to source-node diagonal;
- add `Ps/Zs` to RHS.

This allows physically meaningful finite source impedance instead of a hard pressure boundary.

## Network representation

`cfg.fluid.network.nodes` contains node IDs / optional coordinates.

`cfg.fluid.network.elements` is a struct array. Each element contains `type` and node references. Pipe elements can reuse the structural mesh automatically; non-pipe acoustic components may connect structural acoustic nodes or additional network-only nodes.

For the common case, `cfg.fluid.network.auto_from_structural_mesh=true` builds a pipe FETM element for every structural pipe element, so arbitrary 3D pipe geometry and branches work through topology alone.

## Mapping to structure

The acoustic solution returns pressure at every structural mesh node. Existing `pressure_to_structure_load` consumes those complex nodal pressures unchanged. Network-only nodes do not create structural loads.

## Configuration

```matlab
cfg.fluid.pressure_field_model = 'acoustic_network';
cfg.fluid.network.auto_from_structural_mesh = true;
cfg.fluid.network.proportional_loss = 0;

cfg.fluid.network.sources(1).type = 'pressure';
cfg.fluid.network.sources(1).node = 'inlet';
cfg.fluid.network.sources(1).value = Pin;

cfg.fluid.network.terminations(1).node = 'outlet';
cfg.fluid.network.terminations(1).type = 'anechoic';
```

For prediction where pump source impedance is known, prefer `type='thevenin_pressure'` with physical source impedance.

## Current 2.8 case policy

The measured inlet/outlet spectra cannot be reproduced by one uniform pipe plus one passive termination over all eight harmonics. Therefore the current 2.8 validation case must not fit a passive termination independently per harmonic. Until the external hydraulic loop is specified, `endpoint_constrained` remains the recommended engineering mode for that experiment.

The new network mode is validated on analytic/passive-network tests and on consistency/regression tests, not by forcing the incomplete 2.8 external network to match experiment.

## Validation

1. Pipe FETM matrix matches analytic formula.
2. A matched termination gives traveling-wave transfer magnitude near one and phase `-kL`.
3. Series resistance dissipates and never creates negative resistance.
4. Junction assembly conserves volume flow.
5. Symmetric tee gives symmetric branch pressures/flows.
6. Chamber compliance produces the expected low-pass/reactive behavior.
7. Thevenin and Norton source representations are equivalent.
8. Auto-generated straight network matches the existing `fetm_impedance` solver for the same source/termination.
9. `endpoint_constrained` regression remains exact.
10. No HBM files change.

## Completion criterion

PipePulse is considered to have reached the intended general predictive architecture when arbitrary connected structural pipe meshes can be automatically converted to an acoustic FETM network, common hydraulic acoustic components and physical sources can be added, complex nodal pressures can be solved and mapped into the structural/HBM solver, and all legacy/reference modes remain available without hidden calibration factors.
