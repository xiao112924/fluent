function F = pressure_to_structure_load(mesh,cfg,fluidSol)
%PRESSURE_TO_STRUCTURE_LOAD 将管内压力/动量脉动转成3D管梁节点力。
%
% 对每个小直梁单元:
% node1 += -p1*A*t
% node2 += +p2*A*t
%
% 相邻共线单元内力自动抵消；方向变化处自然留下弯头合力。

F = complex(zeros(6*mesh.nnode,1));

for e=1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    dx = mesh.nodes(n2,:)-mesh.nodes(n1,:);
    L = norm(dx);
    t = dx(:)/L;
    A = pi*mesh.Di(e)^2/4;

    p1 = fluidSol.p(n1);
    p2 = fluidSol.p(n2);

    % 与静压闭口端压力推力采用同一物理方向。
    f1 = -p1*A*t;
    f2 = +p2*A*t;

    if cfg.coupling.include_momentum && abs(cfg.fluid.mean_velocity)>0
        Q = fluidSol.Qe(e);
        fm = 2*cfg.fluid.rho*cfg.fluid.mean_velocity*Q;
        f1 = f1 + fm*t;
        f2 = f2 - fm*t;
    end

    if cfg.coupling.include_viscous_wall_shear
        Zp = fluidSol.Zpe(e);
        Zinertial = 1i*0; %#ok<NASGU>
        % 壁面黏性反力近似：总串联阻抗减去无黏惯性项。
        omega_est = 0; %#ok<NASGU>
        % 该项需要omega才能严格分解，通用v1默认关闭。
    end

    d1 = (6*n1-5):(6*n1-3);
    d2 = (6*n2-5):(6*n2-3);
    F(d1) = F(d1)+f1;
    F(d2) = F(d2)+f2;
end
end
