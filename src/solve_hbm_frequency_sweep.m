function SW = solve_hbm_frequency_sweep(baseResult,cfg,k3Values)
%SOLVE_HBM_FREQUENCY_SWEEP 单频压力激励下进行非线性HBM连续扫频。
%
% 每个扫频点只直接施加当前案例的一阶入口/出口压力复幅值，
% HBM保留1~nHarm阶，较高谐波由二次+三次非线性边界自行生成。

if ~isfield(cfg,'hbm_sweep')
    error('PipePulse:HBMSweepConfig','缺少cfg.hbm_sweep配置。');
end

fmin = cfg.hbm_sweep.fmin;
fmax = cfg.hbm_sweep.fmax;
df = cfg.hbm_sweep.df;
if fmin <= 0 || fmax <= fmin || df <= 0
    error('PipePulse:HBMSweepConfig','扫频范围或步长无效。');
end

freq = (fmin:df:fmax).';
nHarm = cfg.hbm.n_harmonics;
Hin1 = baseResult.pressure_harmonics.inlet.P(1);
Hout1 = baseResult.pressure_harmonics.outlet.P(1);

nK = numel(k3Values);
nF = numel(freq);
fundamental = nan(nF,nK);
totalPeak = nan(nF,nK);
converged = false(nF,nK);
iterations = zeros(nF,nK);
residual = nan(nF,nK);
harmonicAmp = nan(nF,nHarm,nK);

for ik = 1:nK
    k3 = k3Values(ik);
    fprintf('\nHBM扫频：k3 = %.6e N/m^3\n',k3);
    Qprev = [];

    for jf = 1:nF
        fdrive = freq(jf);
        fprintf('  %4d/%4d : %.3f Hz\n',jf,nF,fdrive);

        cfgPoint = cfg;
        cfgPoint.boundary.nonlinear.enabled = true;
        if ~isfield(cfgPoint.boundary.nonlinear,'k2')
            cfgPoint.boundary.nonlinear.k2 = 0;
        end
        cfgPoint.boundary.nonlinear.k3 = k3;
        cfgPoint.excitation.base_frequency = fdrive;

        linearPoint = build_hbm_single_tone_case( ...
            baseResult,cfgPoint,fdrive,Hin1,Hout1,nHarm);

        % 第一频点使用k3强度延续；后续频点使用上一点作频率延续初值。
        if isempty(Qprev)
            hbmPoint = solve_pipepulse_hbm(linearPoint,cfgPoint);
        else
            cfgPoint.hbm.continuation_steps = 1;
            hbmPoint = solve_pipepulse_hbm(linearPoint,cfgPoint,Qprev);
            if ~hbmPoint.hbm.converged
                % 若频率延续失败，则退回线性初值并恢复非线性强度延续。
                cfgPoint.hbm.continuation_steps = cfg.hbm.continuation_steps;
                hbmPoint = solve_pipepulse_hbm(linearPoint,cfgPoint);
            end
        end

        Qprev = hbmPoint.hbm.boundary_displacement_harmonics;
        R = query_point_response(hbmPoint,cfg.query.point,cfg.query.direction);

        fundamental(jf,ik) = R.A_g(1);
        totalPeak(jf,ik) = max(abs(R.a_time))/9.80665;
        harmonicAmp(jf,:,ik) = R.A_g(:).';
        converged(jf,ik) = hbmPoint.hbm.converged;
        iterations(jf,ik) = hbmPoint.hbm.iterations;
        residual(jf,ik) = hbmPoint.hbm.relative_residual;
    end
end

SW.frequency = freq;
SW.k3_values = k3Values(:).';
SW.fundamental_g = fundamental;
SW.total_peak_g = totalPeak;
SW.harmonic_g = harmonicAmp;
SW.converged = converged;
SW.iterations = iterations;
SW.relative_residual = residual;
SW.k2 = cfg.boundary.nonlinear.k2;
SW.definition = 'single-tone pressure sweep; external pressure only at fundamental; quadratic+cubic nonlinear HBM generates higher harmonics';
end
