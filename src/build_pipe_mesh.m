function mesh = build_pipe_mesh(seg,bends,cfg)
%BUILD_PIPE_MESH 对直管和自动重建弯管进行1D中心线网格划分。

nodes = zeros(0,3);
elements = zeros(0,2);
Di = zeros(0,1);
Do = zeros(0,1);
part_type = strings(0,1);
part_id = zeros(0,1);

% 第一段起点
nodes(end+1,:) = seg(1).p1;

for i=1:numel(seg)
    % ----- 直管 -----
    p1 = seg(i).p1;
    p2 = seg(i).p2;
    L = norm(p2-p1);
    ne = max(1,ceil(L/cfg.mesh.size));
    ss = linspace(0,1,ne+1);

    % 当前nodes最后一点应当与p1一致；第一段以后上一弯头终点即p1。
    if norm(nodes(end,:)-p1) > 1e-7
        nodes(end+1,:) = p1;
    end
    for k=2:numel(ss)
        p = p1 + ss(k)*(p2-p1);
        nodes(end+1,:) = p;
        elements(end+1,:) = [size(nodes,1)-1,size(nodes,1)];
        Di(end+1,1) = seg(i).Di;
        Do(end+1,1) = seg(i).Do;
        part_type(end+1,1) = "straight";
        part_id(end+1,1) = i;
    end

    % ----- 弯管 -----
    if i <= numel(bends)
        b = bends(i);
        Lb = abs(b.R*b.theta);
        nb = max(cfg.mesh.min_bend_elements,ceil(Lb/cfg.mesh.size));
        aa = linspace(0,b.theta,nb+1);

        c = b.center(:);
        v0 = b.p1(:)-c;
        n = b.normal(:);
        for k=2:numel(aa)
            v = rodrigues_rotate(v0,n,aa(k));
            p = (c+v).';
            nodes(end+1,:) = p;
            elements(end+1,:) = [size(nodes,1)-1,size(nodes,1)];
            Di(end+1,1) = b.Di;
            Do(end+1,1) = b.Do;
            part_type(end+1,1) = "bend";
            part_id(end+1,1) = i;
        end
        % 数值上强制最后一个弯管节点等于下一段切点
        nodes(end,:) = b.p2;
    end
end

mesh.nodes = nodes;
mesh.elements = elements;
mesh.Di = Di;
mesh.Do = Do;
mesh.part_type = part_type;
mesh.part_id = part_id;
mesh.nnode = size(nodes,1);
mesh.nelem = size(elements,1);
end

function vr = rodrigues_rotate(v,k,ang)
k = k/norm(k);
vr = v*cos(ang) + cross(k,v)*sin(ang) + k*dot(k,v)*(1-cos(ang));
end
