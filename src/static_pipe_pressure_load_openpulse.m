function F = static_pipe_pressure_load_openpulse(mesh,pnode,solid,coupling)
%STATIC_PIPE_PRESSURE_LOAD_OPENPULSE
% 使用与动态 OpenPulse wall coupling 相同的薄/厚壁、封闭端压力轴向合力。

if isfield(coupling,'external_pressure') && ~isempty(coupling.external_pressure)
    pext = coupling.external_pressure;
else
    pext = 0;
end
if isfield(coupling,'capped_end') && ~isempty(coupling.capped_end)
    cappedEnd = coupling.capped_end;
else
    cappedEnd = true;
end
if isfield(coupling,'wall_formulation') && ~isempty(coupling.wall_formulation)
    wallFormulation = coupling.wall_formulation;
else
    wallFormulation = 'thin_wall';
end

F = zeros(6*mesh.nnode,1);
for e = 1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    dx = mesh.nodes(n2,:) - mesh.nodes(n1,:);
    t = dx(:)/norm(dx);

    N1 = wall_pressure_axial_resultant(pnode(n1),mesh.Di(e),mesh.Do(e), ...
        solid.nu,pext,cappedEnd,wallFormulation);
    N2 = wall_pressure_axial_resultant(pnode(n2),mesh.Di(e),mesh.Do(e), ...
        solid.nu,pext,cappedEnd,wallFormulation);

    f1 = -N1*t;
    f2 = +N2*t;
    d1 = (6*n1-5):(6*n1-3);
    d2 = (6*n2-5):(6*n2-3);
    F(d1) = F(d1) + f1;
    F(d2) = F(d2) + f2;
end
end
