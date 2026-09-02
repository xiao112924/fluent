clear; clc;
addpath(fullfile(pwd,'src'));

% PipePulse：当前修正 Timoshenko 模型 + 非线性弹支 HBM 连续扫频
% 外部压力只直接施加在基频，高次谐波由 k2*u^2+k3*u^3 产生。

cfg = example_case();
cfg.solver.type = 'nonlinear_hbm';
cfg.boundary.nonlinear.enabled = true;

fprintf('PipePulse HBM扫频：计算线性基准与预应力状态...\n');
baseResult = solve_pipepulse(cfg);

k3Values = cfg.hbm_sweep.k3_values;
fprintf('\n开始非线性 HBM 连续扫频...\n');
SW = solve_hbm_frequency_sweep(baseResult,cfg,k3Values);
plot_hbm_sweep_comparison(SW);

out = cfg.output.folder;
if ~exist(out,'dir'), mkdir(out); end
header = {'频率_Hz'};
for i=1:numel(k3Values)
    header{end+1} = sprintf('基频_g_k3_%g',k3Values(i)); %#ok<SAGROW>
    header{end+1} = sprintf('总峰值_g_k3_%g',k3Values(i)); %#ok<SAGROW>
end
rows = cell(numel(SW.frequency),numel(header));
for j=1:numel(SW.frequency)
    rows{j,1}=SW.frequency(j);
    c=2;
    for i=1:numel(k3Values)
        rows{j,c}=SW.fundamental_g(j,i); c=c+1;
        rows{j,c}=SW.total_peak_g(j,i); c=c+1;
    end
end
writecell([header;rows],fullfile(out,'hbm_frequency_sweep_comparison.csv'));
save(fullfile(out,'hbm_frequency_sweep.mat'),'SW','cfg','k3Values','-v7.3');
fprintf('\nHBM扫频完成，结果已输出至：%s\n',out);
