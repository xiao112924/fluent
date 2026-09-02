function Neff = effective_pressure_axial_force(Nwall,p,Di,external_pressure,closed_end_factor)
%EFFECTIVE_PRESSURE_AXIAL_FORCE
% 计算用于横向振动几何刚度的有效轴力。
%
% 对闭口内压管，管壁轴向膜力本身约为 p*A_i，
% 同时内部压力的随动推力在横向扰动方程中产生相反贡献。
% 因此一阶有效轴力写成：
%
%   Neff = Nwall - factor*(p-p_ext)*Ai
%
% 这样对于自由、直、闭口的均匀受压管，
% 若 Nwall = p*Ai，则两项自动抵消，不会重复计算压力刚化。
%
% 约定：
%   Neff > 0 -> 有效拉力，几何刚化
%   Neff < 0 -> 有效压力，几何软化

if nargin < 4 || isempty(external_pressure)
    external_pressure = 0;
end
if nargin < 5 || isempty(closed_end_factor)
    closed_end_factor = 1;
end

Ai = pi*Di^2/4;
pressure_thrust = closed_end_factor*(p-external_pressure)*Ai;
Neff = Nwall - pressure_thrust;
end
