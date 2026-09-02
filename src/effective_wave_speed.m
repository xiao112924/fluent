function c = effective_wave_speed(Di,Do,solid,fluid)
%EFFECTIVE_WAVE_SPEED 液体-薄壁弹性管等效声速近似。
% 1/c^2 = rho*(1/Kf + Di/(E*t))
% 对厚壁小管属于工程近似；可通过 wave_speed_override 覆盖。

if isfield(fluid,'wave_speed_override') && isfinite(fluid.wave_speed_override)
    c = fluid.wave_speed_override;
    return;
end

t = 0.5*(Do-Di);
comp = 1/fluid.bulk + Di/(solid.E*t);
c = 1/sqrt(fluid.rho*comp);
end
