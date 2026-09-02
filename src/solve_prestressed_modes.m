function modal = solve_prestressed_modes(result,nModes)
%SOLVE_PRESTRESSED_MODES
% 在当前静压预应力切线刚度 + 当前端部弹性边界下求固有频率。
%
% 广义特征值问题：
%   (Kt + Kboundary) * phi = lambda * M * phi
%   f = sqrt(lambda)/(2*pi)
%
% 注意：阻尼不参与实特征值模态求解。

if nargin < 2 || isempty(nModes)
    nModes = 10;
end

S = result.structure;
cfg = result.cfg;

Kmodal = S.Kt;
[Kmodal,fixed] = apply_boundary_impedance( ...
    Kmodal,cfg,result.inletNode,result.outletNode,0);

allD = (1:S.ndof).';
free = setdiff(allD,fixed);

Kff = Kmodal(free,free);
Mff = S.M(free,free);

nReq = min(nModes+6, max(1,numel(free)-2));

try
    [V,D] = eigs(Kff,Mff,nReq,'smallestabs');
catch
    [V,D] = eigs(Kff,Mff,nReq,'sm');
end

lam = real(diag(D));
valid = isfinite(lam) & lam > 1e-6;
lam = lam(valid);
V = V(:,valid);

f = sqrt(lam)/(2*pi);
[f,idx] = sort(f);
V = V(:,idx);

nKeep = min(nModes,numel(f));
f = f(1:nKeep);
V = V(:,1:nKeep);

Phi = zeros(S.ndof,nKeep);
Phi(free,:) = V;

% 质量归一化
for i=1:nKeep
    mnorm = sqrt(real(Phi(:,i)'*S.M*Phi(:,i)));
    if mnorm > 0
        Phi(:,i) = Phi(:,i)/mnorm;
    end
end

modal.frequency = f(:);
modal.omega = 2*pi*f(:);
modal.modes = Phi;
modal.fixed_dofs = fixed;
modal.free_dofs = free;
end
