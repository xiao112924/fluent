function [D, fixedDofs] = apply_boundary_impedance(D,cfg,inletNode,outletNode,omega)
%APPLY_BOUNDARY_IMPEDANCE 在动态刚度矩阵中加入弹性边界，并返回固支DOF。

fixedDofs = [];
[D,f1] = one_end(D,cfg.boundary.inlet,inletNode,omega);
[D,f2] = one_end(D,cfg.boundary.outlet,outletNode,omega);
fixedDofs = unique([f1(:);f2(:)]);
end

function [D,fixed] = one_end(D,b,n,omega)
d = (6*n-5):(6*n);
fixed = [];

switch lower(b.type)
    case 'fixed'
        fixed = d(:);
    case 'free'
        return;
    case 'elastic'
        K = b.K(:);
        C = b.C(:);
        if numel(K)~=6 || numel(C)~=6
            error('PipePulse:Boundary','Elastic K and C must contain 6 values.');
        end
        D(d,d) = D(d,d) + diag(K + 1i*omega*C);
    otherwise
        error('PipePulse:Boundary','Unknown boundary type: %s',b.type);
end
end
