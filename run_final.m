clear; clc;
addpath(fullfile(pwd,'src'));

% ============================================================
% PipePulse Timoshenko Clean
% 最终设置：
% 1) 两端统一弹簧-阻尼边界
% 2) 直接使用 example_case.m 中的最终压力表达式
% 3) 平均静压参与修正后的预应力计算
% 4) 查询点与传感器方向沿用 example_case.m
% ============================================================

cfg = example_case();

% 边界参数直接由 example_case.m 控制，不再在此处二次覆盖。

% ----- 求解 -----
result = solve_pipepulse(cfg);

% ----- 查询关注点 -----
R = query_point_response(result, cfg.query.point, cfg.query.direction);

% ----- 输出 -----
print_query_response(R);
plot_query_response(R);

fprintf('\n====================================================\n');
fprintf('最终模型设置\n');
fprintf('入口/出口采用最终压力表达式直接计算。\n');
fprintf('平均静压用于修正后的预应力几何刚度计算。\n');
fprintf('入口/出口边界：统一弹簧-阻尼弹性支承。\n');
fprintf('静压预应力是否启用 = %d\n', cfg.prestress.enabled);
if ~isempty(result.static_effective_axial_force_element)
    fprintf('管壁轴向力范围 = %.3f ~ %.3f N\n', ...
        min(result.static_wall_axial_force_element), ...
        max(result.static_wall_axial_force_element));
    fprintf('有效轴向力范围 = %.3f ~ %.3f N\n', ...
        min(result.static_effective_axial_force_element), ...
        max(result.static_effective_axial_force_element));
    fprintf('最大静态位移 = %.6f mm\n', ...
        1e3*max(abs(result.static_displacement)));
end
fprintf('====================================================\n');

% 保存关注点结果
T = [num2cell((1:numel(R.frequency)).'), ...
     num2cell(R.frequency(:)), ...
     num2cell(R.A_g(:)), ...
     num2cell(R.U_amp(:)), ...
     num2cell(R.P_amp(:))];

if ~exist(cfg.output.folder,'dir')
    mkdir(cfg.output.folder);
end
writecell([{'阶次','频率_Hz','加速度_g','位移_m','压力_Pa'}; T], ...
    fullfile(cfg.output.folder,'final_query_response.csv'));
save(fullfile(cfg.output.folder,'final_query_response.mat'),'R','result','cfg');


% ============================================================
% 预应力模态 + 连续结构FRF
% ============================================================
analysis_modal_frf = analyze_modal_frf(result);

fprintf('\n模态/FRF结果已输出至：%s\n',cfg.output.folder);
fprintf('  prestressed_modal_frequencies.csv\n');
fprintf('  structural_frf.csv\n');
fprintf('  structural_frf_at_harmonics.csv\n');
fprintf('  modal_frf_analysis.mat\n');
