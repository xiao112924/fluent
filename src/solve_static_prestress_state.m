function PS = solve_static_prestress_state(mesh,cfg,S,p0node,inletNode,outletNode)
%SOLVE_STATIC_PRESTRESS_STATE
% 先求平均静压下的静力平衡，再从平衡状态提取有效轴力。
%
% 流程：
%   1) 平均静压 -> 静态等效管壁载荷 F0
%   2) K + 端部弹簧 -> 静力位移 U0
%   3) 从 U0 求每个梁单元的管壁轴力 Nwall
%   4) Neff = Nwall - p*Ai
%   5) 用 Neff 组装几何刚度 KG
%
% 这比“直接把 p*Ai 当成几何刚度轴力”更接近
% 预应力静力平衡 -> 切线刚度 的处理逻辑。

factor = cfg.prestress.closed_end_factor;
pext = cfg.prestress.external_pressure;

F0 = static_pipe_pressure_load(mesh,p0node,pext,factor);

Kstat = S.K;
[Kstat,fixed] = apply_boundary_impedance( ...
    Kstat,cfg,inletNode,outletNode,0);

allD = (1:S.ndof).';
free = setdiff(allD,fixed);

U0 = zeros(S.ndof,1);
if ~isempty(free)
    U0(free) = Kstat(free,free)\F0(free);
end

Nwall = zeros(mesh.nelem,1);
Neff = zeros(mesh.nelem,1);
pElem = zeros(mesh.nelem,1);

I = []; J = []; V = [];

for e = 1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);

    x1 = mesh.nodes(n1,:);
    x2 = mesh.nodes(n2,:);
    L = norm(x2-x1);

    [~,~,T] = beam3d_element( ...
        x1,x2,mesh.Di(e),mesh.Do(e),cfg.solid,cfg.fluid, ...
        cfg.structure.beam_theory);

    dof = [(6*n1-5):(6*n1), (6*n2-5):(6*n2)];
    uloc = T*U0(dof);

    Awall = pi/4*(mesh.Do(e)^2-mesh.Di(e)^2);

    % 拉伸为正：u2_local_x > u1_local_x
    Nwall(e) = cfg.solid.E*Awall/L * (uloc(7)-uloc(1));

    pElem(e) = 0.5*(p0node(n1)+p0node(n2));

    Neff(e) = effective_pressure_axial_force( ...
        Nwall(e),pElem(e),mesh.Di(e),pext,factor);

    Kg = beam3d_geometric_stiffness( ...
        x1,x2,Neff(e),mesh.Di(e),mesh.Do(e),cfg.solid, ...
        cfg.structure.beam_theory);

    [ii,jj] = ndgrid(dof,dof);
    I = [I; ii(:)]; %#ok<AGROW>
    J = [J; jj(:)]; %#ok<AGROW>
    V = [V; Kg(:)]; %#ok<AGROW>
end

PS.KG = sparse(I,J,V,S.ndof,S.ndof);
PS.U0 = U0;
PS.F0 = F0;
PS.pNode = p0node;
PS.pElem = pElem;
PS.Nwall = Nwall;
PS.Neff = Neff;
end
