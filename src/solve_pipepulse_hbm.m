function result = solve_pipepulse_hbm(linearResult,cfg,QinitOverride)
%SOLVE_PIPEPULSE_HBM 基于当前线性PipePulse结果进行非线性弹支AFT-HBM求解。
%
% 非线性仅作用于入口/出口XYZ三个平移自由度：
%   Fnl = k2*u^2 + k3*u^3
% 线性k1、ct以及转动Kr、Cr仍由现有elastic边界加入动态刚度。
%
% 本函数使用边界柔度降阶：每阶只联立6个非线性边界平移自由度，
% 其余结构自由度通过线性动态柔度恢复。

if nargin < 2 || isempty(cfg)
    cfg = linearResult.cfg;
end
if nargin < 3
    QinitOverride = [];
end

if ~isfield(cfg,'hbm')
    error('PipePulse:HBMConfig','缺少cfg.hbm配置。');
end
if ~isfield(cfg,'boundary') || ~isfield(cfg.boundary,'nonlinear') || ...
        ~isfield(cfg.boundary.nonlinear,'enabled') || ~cfg.boundary.nonlinear.enabled
    error('PipePulse:HBMConfig','必须启用cfg.boundary.nonlinear.enabled。');
end
if ~strcmpi(cfg.boundary.inlet.type,'elastic') || ~strcmpi(cfg.boundary.outlet.type,'elastic')
    error('PipePulse:HBMBoundary','当前HBM第一版要求入口和出口均为elastic边界。');
end

if ~isfield(cfg.boundary.nonlinear,'k2')
    cfg.boundary.nonlinear.k2 = 0;
end
if ~isfield(cfg.boundary.nonlinear,'k3')
    error('PipePulse:HBMConfig','缺少cfg.boundary.nonlinear.k3。');
end
k2 = cfg.boundary.nonlinear.k2;
k3 = cfg.boundary.nonlinear.k3;
if ~isscalar(k2) || ~isfinite(k2)
    error('PipePulse:HBMK2','k2必须为有限标量，可正、可负或为0。');
end
if ~isscalar(k3) || ~isfinite(k3)
    error('PipePulse:HBMK3','k3必须为有限标量，可正、可负或为0。');
end

nHarm = cfg.hbm.n_harmonics;
if nHarm < 1 || floor(nHarm) ~= nHarm || nHarm > size(linearResult.U,2)
    error('PipePulse:HBMHarmonics','n_harmonics必须为1到现有线性谐波数之间的整数。');
end
if cfg.hbm.n_time_samples <= 4*nHarm
    error('PipePulse:HBMAliasing','n_time_samples必须大于4*n_harmonics。');
end

S = linearResult.structure;
ndof = S.ndof;
inletNode = linearResult.inletNode;
outletNode = linearResult.outletNode;
inletTrans = (6*inletNode-5):(6*inletNode-3);
outletTrans = (6*outletNode-5):(6*outletNode-3);
bdofs = [inletTrans,outletTrans];
nBoundary = numel(bdofs);

B = sparse(bdofs,1:nBoundary,1,ndof,nBoundary);
G = cell(nHarm+1,1);
X = cell(nHarm+1,1);
Ulin = complex(zeros(ndof,nHarm));
Qlin = complex(zeros(nBoundary,nHarm+1));

% DC增量柔度：围绕已经建立的静压预应力平衡点求动态平均修正。
D0 = S.Kt;
[D0,fixed0] = apply_boundary_impedance(D0,cfg,inletNode,outletNode,0);
if any(ismember(bdofs,fixed0))
    error('PipePulse:HBMBoundary','非线性边界平移自由度不能同时设为fixed。');
end
allD = (1:ndof).';
free0 = setdiff(allD,fixed0);
X0 = complex(zeros(ndof,nBoundary));
X0(free0,:) = D0(free0,free0)\B(free0,:);
X{1} = X0;
G{1} = X0(bdofs,:);

for n = 1:nHarm
    omega = linearResult.omega(n);
    D = S.Kt - omega^2*S.M + 1i*omega*S.C;
    [D,fixed] = apply_boundary_impedance(D,cfg,inletNode,outletNode,omega);
    if any(ismember(bdofs,fixed))
        error('PipePulse:HBMBoundary','非线性边界平移自由度不能同时设为fixed。');
    end
    free = setdiff(allD,fixed);

    Xn = complex(zeros(ndof,nBoundary));
    Xn(free,:) = D(free,free)\B(free,:);
    X{n+1} = Xn;
    G{n+1} = Xn(bdofs,:);

    un = complex(zeros(ndof,1));
    un(free) = D(free,free)\linearResult.F(free,n);
    Ulin(:,n) = un;
    Qlin(:,n+1) = un(bdofs);
end

if isempty(QinitOverride)
    Qinit = Qlin;
else
    if ~isequal(size(QinitOverride),size(Qlin))
        error('PipePulse:HBMInitialState','QinitOverride尺寸必须与当前HBM边界状态一致。');
    end
    Qinit = QinitOverride;
end
sol = solve_hbm_system(Qinit,G,Qlin,k2,k3,cfg.hbm);

if ~sol.converged
    warning('PipePulse:HBMNotConverged', ...
        'HBM未达到设定容差：relative residual = %.6e。',sol.relative_residual);
end

Fnl = sol.Fnl;
U = Ulin;
for n = 1:nHarm
    U(:,n) = Ulin(:,n) - X{n+1}*Fnl(:,n+1);
end
U0corr = -X{1}*Fnl(:,1);

result = linearResult;
result.cfg = cfg;
result.frequency = linearResult.frequency(1:nHarm);
result.omega = linearResult.omega(1:nHarm);
result.U = U;
result.V = U .* (1i*result.omega.');
result.A = U .* (-(result.omega.').^2);
result.P = linearResult.P(:,1:nHarm);
result.Q = linearResult.Q(:,1:nHarm);
result.F = linearResult.F(:,1:nHarm);

result.hbm.enabled = true;
result.hbm.k2 = k2;
result.hbm.k3 = k3;
result.hbm.boundary_dofs = bdofs;
result.hbm.boundary_displacement_harmonics = sol.Q;
result.hbm.nonlinear_force_harmonics = Fnl;
result.hbm.dc_displacement_correction = U0corr;
result.hbm.converged = sol.converged;
result.hbm.iterations = sol.iterations;
result.hbm.relative_residual = sol.relative_residual;
result.hbm.history = sol.history;
result.hbm.linear_reference_U = Ulin;
end
