function fluidSol = solve_fetm_impedance_pressure(mesh,cfg,omega,Pin,Pout,inletNode,outletNode)
%SOLVE_FETM_IMPEDANCE_PRESSURE OpenPulse-style FETM with one pressure source.
% Exactly one endpoint is prescribed. The opposite endpoint is terminated
% by an acoustic impedance; the unused measured endpoint pressure is not a BC.

if ~isfield(cfg.fluid,'fetm')
    fetm = struct();
else
    fetm = cfg.fluid.fetm;
end
source_end = lower(string(getfield_default(fetm,'source_end','inlet'))); %#ok<GFLD>
if source_end == "inlet"
    sourceNode = inletNode;
    termNode = outletNode;
    sourcePressure = Pin;
    validationPressure = Pout;
elseif source_end == "outlet"
    sourceNode = outletNode;
    termNode = inletNode;
    sourcePressure = Pout;
    validationPressure = Pin;
else
    error('PipePulse:FETMSource','source_end 必须为 inlet 或 outlet。');
end

if isfield(fetm,'termination')
    termination = fetm.termination;
else
    termination = struct('type','anechoic');
end
eta = getfield_default(fetm,'proportional_loss',0.0); %#ok<GFLD>
if eta < 0
    error('PipePulse:FETMLoss','proportional_loss 必须 >= 0。');
end
if isfield(cfg,'excitation') && isfield(cfg.excitation,'base_frequency')
    omegaRef = 2*pi*cfg.excitation.base_frequency;
else
    omegaRef = omega;
end

n = mesh.nnode;
Yglob = sparse(n,n);
YeCache = cell(mesh.nelem,1);
Zpe = complex(zeros(mesh.nelem,1));

for e=1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    L = norm(mesh.nodes(n2,:)-mesh.nodes(n1,:));
    Di = mesh.Di(e);
    A = pi*Di^2/4;
    c = effective_wave_speed(Di,mesh.Do(e),cfg.solid,cfg.fluid);
    hyst = 1 - 1i*eta;
    k = (omega/c)*hyst;
    Zspecific = cfg.fluid.rho*c*hyst;
    Zv = Zspecific/A;
    Ye = fetm_acoustic_admittance(k,Zv,L);
    id = [n1 n2];
    Yglob(id,id) = Yglob(id,id) + Ye;
    YeCache{e} = Ye;
    Zpe(e) = Zv/L; % diagnostic p/(Q*length), not Womersley series impedance
end

% Termination characteristic impedance uses the element connected to termNode.
conn = find(mesh.elements(:,1)==termNode | mesh.elements(:,2)==termNode,1,'first');
if isempty(conn)
    error('PipePulse:FETMTopology','端节点未连接声学单元。');
end
DiT = mesh.Di(conn);
AT = pi*DiT^2/4;
cT = effective_wave_speed(DiT,mesh.Do(conn),cfg.solid,cfg.fluid);
ZcharT = cfg.fluid.rho*cT*(1-1i*eta)/AT;
Zterm = acoustic_termination_impedance(termination,omega,ZcharT,omegaRef);
Yglob(termNode,termNode) = Yglob(termNode,termNode) + 1/Zterm;

known = sourceNode; % intentionally one hard-pressure boundary only
free = setdiff((1:n).',known);
p = complex(zeros(n,1));
p(known) = sourcePressure;
p(free) = -Yglob(free,free) \ (Yglob(free,known)*sourcePressure);

% Element centre-volume-flow approximation from the two nodal FETM flows.
Qe = complex(zeros(mesh.nelem,1));
for e=1:mesh.nelem
    id = mesh.elements(e,:);
    qe = YeCache{e} * p(id);
    Qe(e) = 0.5*(qe(1)-qe(2));
end

fluidSol.p = p;
fluidSol.Qe = Qe;
fluidSol.Zpe = Zpe;
fluidSol.pressure_field_model = 'fetm_impedance';
fluidSol.source_node = sourceNode;
fluidSol.termination_node = termNode;
fluidSol.termination_impedance = Zterm;
fluidSol.validation_opposite_pressure = validationPressure;
fluidSol.predicted_opposite_pressure = p(termNode);
end

function value = getfield_default(s,name,defaultValue)
if isfield(s,name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
