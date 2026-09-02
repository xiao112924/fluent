function S = assemble_structure(mesh,cfg)
%ASSEMBLE_STRUCTURE 组装全局结构质量、刚度、阻尼矩阵。

ndof = 6*mesh.nnode;
I = []; J = []; VK = []; VM = [];

if isfield(cfg,'structure') && isfield(cfg.structure,'beam_theory')
    beamTheory = cfg.structure.beam_theory;
else
    beamTheory = 'euler_bernoulli';
end
if isfield(cfg,'structure') && isfield(cfg.structure,'fluid_mass_model')
    fluidMassModel = cfg.structure.fluid_mass_model;
else
    fluidMassModel = 'legacy';
end

for e=1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    [Ke,Me] = beam3d_element(mesh.nodes(n1,:),mesh.nodes(n2,:),...
        mesh.Di(e),mesh.Do(e),cfg.solid,cfg.fluid,beamTheory,fluidMassModel);
    dof = [node_dofs(n1),node_dofs(n2)];
    [ii,jj] = ndgrid(dof,dof);
    I = [I;ii(:)]; %#ok<AGROW>
    J = [J;jj(:)]; %#ok<AGROW>
    VK = [VK;Ke(:)]; %#ok<AGROW>
    VM = [VM;Me(:)]; %#ok<AGROW>
end

K = sparse(I,J,VK,ndof,ndof);
M = sparse(I,J,VM,ndof,ndof);

zeta = cfg.damping.zeta;
w1 = 2*pi*cfg.damping.f1;
w2 = 2*pi*cfg.damping.f2;
beta = 2*zeta/(w1+w2);
alpha = beta*w1*w2;
C = alpha*M + beta*K;

S.K = K;
S.M = M;
S.C = C;
S.alpha = alpha;
S.beta = beta;
S.ndof = ndof;
end

function d = node_dofs(n)
d = (6*n-5):(6*n);
end
