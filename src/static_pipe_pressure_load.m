function F = static_pipe_pressure_load(mesh,pnode,external_pressure,closed_end_factor)
%STATIC_PIPE_PRESSURE_LOAD
% 平均静压对管结构的等效静力载荷。
%
% 对沿 node1 -> node2 的小直梁：
%   node1 += -p*A*t
%   node2 += +p*A*t
%
% 这与闭口管端盖受内部压力后将管壁拉伸的物理方向一致。
% 相邻共线单元的端部力自动抵消；弯头处保留静压合力。
%
% external_pressure 和 closed_end_factor 为可选参数。

if nargin < 3 || isempty(external_pressure)
    external_pressure = 0;
end
if nargin < 4 || isempty(closed_end_factor)
    closed_end_factor = 1;
end

F = zeros(6*mesh.nnode,1);

for e = 1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);

    dx = mesh.nodes(n2,:) - mesh.nodes(n1,:);
    L = norm(dx);
    t = dx(:)/L;

    Ai = pi*mesh.Di(e)^2/4;

    p1 = closed_end_factor*(pnode(n1)-external_pressure);
    p2 = closed_end_factor*(pnode(n2)-external_pressure);

    f1 = -p1*Ai*t;
    f2 = +p2*Ai*t;

    d1 = (6*n1-5):(6*n1-3);
    d2 = (6*n2-5):(6*n2-3);

    F(d1) = F(d1) + f1;
    F(d2) = F(d2) + f2;
end
end
