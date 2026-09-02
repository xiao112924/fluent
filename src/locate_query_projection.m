function L = locate_query_projection(mesh,point)
%LOCATE_QUERY_PROJECTION 找到任意坐标在管路中心线上的最近投影点。

p = point(:).';
bestDist = inf;
bestE = 0;
bestXi = 0;
bestProj = [];

for e=1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    a = mesh.nodes(n1,:);
    b = mesh.nodes(n2,:);
    ab = b-a;
    xi = dot(p-a,ab)/dot(ab,ab);
    xi = max(0,min(1,xi));
    proj = a+xi*ab;
    d = norm(p-proj);

    if d < bestDist
        bestDist = d;
        bestE = e;
        bestXi = xi;
        bestProj = proj;
    end
end

n1 = mesh.elements(bestE,1);
n2 = mesh.elements(bestE,2);

L.element = bestE;
L.n1 = n1;
L.n2 = n2;
L.xi = bestXi;
L.N1 = 1-bestXi;
L.N2 = bestXi;
L.projected = bestProj;
L.distance = bestDist;
end
