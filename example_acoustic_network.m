function cfg = example_acoustic_network()
%EXAMPLE_ACOUSTIC_NETWORK 通用液压声学网络示例。
% 结构几何仍由 example_case() 提供；声学层自动把每个结构管单元转换为
% OpenPulse-style FETM 管单元，并允许继续添加阀、节流、容腔、蓄能器等。

cfg = example_case();
cfg.fluid.pressure_field_model = 'acoustic_network';
cfg.fluid.network.auto_from_structural_mesh = true;
cfg.fluid.network.proportional_loss = 0;

% 示例A：入口为已知复压力源，出口为无反射端。
cfg.fluid.network.sources = struct( ...
    'type','pressure', ...
    'node','inlet');  % 未显式给 value 时自动使用当前谐波 Pin
cfg.fluid.network.terminations = struct( ...
    'node','outlet', ...
    'type','anechoic');

% 其他元件示例（按需启用）：
% cfg.fluid.network.elements(1) = struct( ...
%     'type','resistance','nodes',[20 21],'R',2.0e8);
% cfg.fluid.network.elements(2) = struct( ...
%     'type','inertance','nodes',[30 31],'Lh',5.0e5);
% cfg.fluid.network.elements(3) = struct( ...
%     'type','chamber','nodes',40,'volume',2.0e-5);
%
% 泵的有限源阻抗推荐用 Thevenin 形式：
% cfg.fluid.network.sources = struct( ...
%     'type','thevenin_pressure','node','inlet', ...
%     'impedance',8.0e9);  % Pa*s/m^3
end
