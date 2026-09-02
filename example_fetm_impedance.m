function cfg = example_fetm_impedance()
%EXAMPLE_FETM_IMPEDANCE OpenPulse-style single-source FETM acoustic example.
% The base example remains endpoint_constrained; this file opts in explicitly.

cfg = example_case();
cfg.model.physics_profile = 'custom';
cfg.fluid.pressure_field_model = 'fetm_impedance';
cfg.fluid.wave_speed_model = 'openpulse_compliance';

% Only the inlet measured complex pressure is prescribed in this mode.
cfg.fluid.fetm.source_end = 'inlet';
cfg.fluid.fetm.source_type = 'prescribed_pressure';
cfg.fluid.fetm.proportional_loss = 0.0;

% Predictive default: passive anechoic termination.
cfg.fluid.fetm.termination.type = 'anechoic';

% To use one broadband passive RLC termination, replace the line above with:
% cfg.fluid.fetm.termination.type = 'normalized_rlc';
% cfg.fluid.fetm.termination.r = 1.0;
% cfg.fluid.fetm.termination.m = 0.0;
% cfg.fluid.fetm.termination.q = 0.0;
end
