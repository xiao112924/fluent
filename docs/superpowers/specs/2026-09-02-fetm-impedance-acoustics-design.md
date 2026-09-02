# FETM impedance acoustics design

Add `cfg.fluid.pressure_field_model='fetm_impedance'` using the OpenPulse 1D FETM admittance formulation. Exactly one endpoint pressure is prescribed; the opposite endpoint is represented by a passive acoustic impedance. Preserve `endpoint_constrained`, `acoustic_bvp`, HBM, and all legacy behavior.

For each element:

\[Y_e=\frac{i}{Z_v\sin(kL)}[-\cos(kL),1;1,-\cos(kL)],\quad Z_v=\rho c/A.\]

Termination models are `anechoic`, `normalized_constant`, `normalized_rlc`, and direct `specific_volume_impedance`. Passive normalized models require non-negative resistance; `normalized_rlc` also requires non-negative inertance/compliance coefficients. Optional global OpenPulse-style proportional acoustic loss uses `k*=k(1-i eta_a)` and `Z*=Z(1-i eta_a)`.

The current 2.8 case may use measured inlet pressure as the single source. Measured outlet pressure is validation data only, never a second hard boundary. Per-harmonic inferred impedance is diagnostic only and is not allowed as a predictive default.

A structural boundary re-identification is allowed only if a single broadband passive acoustic termination can plausibly reproduce the measured inlet/outlet transfer. Otherwise report acoustic-model insufficiency and retain the previous preferred structural boundary.
