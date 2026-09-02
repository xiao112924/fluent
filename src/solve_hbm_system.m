function sol = solve_hbm_system(Qinit,G,Qlin,k2,k3,opt)
%SOLVE_HBM_SYSTEM 使用非线性强度延续+阻尼Newton求边界降阶HBM方程。
% 非线性边界：Fnl = k2*u^2 + k3*u^3。

if ~isfield(opt,'n_time_samples'), opt.n_time_samples = 128; end
if ~isfield(opt,'tol'), opt.tol = 1e-7; end
if ~isfield(opt,'max_iter'), opt.max_iter = 20; end
if ~isfield(opt,'continuation_steps'), opt.continuation_steps = 5; end
if ~isfield(opt,'fd_rel_step'), opt.fd_rel_step = 1e-5; end
if ~isfield(opt,'fd_abs_step'), opt.fd_abs_step = 1e-12; end
if ~isfield(opt,'min_line_search'), opt.min_line_search = 1/128; end

nBoundary = size(Qinit,1);
nHarm = size(Qinit,2)-1;
qScale = max(norm(hbm_pack_boundary_state(Qlin)),1e-12);

if all(k2(:)==0) && all(k3(:)==0)
    Q = Qlin;
    [R,Fnl] = hbm_residual(Q,G,Qlin,0,0,opt.n_time_samples);
    sol.Q = Q;
    sol.Fnl = Fnl;
    sol.converged = true;
    sol.iterations = 0;
    sol.relative_residual = norm(hbm_pack_boundary_state(R))/qScale;
    sol.history = [0,0,sol.relative_residual];
    return;
end

nStep = max(1,round(opt.continuation_steps));
Q = Qinit;
history = zeros(0,3);
totalIter = 0;
converged = true;

for is = 1:nStep
    scale = is/nStep;
    k2step = k2*scale;
    k3step = k3*scale;
    z = hbm_pack_boundary_state(Q);
    stepConverged = false;

    for iter = 1:opt.max_iter
        Qnow = hbm_unpack_boundary_state(z,nBoundary,nHarm);
        [R,~] = hbm_residual(Qnow,G,Qlin,k2step,k3step,opt.n_time_samples);
        r = hbm_pack_boundary_state(R);
        rel = norm(r)/qScale;
        totalIter = totalIter + 1;
        history(end+1,:) = [is,iter,rel]; %#ok<AGROW>

        if rel < opt.tol
            stepConverged = true;
            Q = Qnow;
            break;
        end

        nz = numel(z);
        J = zeros(nz,nz);
        zScale = max(max(abs(z)),qScale/sqrt(max(1,numel(z))));
        for j = 1:nz
            h = opt.fd_abs_step + opt.fd_rel_step*max(abs(z(j)),zScale);
            zp = z;
            zp(j) = zp(j) + h;
            Qp = hbm_unpack_boundary_state(zp,nBoundary,nHarm);
            Rp = hbm_residual(Qp,G,Qlin,k2step,k3step,opt.n_time_samples);
            rp = hbm_pack_boundary_state(Rp);
            J(:,j) = (rp-r)/h;
        end

        dz = J\(-r);
        if any(~isfinite(dz))
            stepConverged = false;
            break;
        end

        lambda = 1;
        accepted = false;
        baseNorm = norm(r);
        while lambda >= opt.min_line_search
            ztry = z + lambda*dz;
            Qtry = hbm_unpack_boundary_state(ztry,nBoundary,nHarm);
            Rtry = hbm_residual(Qtry,G,Qlin,k2step,k3step,opt.n_time_samples);
            rtry = hbm_pack_boundary_state(Rtry);
            if norm(rtry) < baseNorm
                z = ztry;
                accepted = true;
                break;
            end
            lambda = 0.5*lambda;
        end

        if ~accepted
            stepConverged = false;
            break;
        end
    end

    if ~stepConverged
        converged = false;
        Q = hbm_unpack_boundary_state(z,nBoundary,nHarm);
        break;
    end
end

[R,Fnl] = hbm_residual(Q,G,Qlin,k2,k3,opt.n_time_samples);
rel = norm(hbm_pack_boundary_state(R))/qScale;
sol.Q = Q;
sol.Fnl = Fnl;
sol.converged = converged && rel < opt.tol;
sol.iterations = totalIter;
sol.relative_residual = rel;
sol.history = history;
end
