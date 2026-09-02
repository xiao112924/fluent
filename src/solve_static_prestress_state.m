function PS = solve_static_prestress_state(mesh,cfg,S,p0node,inletNode,outletNode)
%SOLVE_STATIC_PRESTRESS_STATE
% 先求平均静压下的静力平衡，再从平衡状态提取有效轴力。

factor = cfg.prestress.closed_end_factor;
pext = cfg.prestress.external_pressure;
if isfield(cfg.prestress,'model') && ~isempty(cfg.prestress.model)
    prestressModel = lower(string(cfg.prestress.model));
else
    prestressModel = "legacy";
end

switch prestressModel
    case "legacy"
        F0 = static_pipe_pressure_load(mesh,p0node,pext,factor);
    case "openpulse"
        F0 = static_pipe_pressure_load_openpulse(mesh,p0node,cfg.solid,cfg.coupling);
    otherwise
        error('PipePulse:PrestressModel','未知 prestress.model: %s。',prestressModel);
end

Kstat = S.K;
[Kstat,fixed] = apply_boundary_impedance(Kstat,cfg,inletNode,outletNode,0);
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

    [~,~,T] = beam3d_element(x1,x2,mesh.Di(e),mesh.Do(e),cfg.solid,cfg.fluid, ...
        cfg.structure.beam_theory,get_fluid_mass_model(cfg));
    dof = [(6*n1-5):(6*n1), (6*n2-5):(6*n2)];
    uloc = T*U0(dof);
    Awall = pi/4*(mesh.Do(e)^2-mesh.Di(e)^2);
    Nwall(e) = cfg.solid.E*Awall/L * (uloc(7)-uloc(1));
    pElem(e) = 0.5*(p0node(n1)+p0node(n2));

    switch prestressModel
        case "legacy"
            Neff(e) = effective_pressure_axial_force( ...
                Nwall(e),pElem(e),mesh.Di(e),pext,factor);
        case "openpulse"
            if isfield(cfg.coupling,'external_pressure') && ~isempty(cfg.coupling.external_pressure)
                pextOpen = cfg.coupling.external_pressure;
            else
                pextOpen = 0;
            end
            if isfield(cfg.coupling,'capped_end') && ~isempty(cfg.coupling.capped_end)
                cappedOpen = cfg.coupling.capped_end;
            else
                cappedOpen = true;
            end
            if isfield(cfg.coupling,'wall_formulation') && ~isempty(cfg.coupling.wall_formulation)
                wallOpen = cfg.coupling.wall_formulation;
            else
                wallOpen = 'thin_wall';
            end
            Fp = wall_pressure_axial_resultant(pElem(e),mesh.Di(e),mesh.Do(e), ...
                cfg.solid.nu,pextOpen,cappedOpen,wallOpen);
            % OpenPulse: Te = E*A/L*(u2-u1) - Fp
            Neff(e) = Nwall(e) - Fp;
    end

    Kg = beam3d_geometric_stiffness(x1,x2,Neff(e),mesh.Di(e),mesh.Do(e), ...
        cfg.solid,cfg.structure.beam_theory);
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
PS.model = char(prestressModel);
end

function model = get_fluid_mass_model(cfg)
if isfield(cfg,'structure') && isfield(cfg.structure,'fluid_mass_model')
    model = cfg.structure.fluid_mass_model;
else
    model = 'legacy';
end
end
