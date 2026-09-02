function FRF = compute_structural_frf(result,freq,point,direction)
%COMPUTE_STRUCTURAL_FRF
% 在关注点沿指定方向施加单位谐波力，并在同一位置/方向读取加速度。
%
% 输出单位：
%   acceleration_mps2_per_N
%   acceleration_g_per_N
%
% 这是结构自身的 FRF，不是实际压力在非倍频处的强迫响应。

S = result.structure;
cfg = result.cfg;
mesh = result.mesh;

freq = freq(:);
dir = direction(:);
if norm(dir)==0
    error('PipePulse:Direction','方向向量不能为零。');
end
dir = dir/norm(dir);

L = locate_query_projection(mesh,point);

% 将单位点力按线性形函数分配到投影单元两端节点
Funit = zeros(S.ndof,1);
d1 = (6*L.n1-5):(6*L.n1-3);
d2 = (6*L.n2-5):(6*L.n2-3);
Funit(d1) = Funit(d1) + L.N1*dir;
Funit(d2) = Funit(d2) + L.N2*dir;

Hacc = complex(zeros(numel(freq),1));
Hdisp = complex(zeros(numel(freq),1));

for k=1:numel(freq)
    w = 2*pi*freq(k);

    D = S.Kt - w^2*S.M + 1i*w*S.C;
    [D,fixed] = apply_boundary_impedance( ...
        D,cfg,result.inletNode,result.outletNode,w);

    allD = (1:S.ndof).';
    free = setdiff(allD,fixed);

    u = complex(zeros(S.ndof,1));
    if ~isempty(free)
        u(free) = D(free,free)\Funit(free);
    end

    u1 = u(d1);
    u2 = u(d2);
    up = L.N1*u1 + L.N2*u2;

    us = dir.'*up;
    Hdisp(k) = us;
    Hacc(k) = -w^2*us;
end

FRF.frequency = freq;
FRF.Hdisp = Hdisp;
FRF.Hacc = Hacc;
FRF.displacement_m_per_N = abs(Hdisp);
FRF.acceleration_mps2_per_N = abs(Hacc);
FRF.acceleration_g_per_N = abs(Hacc)/9.80665;
FRF.phase_deg = angle(Hacc)*180/pi;
FRF.point_requested = point(:).';
FRF.point_projected = L.projected;
FRF.distance = L.distance;
FRF.element = L.element;
FRF.direction = dir.';
end
