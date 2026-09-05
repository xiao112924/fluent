function [Y,q,known,pk,net,elementCache] = assemble_acoustic_network(mesh,cfg,omega,Pin,Pout,inletNode,outletNode)
%ASSEMBLE_ACOUSTIC_NETWORK Assemble Y*p=q for an arbitrary acoustic network.
net = build_acoustic_network_from_mesh(mesh,cfg);
Y = sparse(net.nnode,net.nnode);
q = complex(zeros(net.nnode,1));
elementCache = cell(numel(net.elements),1);

for i=1:numel(net.elements)
    el = net.elements{i};
    [Ye,nodes,meta] = acoustic_network_element_admittance(el,mesh,cfg,omega);
    Y(nodes,nodes) = Y(nodes,nodes) + Ye;
    elementCache{i} = struct('Ye',Ye,'nodes',nodes,'meta',meta);
end

for i=1:numel(net.terminations)
    term = net.terminations{i};
    node = resolve_node(term.node,inletNode,outletNode);
    Zchar = node_zchar(node,net,mesh,cfg);
    omegaRef = omega;
    if isfield(cfg,'excitation') && isfield(cfg.excitation,'base_frequency')
        omegaRef = 2*pi*cfg.excitation.base_frequency;
    end
    Zt = acoustic_termination_impedance(term,omega,Zchar,omegaRef);
    Y(node,node) = Y(node,node) + 1/Zt;
end

[Y,q,known,pk] = apply_acoustic_network_sources(Y,q,net,mesh,cfg,omega,Pin,Pout,inletNode,outletNode);
end

function node = resolve_node(value,inletNode,outletNode)
if isnumeric(value), node=value; return; end
tag=lower(string(value));
if tag=="inlet", node=inletNode; elseif tag=="outlet", node=outletNode; else
    error('PipePulse:AcousticNode','Node alias must be inlet/outlet or numeric.');
end
end

function Zchar = node_zchar(node,net,mesh,cfg)
for i=1:numel(net.elements)
    el=net.elements{i};
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
error('PipePulse:AcousticTermination','Cannot infer characteristic impedance at termination node.');
end
