function net = build_acoustic_network_from_mesh(mesh,cfg)
%BUILD_ACOUSTIC_NETWORK_FROM_MESH Build general acoustic topology.
% Internally use cell arrays of structs so heterogeneous acoustic elements
% (pipe, valve impedance, chamber, source, etc.) can coexist safely.

net = struct();
net.structural_node_count = mesh.nnode;
net.nnode = mesh.nnode;
net.elements = {};
net.sources = {};
net.terminations = {};

nw = struct();
if isfield(cfg.fluid,'network')
    nw = cfg.fluid.network;
end

if ~isfield(nw,'auto_from_structural_mesh') || logical(nw.auto_from_structural_mesh)
    for e = 1:mesh.nelem
        net.elements{end+1,1} = struct( ... %#ok<AGROW>
            'type','pipe_fetm', ...
            'nodes',mesh.elements(e,:), ...
            'structural_element',e);
    end
end

if isfield(nw,'elements') && ~isempty(nw.elements)
    net.elements = [net.elements; normalize_entries(nw.elements)];
end
if isfield(nw,'sources') && ~isempty(nw.sources)
    net.sources = normalize_entries(nw.sources);
end
if isfield(nw,'terminations') && ~isempty(nw.terminations)
    net.terminations = normalize_entries(nw.terminations);
end
if isfield(nw,'nnode') && ~isempty(nw.nnode)
    net.nnode = max(net.nnode,nw.nnode);
end
for e=1:numel(net.elements)
    el = net.elements{e};
    if isfield(el,'nodes') && ~isempty(el.nodes)
        net.nnode = max(net.nnode,max(el.nodes));
    end
end
end

function entries = normalize_entries(value)
if iscell(value)
    entries = value(:);
elseif isstruct(value)
    entries = num2cell(value(:));
else
    error('PipePulse:AcousticNetworkConfig', ...
        'Network elements/sources/terminations must be structs or cell arrays of structs.');
end
for i=1:numel(entries)
    if ~isstruct(entries{i})
        error('PipePulse:AcousticNetworkConfig','Each network entry must be a struct.');
    end
end
end
