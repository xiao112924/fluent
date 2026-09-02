function N = wall_pressure_axial_resultant(p,Di,Do,nu,external_pressure,capped_end,wall_formulation)
%WALL_PRESSURE_AXIAL_RESULTANT 压力经管壁轴向应力转换后的等效轴向合力。

if ~(isfinite(Di) && isfinite(Do) && Di > 0 && Do > Di)
    error('PipePulse:WallPressureGeometry','必须满足 Do > Di > 0。');
end
if ~(isfinite(nu) && isscalar(nu))
    error('PipePulse:WallPressurePoisson','泊松比 nu 必须为有限标量。');
end
if nargin < 5 || isempty(external_pressure)
    external_pressure = 0;
end
if nargin < 6 || isempty(capped_end)
    capped_end = true;
end
if nargin < 7 || isempty(wall_formulation)
    wall_formulation = "thick_wall";
end

wall_formulation = lower(string(wall_formulation));
capped_end = double(logical(capped_end));
Aw = pi/4*(Do^2-Di^2);

switch wall_formulation
    case "thick_wall"
        sigma_axial = (p*Di^2 - external_pressure*Do^2)/(Do^2-Di^2);
        N = Aw*(capped_end - 2*nu)*sigma_axial;

    case "thin_wall"
        stress_axial = (p*Di^2 - external_pressure*Do^2)/(Do^2-Di^2);
        N = Aw*(capped_end*stress_axial - nu*p*(Do/(Do-Di)-1));

    otherwise
        error('PipePulse:WallPressureFormulation', ...
            '不支持的 wall_formulation: %s。仅支持 thick_wall 或 thin_wall。', wall_formulation);
end
end
