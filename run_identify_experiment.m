clear; clc;
addpath(fullfile(pwd,'src'));

cfg = example_case();
ID = identify_experiment_response(cfg);

fprintf('\n========== Timoshenko 实验响应识别结果 ==========\n');
fprintf('Kt   = %.8e N/m\n',ID.params.Kt);
fprintf('Kr   = %.8e N*m/rad\n',ID.params.Kr);
fprintf('Ct   = %.8e N*s/m\n',ID.params.Ct);
fprintf('Cr   = %.8e N*m*s/rad\n',ID.params.Cr);
fprintf('zeta = %.8e\n',ID.params.zeta);
fprintf('RMSE = %.6f g\n',ID.rmse_g);
fprintf('相对RMSE = %.3f %%\n',100*ID.relative_rmse);

figure('Name','Experiment identification','Color','w');
plot(ID.frequency,ID.target_g,'o-','LineWidth',1.2); hold on;
plot(ID.frequency,ID.calculated_g,'s--','LineWidth',1.2);
xlabel('频率 (Hz)'); ylabel('加速度幅值 (g)');
legend('实验','Timoshenko识别后','Location','best'); grid on;
title('实验与重新识别结果对比');
