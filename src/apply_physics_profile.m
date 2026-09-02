function cfg = apply_physics_profile(cfg)
%APPLY_PHYSICS_PROFILE Apply a named set of mutually consistent physics switches.
% Missing/empty profile leaves the existing explicit configuration untouched.

if ~isfield(cfg,'model') || ~isfield(cfg.model,'physics_profile') || ...
        isempty(cfg.model.physics_profile)
    return;
end

profile = lower(string(cfg.model.physics_profile));
switch profile
    case "openpulse_consistent"
        cfg.structure.fluid_mass_model = 'openpulse_translational';
        cfg.coupling.pressure_load_model = 'wall_stress_coupling';
        cfg.coupling.wall_formulation = 'thin_wall';
        cfg.coupling.capped_end = true;
        cfg.coupling.external_pressure = 0;
        cfg.fluid.wave_speed_model = 'openpulse_compliance';
        cfg.prestress.model = 'openpulse';
        cfg.fluid.pressure_field_model = 'endpoint_constrained';

    case {"legacy","custom"}
        % Explicitly configured fields are retained.

    otherwise
        error('PipePulse:PhysicsProfile','未知 physics_profile: %s。',profile);
end
end
