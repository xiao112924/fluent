function A = analyze_modal_frf(result)
%ANALYZE_MODAL_FRF 自动进行预应力模态、连续结构FRF和固有频率处FRF计算。

cfg = result.cfg;

if ~isfield(cfg,'modal') || ~isfield(cfg.modal,'n_modes')
    nModes = 10;
else
    nModes = cfg.modal.n_modes;
end

if ~isfield(cfg,'frf')
    fmin = 50;
    fmax = max(1600,1.12*max(result.frequency));
    df = 2;
else
    fmin = cfg.frf.fmin;
    fmax = cfg.frf.fmax;
    df = cfg.frf.df;
end

fprintf('\nPipePulse：正在求解预应力状态下的固有频率...\n');
modal = solve_prestressed_modes(result,nModes);

fprintf('预应力状态下的固有频率：\n');
for i=1:numel(modal.frequency)
    fprintf('  第 %2d 阶：%12.6f Hz\n',i,modal.frequency(i));
end

fprintf('\nPipePulse：正在进行结构FRF连续扫频 %.3f ~ %.3f Hz，步长=%.3f Hz...\n', ...
    fmin,fmax,df);

fgrid = (fmin:df:fmax).';
FRF = compute_structural_frf( ...
    result,fgrid,cfg.query.point,cfg.query.direction);

% 在固有频率处精确求FRF
FRFmode = compute_structural_frf( ...
    result,modal.frequency,cfg.query.point,cfg.query.direction);

% 在实际1~8阶倍频位置求FRF
FRFharm = compute_structural_frf( ...
    result,result.frequency,cfg.query.point,cfg.query.direction);

out = cfg.output.folder;
if ~exist(out,'dir')
    mkdir(out);
end

Tmode = [num2cell((1:numel(modal.frequency)).'), ...
         num2cell(modal.frequency(:)), ...
         num2cell(FRFmode.acceleration_g_per_N(:))];
writecell([{'阶次','固有频率_Hz','加速度FRF_g每N'}; Tmode], ...
    fullfile(out,'prestressed_modal_frequencies.csv'));

Tfrf = [num2cell(FRF.frequency(:)), ...
        num2cell(FRF.acceleration_g_per_N(:)), ...
        num2cell(FRF.phase_deg(:))];
writecell([{'频率_Hz','加速度FRF_g每N','相位_度'}; Tfrf], ...
    fullfile(out,'structural_frf.csv'));

Th = [num2cell((1:numel(result.frequency)).'), ...
      num2cell(result.frequency(:)), ...
      num2cell(FRFharm.acceleration_g_per_N(:))];
writecell([{'倍频阶次','频率_Hz','结构FRF_g每N'}; Th], ...
    fullfile(out,'structural_frf_at_harmonics.csv'));

% 图1：连续FRF
figure('Color','w','Name','预应力结构频响函数');
semilogy(FRF.frequency,FRF.acceleration_g_per_N,'LineWidth',1.4);
hold on;
plot(result.frequency,FRFharm.acceleration_g_per_N,'o','MarkerSize',6,'LineWidth',1.2);
for i=1:numel(modal.frequency)
    xline(modal.frequency(i),':');
end
grid on;
xlabel('频率 (Hz)');
ylabel('加速度FRF (g/N)');
title('预应力结构频响函数 and harmonic locations');
legend('结构FRF','1~8阶倍频','固有频率','Location','best');

% 图2：实际响应 + 固有频率
R = query_point_response(result,cfg.query.point,cfg.query.direction);
figure('Color','w','Name','倍频响应与固有频率');
plot(R.frequency,R.A_g,'s--','LineWidth',1.4,'MarkerSize',6);
hold on;
for i=1:numel(modal.frequency)
    xline(modal.frequency(i),':');
end
grid on;
xlabel('频率 (Hz)');
ylabel('加速度幅值 (g)');
title('考虑预应力固有频率的倍频响应');

A.modal = modal;
A.frf = FRF;
A.frf_modes = FRFmode;
A.frf_harmonics = FRFharm;

save(fullfile(out,'modal_frf_analysis.mat'),'A','-v7.3');
end
