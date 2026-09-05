function [Y,q,known,pk] = apply_acoustic_network_sources(Y,q,net,mesh,cfg,omega,Pin,Pout,inletNode,outletNode)
%APPLY_ACOUSTIC_NETWORK_SOURCES Add pressure, flow, and Thevenin sources.
known = zeros(0,1); pk = complex(zeros(0,1));
for i=1:numel(net.sources)
    s = net.sources(i);
    node = resolve_node(s.node,inletNode,outletNode);
    type = lower(string(s.type));
    switch type
        case "pressure"
            sourcePressure = source_value(s,node,Pin,Pout,inletNode,outletNode);
            idx = find(known==node,1);
            if isempty(idx)
                known(end+1,1)=node; %#ok<AGROW>
                pk(end+1,1)=sourcePressure; %#ok<AGROW>
            elseif abs(pk(idx)-sourcePressure) > 1e-9*max(1,abs(sourcePressure))
                error('PipePulse:AcousticSourceConflict','Conflicting prescribed pressure sources.');
            end

        case "volume_flow"
            if ~isfield(s,'value') || isempty(s.value)
                error('PipePulse:AcousticSource','volume_flow requires value.');
            end
            q(node) = q(node) + s.value;

        case "thevenin_pressure"
            sourcePressure = source_value(s,node,Pin,Pout,inletNode,outletNode);
            Zs = source_impedance(s,node,net,mesh,cfg,omega);
            Y(node,node) = Y(node,node) + 1/Zs;
            q(node) = q(node) + sourcePressure/Zs;

        otherwise
            error('PipePulse:AcousticSource','Unknown acoustic source type: %s',type);
    end
end
end

function node = resolve_node(value,inletNode,outletNode)
if isnumeric(value)
    node = value;
else
    tag = lower(string(value));
    if tag=="inlet", node=inletNode; elseif tag=="outlet", node=outletNode; else
        error('PipePulse:AcousticNode','Node alias must be inlet/outlet or numeric.');
    end
end
end

function value = source_value(s,node,Pin,Pout,inletNode,outletNode)
if isfield(s,'value') && ~isempty(s.value)
    value = s.value;
elseif node==inletNode
    value = Pin;
elseif node==outletNode
    value = Pout;
else
    error('PipePulse:AcousticSource','Source value required for non-endpoint node.');
end
end

function Zs = source_impedance(s,node,net,mesh,cfg,omega)
if isfield(s,'impedance') && isnumeric(s.impedance)
    Zs = s.impedance;
elseif isfield(s,'impedance') && isstruct(s.impedance)
    Zchar = node_zchar(node,net,mesh,cfg);
    omegaRef = omega;
    if isfield(cfg,'excitation') && isfield(cfg.excitation,'base_frequency')
        omegaRef=2*pi*cfg.excitation.base_frequency;
    end
    Zs = acoustic_termination_impedance(s.impedance,omega,Zchar,omegaRef);
else
    error('PipePulse:AcousticSource','thevenin_pressure requires source impedance.');
end
allowActive = isfield(s,'allow_active') && logical(s.allow_active);
if ~allowActive && real(Zs)<0
    error('PipePulse:ActiveAcousticSource','Passive source impedance requires real(Zs)>=0.');
end
if ~isfinite(abs(Zs)) || abs(Zs)==0
    error('PipePulse:AcousticSource','Source impedance must be finite and nonzero.');
end
end

function Zchar = node_zchar(node,net,mesh,cfg)
for i=1:numel(net.elements)
    el=net.elements(i);
    if ~strcmpi(el.type,'pipe_fetm') || ~any(el.nodes==node), continue; end
    if isfield(el,'structural_element') && ~isempty(el.structural_element)
        e=el.structural_element; Di=mesh.Di(e); Do=mesh.Do(e);
    else
        Di=el.Di; Do=el.Do;
    end
    c=effective_wave_speed(Di,Do,cfg.solid,cfg.fluid);
    Zchar=cfg.fluid.rho*c/(pi*Di^2/4);
    return;
end
error('PipePulse:AcousticSource','Cannot infer characteristic impedance at source node.');
end
