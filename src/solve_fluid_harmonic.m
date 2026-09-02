function fluidSol = solve_fluid_harmonic(mesh,cfg,omega,Pin,Pout,inletNode,outletNode)
%SOLVE_FLUID_HARMONIC 1D液压管路压力复幅值求解。
%
% pressure_field_model:
%   endpoint_constrained (默认)
%       将实测/给定的入口与出口复压力作为硬约束，沿中心线弧长对复压力
%       做插值。该模式不额外生成端点之外的1D声学驻波峰，适用于入口、
%       出口压力时程都已知的工程脉动响应计算。
%
%   acoustic_bvp (兼容旧版)
%       Womersley串联阻抗 + 弹性管波速的1D Helmholtz边值问题。
%       在液柱声学固有频率附近可能产生明显内部驻波放大，应结合实际
%       端部声学阻抗/CFD结果判断是否使用。

if isfield(cfg.fluid,'pressure_field_model') && ~isempty(cfg.fluid.pressure_field_model)
    model = lower(string(cfg.fluid.pressure_field_model));
else
    model = "acoustic_bvp"; % 老配置文件保持向后兼容
end

n = mesh.nnode;
p = complex(zeros(n,1));

switch model
    case "endpoint_constrained"
        % 中心线累计弧长。mesh节点按管路拓扑顺序排列。
        sNode = zeros(n,1);
        for i = 2:n
            sNode(i) = sNode(i-1) + norm(mesh.nodes(i,:)-mesh.nodes(i-1,:));
        end
        sOut = sNode(outletNode);
        sIn  = sNode(inletNode);
        if abs(sIn-sOut) < eps
            error('PipePulse:FluidBoundary','入口与出口节点不能重合。');
        end
        xi = (sNode-sOut)/(sIn-sOut);
        p = Pout + (Pin-Pout).*xi;
        % 严格回写端点，避免浮点误差。
        p(inletNode) = Pin;
        p(outletNode) = Pout;

    case "acoustic_bvp"
        Aglob = sparse(n,n);
        for e=1:mesh.nelem
            n1 = mesh.elements(e,1);
            n2 = mesh.elements(e,2);
            x1 = mesh.nodes(n1,:);
            x2 = mesh.nodes(n2,:);
            L = norm(x2-x1);
            Di = mesh.Di(e);
            A = pi*Di^2/4;

            c = effective_wave_speed(Di,mesh.Do(e),cfg.solid,cfg.fluid);
            [Zp,~] = womersley_series_impedance(omega,Di,cfg.fluid);
            Yp = 1i*omega*A/(cfg.fluid.rho*c^2);
            gamma2 = Zp*Yp;

            Ke = 1/L*[1 -1;-1 1] + gamma2*L/6*[2 1;1 2];
            id = [n1 n2];
            Aglob(id,id) = Aglob(id,id) + Ke;
        end

        known = unique([inletNode,outletNode]);
        pk = zeros(numel(known),1);
        for i=1:numel(known)
            if known(i)==inletNode
                pk(i)=Pin;
            elseif known(i)==outletNode
                pk(i)=Pout;
            end
        end
        free = setdiff((1:n).',known(:));
        p(known) = pk;
        if ~isempty(free)
            p(free) = -Aglob(free,free)\(Aglob(free,known)*pk);
        end

    otherwise
        error('PipePulse:UnknownPressureFieldModel', ...
            '未知 cfg.fluid.pressure_field_model = %s',model);
end

% 每个单元的复流量：由局部压力梯度与Womersley串联阻抗估算。
Qe = complex(zeros(mesh.nelem,1));
Zpe = complex(zeros(mesh.nelem,1));
for e=1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    L = norm(mesh.nodes(n2,:)-mesh.nodes(n1,:));
    [Zp,~] = womersley_series_impedance(omega,mesh.Di(e),cfg.fluid);
    Zpe(e)=Zp;
    dpdx = (p(n2)-p(n1))/L;
    Qe(e) = -dpdx/Zp;
end

fluidSol.p = p;
fluidSol.Qe = Qe;
fluidSol.Zpe = Zpe;
fluidSol.pressure_field_model = char(model);
end
