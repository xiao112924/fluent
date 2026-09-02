function ID = identify_experiment_response(cfg)
%IDENTIFY_EXPERIMENT_RESPONSE 用实验1~8阶加速度重新识别线性支撑与结构阻尼。
% 参数：[Kt, Kr, Ct, Cr, zeta]，两端对称、XYZ/三转角各向同性。
% 目标函数采用对数幅值残差，避免某一阶大幅值独占目标函数。

target = cfg.identification.experimental_acceleration_g(:);
if numel(target) ~= cfg.excitation.max_harmonic
    error('实验目标阶数必须等于 cfg.excitation.max_harmonic。');
end

p0 = cfg.identification.initial(:).';
bounds = cfg.identification.bounds;
if ~isequal(size(bounds),[2 5])
    error('cfg.identification.bounds 必须为 2x5。');
end

lb = bounds(1,:); ub = bounds(2,:);
x0 = log10(p0);
xlb = log10(lb); xub = log10(ub);

% 优化期间关闭绘图和大文件输出。
cfgOpt = cfg;
cfgOpt.output.plot_mesh = false;
cfgOpt.output.save_mat = false;
cfgOpt.modal.n_modes = 0;

history = [];
obj = @(x) objective_bounded(x,cfgOpt,target,xlb,xub);
opts = optimset('Display',cfg.identification.display, ...
    'MaxIter',cfg.identification.max_iterations, ...
    'MaxFunEvals',max(500,20*cfg.identification.max_iterations), ...
    'TolX',1e-4,'TolFun',1e-5,'OutputFcn',@outfun);

[xbest,fbest,exitflag,output] = fminsearch(obj,x0,opts);
xbest = min(max(xbest,xlb),xub);
pbest = 10.^xbest;

cfgBest = set_params(cfg,pbest);
cfgBest.output.plot_mesh = false;
result = solve_pipepulse(cfgBest);
R = query_point_response(result,cfgBest.query.point,cfgBest.query.direction);
calc = R.A_g(:);

ID.params.Kt = pbest(1);
ID.params.Kr = pbest(2);
ID.params.Ct = pbest(3);
ID.params.Cr = pbest(4);
ID.params.zeta = pbest(5);
ID.target_g = target;
ID.calculated_g = calc;
ID.frequency = R.frequency(:);
ID.relative_error_percent = 100*(calc-target)./target;
ID.rmse_g = sqrt(mean((calc-target).^2));
ID.relative_rmse = sqrt(mean(((calc-target)./target).^2));
ID.objective = fbest;
ID.exitflag = exitflag;
ID.output = output;
ID.history = history;
ID.cfg_best = cfgBest;

if ~exist(cfg.output.folder,'dir'), mkdir(cfg.output.folder); end
T = table((1:numel(target)).',ID.frequency,target,calc,ID.relative_error_percent, ...
    'VariableNames',{'Order','Frequency_Hz','Experiment_g','Calculated_g','RelativeError_percent'});
writetable(T,fullfile(cfg.output.folder,'identified_experiment_response.csv'));
P = table(pbest(1),pbest(2),pbest(3),pbest(4),pbest(5), ...
    'VariableNames',{'Kt_N_per_m','Kr_Nm_per_rad','Ct_Ns_per_m','Cr_Nms_per_rad','zeta'});
writetable(P,fullfile(cfg.output.folder,'identified_parameters.csv'));
save(fullfile(cfg.output.folder,'experiment_identification.mat'),'ID');

    function stop = outfun(x,optimValues,state)
        stop = false;
        if strcmp(state,'iter')
            history(end+1,:) = [optimValues.iteration optimValues.fval x(:).']; %#ok<AGROW>
        end
    end
end

function J = objective_bounded(x,cfg,target,xlb,xub)
xc = min(max(x,xlb),xub);
penalty = 1e3*sum((x-xc).^2);
p = 10.^xc;
try
    cfg2 = set_params(cfg,p);
    result = solve_pipepulse(cfg2);
    R = query_point_response(result,cfg2.query.point,cfg2.query.direction);
    a = max(R.A_g(:),1e-12);
    r = log(a./target);
    J = mean(r.^2) + penalty;
catch
    J = 1e6 + penalty;
end
end

function cfg = set_params(cfg,p)
Kt=p(1); Kr=p(2); Ct=p(3); Cr=p(4); zeta=p(5);
cfg.boundary.inlet.type='elastic';
cfg.boundary.outlet.type='elastic';
cfg.boundary.inlet.K=[Kt Kt Kt Kr Kr Kr];
cfg.boundary.inlet.C=[Ct Ct Ct Cr Cr Cr];
cfg.boundary.outlet.K=cfg.boundary.inlet.K;
cfg.boundary.outlet.C=cfg.boundary.inlet.C;
cfg.damping.zeta=zeta;
end
