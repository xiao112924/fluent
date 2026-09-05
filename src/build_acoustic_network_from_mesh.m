function net = build_acoustic_network_from_mesh(mesh,cfg)
%BUILD_ACOUSTIC_NETWORK_FROM_MESH Build general acoustic topology.
net = struct();
net.structural_node_count = mesh.nnode;
net.nnode = mesh.nnode;
net.elements = struct([]);
net.sources = struct([]);
net.terminations = struct([]);

nw = struct();
if isfield(cfg.fluid,'network')
    nw = cfg.fluid.network;
end
if ~isfield(nw,'auto_from_structural_mesh') || logical(nw.auto_from_structural_mesh)
    elems = repmat(struct('type','pipe_fetm','nodes',[],'structural_element',[]),mesh.nelem,1);
    for e = 1:mesh.nelem
        elems(e).nodes = mesh.elements(e,:);
        elems(e).structural_element = e;
    end
    net.elements = elems;
end
if isfield(nw,'elements') && ~isempty(nw.elements)
    if isempty(net.elements), net.elements = nw.elements(:); else, net.elements = [net.elements(:); nw.elements(:)]; end
end
if isfield(nw,'nnode') && ~isempty(nw.nnode)
    net.nnode = max(net.nnode,nw.nnode);
end
for e=1:numel(net.elements)
    if isfield(net.elements(e),'nodes') && ~isempty(net.elements(e).nodes)
        net.nnode = max(net.nnode,max(net.elements(e).nodes));
    end
end
if isfield(nw,'sources'), net.sources = nw.sources; end
if isfield(nw,'terminations'), net.terminations = nw.terminations; end
end
