function fluidSol = solve_acoustic_network_harmonic(mesh,cfg,omega,Pin,Pout,inletNode,outletNode)
%SOLVE_ACOUSTIC_NETWORK_HARMONIC Solve general nodal hydraulic acoustic network.
[Y,q,known,pk,net,cache] = assemble_acoustic_network(mesh,cfg,omega,Pin,Pout,inletNode,outletNode);
allNodes = (1:net.nnode).';
known = unique(known(:),'stable');
if isempty(known)
    free = allNodes;
else
    free = setdiff(allNodes,known);
end
p = complex(zeros(net.nnode,1));
if ~isempty(known), p(known)=pk; end
if ~isempty(free)
    Yff = Y(free,free);
    if rcond(full(Yff)) < 1e-14
        error('PipePulse:AcousticNetworkSingular','Acoustic network is singular; add a pressure reference or finite termination/source impedance.');
    end
    if isempty(known)
        p(free) = Y(free,free) \ q(free);
    else
        p(free) = Y(free,free) \ (q(free) - Y(free,known)*pk);
    end
end

Qe = complex(zeros(mesh.nelem,1));
for i=1:numel(cache)
    c=cache{i};
    if isempty(c.meta.structural_element), continue; end
    qe=c.Ye*p(c.nodes);
    e=c.meta.structural_element;
    Qe(e)=0.5*(qe(1)-qe(2));
end
fluidSol.p = p(1:net.structural_node_count);
fluidSol.network_p = p;
fluidSol.Qe = Qe;
fluidSol.Zpe = complex(zeros(mesh.nelem,1));
fluidSol.pressure_field_model = 'acoustic_network';
fluidSol.network = net;
fluidSol.prescribed_nodes = known;
end
