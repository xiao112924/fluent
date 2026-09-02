function R = query_point_response(result,point,direction)
%QUERY_POINT_RESPONSE 输入空间坐标，返回最近管段投影点处的响应。
%
% 当前采用细网格上的线性复幅值插值。mesh_size足够小时精度稳定。

mesh = result.mesh;
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

e = bestE;
xi = bestXi;
n1 = mesh.elements(e,1);
n2 = mesh.elements(e,2);
N1 = 1-xi; N2 = xi;

dof1 = (6*n1-5):(6*n1-3);
dof2 = (6*n2-5):(6*n2-3);

U = N1*result.U(dof1,:) + N2*result.U(dof2,:);
V = N1*result.V(dof1,:) + N2*result.V(dof2,:);
A = N1*result.A(dof1,:) + N2*result.A(dof2,:);
P = N1*result.P(n1,:) + N2*result.P(n2,:);

dir = direction(:);
if norm(dir)==0
    error('PipePulse:Direction','Sensor direction cannot be zero.');
end
dir = dir/norm(dir);
As = dir.'*A;
Us = dir.'*U;
Vs = dir.'*V;

% 单元流量
Q = result.Q(e,:);

R.point_requested = p;
R.point_projected = bestProj;
R.distance = bestDist;
R.element = e;
R.element_part_type = mesh.part_type(e);
R.element_part_id = mesh.part_id(e);
R.xi = xi;
R.direction = dir.';
R.frequency = result.frequency;
R.Uxyz = U;
R.Vxyz = V;
R.Axyz = A;
R.Us = Us;
R.Vs = Vs;
R.As = As;
R.P = P;
R.Q = Q;

R.U_amp = abs(Us).';
R.V_amp = abs(Vs).';
R.A_amp = abs(As).';
R.A_g = abs(As).'/9.80665;
R.P_amp = abs(P).';
R.Q_amp = abs(Q).';
R.U_phase_deg = angle(Us).'*180/pi;
R.A_phase_deg = angle(As).'*180/pi;
R.P_phase_deg = angle(P).'*180/pi;

% 重建一个基频周期时域
f0 = result.cfg.excitation.base_frequency;
ns = max(4096,result.cfg.excitation.fft_samples);
T = 1/f0;
t = (0:ns-1).'/ns*T;
at = zeros(ns,1);
ut = zeros(ns,1);
pt = result.pressure_harmonics.inlet.mean*0; % 只输出动态局部压力
for k=1:numel(result.frequency)
    at = at + real(As(k)*exp(1i*2*pi*result.frequency(k)*t));
    ut = ut + real(Us(k)*exp(1i*2*pi*result.frequency(k)*t));
    pt = pt + real(P(k)*exp(1i*2*pi*result.frequency(k)*t));
end
R.time = t;
R.a_time = at;
R.u_time = ut;
R.p_time_dynamic = pt;
end
