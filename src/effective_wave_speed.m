function c = effective_wave_speed(Di,Do,solid,fluid)
%EFFECTIVE_WAVE_SPEED 液体-弹性管等效声速。
% wave_speed_model:
%   legacy                : 1/c^2 = rho*(1/Kf + Di/(E*t))
%   openpulse_compliance  : c0/sqrt(1 + Di*Kf/(E*t))
% 两者在当前零流量线弹性假设下数学等价，但保留显式分支用于物理配置追踪。

if isfield(fluid,'wave_speed_override') && isfinite(fluid.wave_speed_override)
    c = fluid.wave_speed_override;
    return;
end

if isfield(fluid,'wave_speed_model') && ~isempty(fluid.wave_speed_model)
    model = lower(string(fluid.wave_speed_model));
else
    model = "legacy";
end

t = 0.5*(Do-Di);
switch model
    case "legacy"
        comp = 1/fluid.bulk + Di/(solid.E*t);
        c = 1/sqrt(fluid.rho*comp);

    case "openpulse_compliance"
        c_fluid = sqrt(fluid.bulk/fluid.rho);
        factor = Di*fluid.bulk/(solid.E*t);
        c = c_fluid/sqrt(1 + factor);

    otherwise
        error('PipePulse:WaveSpeedModel', ...
            '未知 wave_speed_model: %s。',model);
end
end
