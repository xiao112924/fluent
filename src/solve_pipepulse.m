function result = solve_pipepulse(cfg)
%SOLVE_PIPEPULSE PipePulse通用脉动响应主求解器。

cfg = apply_physics_profile(cfg);

fprintf('PipePulse：正在读取直管段数据...\n');
seg = load_straight_segments(cfg.geometry.file,cfg.geometry.sheet,cfg.geometry.length_unit);

fprintf('PipePulse: reconstructing %d bends...\n',numel(seg)-1);
bends = reconstruct_bends(seg,cfg);

fprintf('PipePulse: automatic meshing...\n');
mesh = build_pipe_mesh(seg,bends,cfg);
if isfield(cfg.output,'plot_mesh') && cfg.output.plot_mesh
    plot_pipe_mesh(mesh,bends);
end

if isempty(cfg.boundary.outlet_point)
    outletPoint = seg(1).p1;
else
    outletPoint = cfg.boundary.outlet_point;
end
if isempty(cfg.boundary.inlet_point)
    inletPoint = seg(end).p2;
else
    inletPoint = cfg.boundary.inlet_point;
end

outletNode = find_nearest_node(mesh.nodes,outletPoint);
inletNode  = find_nearest_node(mesh.nodes,inletPoint);

fprintf('PipePulse：正在组装三维管路结构矩阵...\n');
S = assemble_structure(mesh,cfg);

fprintf('PipePulse：正在提取脉动压力谐波...\n');
f0 = cfg.excitation.base_frequency;
nh = cfg.excitation.max_harmonic;
Hin = extract_pressure_harmonics(cfg.excitation.Pin,f0,nh,cfg.excitation.fft_samples);
Hout = extract_pressure_harmonics(cfg.excitation.Pout,f0,nh,cfg.excitation.fft_samples);

if isfield(cfg,'prestress') && isfield(cfg.prestress,'enabled') && cfg.prestress.enabled
    fprintf('PipePulse：正在计算静压预应力几何刚度...\n');
    p0node = build_static_pressure_profile(mesh,inletNode,outletNode,Hin.mean,Hout.mean);
    PS = solve_static_prestress_state(mesh,cfg,S,p0node,inletNode,outletNode);
    S.KG = PS.KG;
    S.Kt = S.K + S.KG;
    S.C = S.alpha*S.M + S.beta*S.Kt;
    S.prestress = PS;
    fprintf('  入口平均静压  = %.6g MPa\n',Hin.mean/1e6);
    fprintf('  出口平均静压 = %.6g MPa\n',Hout.mean/1e6);
    fprintf('  管壁轴向力范围 = %.6g ~ %.6g N\n',min(PS.Nwall),max(PS.Nwall));
    fprintf('  有效轴向力范围 = %.6g ~ %.6g N\n',min(PS.Neff),max(PS.Neff));
    fprintf('  最大静态位移 = %.6g mm\n',1e3*max(abs(PS.U0)));
else
    S.KG = sparse(S.ndof,S.ndof);
    S.Kt = S.K;
    S.prestress = [];
end

freq = (1:nh).'*f0;
U = complex(zeros(S.ndof,nh));
P = complex(zeros(mesh.nnode,nh));
Q = complex(zeros(mesh.nelem,nh));
F = complex(zeros(S.ndof,nh));

for k=1:nh
    f = freq(k);
    omega = 2*pi*f;
    fprintf('  harmonic %d/%d : %.6f Hz\n',k,nh,f);
    fs = solve_fluid_harmonic(mesh,cfg,omega,Hin.P(k),Hout.P(k),inletNode,outletNode);
    Fk = pressure_to_structure_load(mesh,cfg,fs);
    D = S.Kt - omega^2*S.M + 1i*omega*S.C;
    [D,fixed] = apply_boundary_impedance(D,cfg,inletNode,outletNode,omega);
    allD = (1:S.ndof).';
    free = setdiff(allD,fixed);
    uk = complex(zeros(S.ndof,1));
    if ~isempty(free)
        uk(free) = D(free,free)\Fk(free);
    end
    U(:,k) = uk;
    P(:,k) = fs.p;
    Q(:,k) = fs.Qe;
    F(:,k) = Fk;
end

result.cfg = cfg;
result.segments = seg;
result.bends = bends;
result.mesh = mesh;
result.structure = S;
result.inletNode = inletNode;
result.outletNode = outletNode;
result.frequency = freq;
result.omega = 2*pi*freq;
result.U = U;
result.V = U .* (1i*result.omega.');
result.A = U .* (-(result.omega.').^2);
result.P = P;
result.Q = Q;
result.F = F;
result.pressure_harmonics.inlet = Hin;
result.pressure_harmonics.outlet = Hout;
result.static_pressure_node = [];
result.static_displacement = [];
result.static_wall_axial_force_element = [];
result.static_effective_axial_force_element = [];

if isfield(S,'prestress') && ~isempty(S.prestress)
    result.static_pressure_node = S.prestress.pNode;
    result.static_displacement = S.prestress.U0;
    result.static_wall_axial_force_element = S.prestress.Nwall;
    result.static_effective_axial_force_element = S.prestress.Neff;
end

if ~exist(cfg.output.folder,'dir')
    mkdir(cfg.output.folder);
end
bendTable = table((1:numel(bends)).',[bends.R].',[bends.theta].'*180/pi,[bends.fit_error].', ...
    'VariableNames',{'Bend','Radius_m','Angle_deg','FitError_m'});
writetable(bendTable,fullfile(cfg.output.folder,'reconstructed_bends.csv'));
if cfg.output.save_mat
    save(fullfile(cfg.output.folder,[cfg.name '_result.mat']),'result','-v7.3');
end
end
