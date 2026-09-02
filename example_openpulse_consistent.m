function cfg = example_openpulse_consistent()
%EXAMPLE_OPENPULSE_CONSISTENT OpenPulse-consistent physics profile for the 2.8 case.
% Starts from the current example data and only selects the named physics profile.
% solve_pipepulse() applies all coupled switches atomically through apply_physics_profile().

cfg = example_case();
cfg.model.physics_profile = 'openpulse_consistent';

% Keep the original/unamplified measured pressure harmonics and bounded pressure field.
cfg.fluid.pressure_field_model = 'endpoint_constrained';
end
