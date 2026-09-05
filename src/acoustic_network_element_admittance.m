function [Ye,nodes,meta] = acoustic_network_element_admittance(el,mesh,cfg,omega)
%ACOUSTIC_NETWORK_ELEMENT_ADMITTANCE Complex nodal admittance of one element.
% Positive element flow is defined into the element at each node.

type = lower(string(el.type));
meta = struct('type',char(type),'volume_impedance',[],'structural_element',[]);

switch type
    case "pipe_fetm"
        if isfield(el,'structural_element') && ~isempty(el.structural_element)
            e = el.structural_element;
            nodes = mesh.elements(e,:);
            L = norm(mesh.nodes(nodes(2),:)-mesh.nodes(nodes(1),:));
            Di = mesh.Di(e); Do = mesh.Do(e);
            meta.structural_element = e;
        else
            nodes = el.nodes(:).';
            L = el.length; Di = el.Di; Do = el.Do;
        end
        if numel(nodes) ~= 2 || L <= 0 || Di <= 0 || Do <= Di
            error('PipePulse:AcousticNetworkPipe','Invalid pipe FETM element.');
        end
        c = effective_wave_speed(Di,Do,cfg.solid,cfg.fluid);
        eta = 0;
        if isfield(cfg.fluid,'network') && isfield(cfg.fluid.network,'proportional_loss')
            eta = cfg.fluid.network.proportional_loss;
        end
        if eta < 0
            error('PipePulse:AcousticNetworkLoss','proportional_loss must be >= 0.');
        end
        hyst = 1 - 1i*eta;
        k = (omega/c)*hyst;
        A = pi*Di^2/4;
        Zv = cfg.fluid.rho*c*hyst/A;
        Ye = fetm_acoustic_admittance(k,Zv,L);
        meta.volume_impedance = Zv;

    case "resistance"
        nodes = require_two_nodes(el);
        R = require_nonnegative(el,'R');
        Ye = series_matrix(R);
        meta.volume_impedance = R;

    case "inertance"
        nodes = require_two_nodes(el);
        Lh = require_nonnegative(el,'Lh');
        Z = 1i*omega*Lh;
        Ye = series_matrix(Z);
        meta.volume_impedance = Z;

    case "series_rl"
        nodes = require_two_nodes(el);
        R = require_nonnegative(el,'R');
        Lh = require_nonnegative(el,'Lh');
        Z = R + 1i*omega*Lh;
        Ye = series_matrix(Z);
        meta.volume_impedance = Z;

    case "series_impedance"
        nodes = require_two_nodes(el);
        if ~isfield(el,'value') || isempty(el.value)
            error('PipePulse:AcousticNetworkImpedance','series_impedance requires value.');
        end
        Z = el.value;
        allowActive = isfield(el,'allow_active') && logical(el.allow_active);
        if ~allowActive && real(Z) < 0
            error('PipePulse:ActiveAcousticElement','Passive series impedance requires real(Z)>=0.');
        end
        Ye = series_matrix(Z);
        meta.volume_impedance = Z;

    case "compliance"
        nodes = require_one_node(el);
        if ~isfield(el,'Cq') || isempty(el.Cq) || el.Cq < 0
            error('PipePulse:AcousticCompliance','compliance requires Cq>=0.');
        end
        Cq = el.Cq;
        Ye = 1i*omega*Cq;

    case "chamber"
        nodes = require_one_node(el);
        if ~isfield(el,'volume') || isempty(el.volume) || el.volume < 0
            error('PipePulse:AcousticChamber','chamber requires volume>=0.');
        end
        if isfield(el,'bulk_modulus') && ~isempty(el.bulk_modulus)
            Kf = el.bulk_modulus;
        elseif isfield(cfg.fluid,'bulk') && ~isempty(cfg.fluid.bulk)
            Kf = cfg.fluid.bulk;
        elseif isfield(cfg.fluid,'bulk_modulus') && ~isempty(cfg.fluid.bulk_modulus)
            Kf = cfg.fluid.bulk_modulus;
        else
            error('PipePulse:AcousticChamber','No fluid bulk modulus is available.');
        end
        if Kf <= 0
            error('PipePulse:AcousticChamber','bulk modulus must be positive.');
        end
        Cq = el.volume/Kf;
        Ye = 1i*omega*Cq;

    otherwise
        error('PipePulse:AcousticNetworkElement','Unknown acoustic element type: %s',type);
end
end

function nodes = require_two_nodes(el)
if ~isfield(el,'nodes') || numel(el.nodes) ~= 2
    error('PipePulse:AcousticNetworkTopology','Two-node element requires el.nodes=[n1 n2].');
end
nodes = el.nodes(:).';
end

function nodes = require_one_node(el)
if ~isfield(el,'nodes') || numel(el.nodes) ~= 1
    error('PipePulse:AcousticNetworkTopology','Shunt element requires one node.');
end
nodes = el.nodes(:).';
end

function value = require_nonnegative(el,name)
if ~isfield(el,name) || isempty(el.(name)) || el.(name) < 0
    error('PipePulse:AcousticNetworkParameter','%s must be >=0.',name);
end
value = el.(name);
end

function Ye = series_matrix(Z)
if ~isfinite(abs(Z)) || abs(Z) == 0
    error('PipePulse:AcousticNetworkImpedance','Series impedance must be finite and nonzero.');
end
Y = 1/Z;
Ye = Y*[1 -1;-1 1];
end
