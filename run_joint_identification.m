clear; clc;
addpath(fullfile(pwd,'src'));

cfg = example_case();
JID = identify_boundary_sensor_joint(cfg);
ID = JID.best;

fprintf('\n========== 边界 + 测点联合识别 ==========' );
fprintf('\n最佳节点 = %d\n',JID.best_sensor_node);
fprintf('相对原节点弧长偏移 = %+8.3f mm\n',1e3*JID.sensor_distance_m);
fprintf('坐标 = [%.9f %.9f %.9f]\n',JID.best_sensor_point);
fprintf('Kt   = %.8e N/m\n',ID.params.Kt);
fprintf('Kr   = %.8e N*m/rad\n',ID.params.Kr);
fprintf('Ct   = %.8e N*s/m\n',ID.params.Ct);
fprintf('Cr   = %.8e N*m*s/rad\n',ID.params.Cr);
fprintf('zeta = %.8e\n',ID.params.zeta);
fprintf('RMSE = %.6f g\n',ID.rmse_g);
fprintf('相对RMSE = %.3f %%\n',100*ID.relative_rmse);

figure('Name','Joint sensor-boundary identification','Color','w');
plot(ID.frequency,ID.target_g,'o-','LineWidth',1.2); hold on;
plot(ID.frequency,ID.calculated_g,'s--','LineWidth',1.2);
xlabel('频率 (Hz)'); ylabel('加速度幅值 (g)');
legend('实验','联合识别','Location','best'); grid on;
title(sprintf('边界+测点联合识别：节点 %d, 偏移 %+0.1f mm', ...
    JID.best_sensor_node,1e3*JID.sensor_distance_m));
