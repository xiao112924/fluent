function single = build_hbm_single_tone_case(baseResult,cfg,fdrive,Hin1,Hout1,nHarm)
%BUILD_HBM_SINGLE_TONE_CASE 构造单频压力扫频下的线性参考结果。
% 外部压力只作用于基频；2~nHarm阶外载置零，供非线性HBM自行生成高次谐波。

S = baseResult.structure;
mesh = baseResult.mesh;
inletNode = baseResult.inletNode;
outletNode = baseResult.outletNode;
ndof = S.ndof;

freq = (1:nHarm).'*fdrive;
omega = 2*pi*freq;
U = complex(zeros(ndof,nHarm));
P = complex(zeros(mesh.nnode,nHarm));
Q = complex(zeros(mesh.nelem,nHarm));
F = complex(zeros(ndof,nHarm));

% 仅基频使用当前案例的一阶入口/出口压力复幅值。
fs = solve_fluid_harmonic(mesh,cfg,omega(1),Hin1,Hout1,inletNode,outletNode);
F(:,1) = pressure_to_structure_load(mesh,cfg,fs);
P(:,1) = fs.p;
Q(:,1) = fs.Qe;

for n = 1:nHarm
    D = S.Kt - omega(n)^2*S.M + 1i*omega(n)*S.C;
    [D,fixed] = apply_boundary_impedance(D,cfg,inletNode,outletNode,omega(n));
    allD = (1:ndof).';
    free = setdiff(allD,fixed);
    if ~isempty(free) && n == 1
        U(free,n) = D(free,free)\F(free,n);
    end
end

single = baseResult;
single.cfg = cfg;
single.cfg.excitation.base_frequency = fdrive;
single.cfg.excitation.max_harmonic = nHarm;
single.frequency = freq;
single.omega = omega;
single.U = U;
single.V = U .* (1i*omega.');
single.A = U .* (-(omega.').^2);
single.P = P;
single.Q = Q;
single.F = F;
end
