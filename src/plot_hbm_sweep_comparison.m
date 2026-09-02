function plot_hbm_sweep_comparison(SW)
%PLOT_HBM_SWEEP_COMPARISON 绘制不同k3下的非线性扫频结果。

labels = cell(1,numel(SW.k3_values));
for i=1:numel(SW.k3_values)
    labels{i} = sprintf('k_3 = %.2e N/m^3',SW.k3_values(i));
end

figure('Color','w','Name','HBM扫频：基频响应');
hold on;
for i=1:numel(SW.k3_values)
    plot(SW.frequency,SW.fundamental_g(:,i),'LineWidth',1.4);
end
grid on;
xlabel('激励频率 (Hz)');
ylabel('基频加速度幅值 (g)');
title('非线性弹支 HBM 基频扫频响应');
legend(labels,'Location','best');

figure('Color','w','Name','HBM扫频：总时域峰值');
hold on;
for i=1:numel(SW.k3_values)
    plot(SW.frequency,SW.total_peak_g(:,i),'LineWidth',1.4);
end
grid on;
xlabel('激励频率 (Hz)');
ylabel('重构时域加速度峰值 (g)');
title('非线性弹支 HBM 总响应扫频');
legend(labels,'Location','best');
end
