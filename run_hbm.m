clear; clc;
addpath(fullfile(pwd,'src'));

% PipePulse：当前修正 Timoshenko 模型 + 非线性弹支 AFT-HBM
% 非线性只作用于入口/出口 XYZ 平移自由度：
%   F_nl = k2*u^2 + k3*u^3
% 转动边界仍使用 example_case.m 中的线性 Kr/Cr。

cfg = example_case();
cfg.solver.type = 'nonlinear_hbm';
cfg.boundary.nonlinear.enabled = true;

fprintf('PipePulse HBM：计算当前线性基准...\n');
linearResult = solve_pipepulse(cfg);

fprintf('\nPipePulse HBM：开始 AFT-HBM 多谐波耦合求解...\n');
hbmResult = solve_pipepulse_hbm(linearResult,cfg);

R = print_hbm_response(linearResult,hbmResult,cfg.query.point,cfg.query.direction);
plot_hbm_response(R);

out = cfg.output.folder;
if ~exist(out,'dir'), mkdir(out); end

change = 100*(R.hbm.A_g-R.linear.A_g)./max(R.linear.A_g,eps);
T = [num2cell((1:numel(R.hbm.frequency)).'), ...
     num2cell(R.hbm.frequency(:)), ...
     num2cell(R.linear.A_g(:)), ...
     num2cell(R.hbm.A_g(:)), ...
     num2cell(change(:))];
writecell([{'阶次','频率_Hz','线性加速度_g','HBM加速度_g','变化_百分比'}; T], ...
    fullfile(out,'hbm_response_comparison.csv'));

save(fullfile(out,'hbm_result.mat'),'hbmResult','linearResult','R','cfg','-v7.3');
fprintf('\nHBM结果已输出至：%s\n',out);
