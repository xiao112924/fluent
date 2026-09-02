function [Ke,Me,T] = beam3d_element(x1,x2,Di,Do,solid,fluid,beamTheory,fluidMassModel)
%BEAM3D_ELEMENT 3D 管梁单元（Euler-Bernoulli / Timoshenko）。
% DOF顺序:
% [ux uy uz rx ry rz]node1, [ux uy uz rx ry rz]node2
%
% Timoshenko 模型：
% 1) 弯曲刚度考虑横向剪切变形；
% 2) 弯曲平动质量使用与 Timoshenko 位移场一致的质量矩阵；
% 3) 同时加入与剪切参数一致的截面转动惯量质量矩阵；
% 4) 环形截面剪切修正系数采用 Cowper 型表达式。

if nargin < 7 || isempty(beamTheory)
    beamTheory = 'euler_bernoulli';
end
if nargin < 8 || isempty(fluidMassModel)
    fluidMassModel = 'legacy';
end
beamTheory = lower(strtrim(beamTheory));
fluidMassModel = lower(strtrim(fluidMassModel));

dx = x2(:)-x1(:);
L = norm(dx);
if L <= 0
    error('PipePulse:BeamLength','梁单元长度必须为正值。');
end
ex = dx/L;

ref = [0;0;1];
if abs(dot(ex,ref)) > 0.90
    ref = [0;1;0];
end
ez = cross(ex,ref); ez = ez/norm(ez);
ey = cross(ez,ex);  ey = ey/norm(ey);
R = [ex.';ey.';ez.'];
T = blkdiag(R,R,R,R);

A = pi/4*(Do^2-Di^2);
Ai = pi/4*Di^2;
Iy = pi/64*(Do^4-Di^4);
Iz = Iy;
J = pi/32*(Do^4-Di^4);
E = solid.E;
nu = solid.nu;
G = E/(2*(1+nu));

K = zeros(12);
K([1 7],[1 7]) = E*A/L*[1 -1;-1 1];
K([4 10],[4 10]) = G*J/L*[1 -1;-1 1];

switch beamTheory
    case {'timoshenko','timo'}
        kappa = shear_correction_annulus(Di,Do,nu);
        phi_y = 12*E*Iy/(kappa*G*A*L^2);
        phi_z = 12*E*Iz/(kappa*G*A*L^2);
        Kby = bend_k_timoshenko(E*Iy,L,phi_y);
        Kbz = bend_k_timoshenko(E*Iz,L,phi_z);
    case {'euler_bernoulli','euler','eb'}
        phi_y = 0;
        phi_z = 0;
        Kby = bend_k_euler(E*Iy,L);
        Kbz = bend_k_euler(E*Iz,L);
    otherwise
        error('未知梁理论: %s。可选 euler_bernoulli / timoshenko。',beamTheory);
end

idx_y = [2 6 8 12];
K(idx_y,idx_y) = Kbz;
idx_z = [3 5 9 11];
Ssgn = diag([1 -1 1 -1]);
K(idx_z,idx_z) = Ssgn*Kby*Ssgn;

% ---------- 质量矩阵 ----------
% legacy: 保持历史模型，液体质量参与梁位移场的一致质量与横向转动惯量。
% openpulse_translational: 对齐 OpenPulse，液体只进入 XYZ 平动自由度。
msteel = solid.rho*A;
mfluid = fluid.rho*Ai;
switch fluidMassModel
    case 'legacy'
        mline = msteel + mfluid;
    case 'openpulse_translational'
        mline = msteel;
    otherwise
        error('PipePulse:FluidMassModel', ...
            '未知 fluidMassModel: %s。可选 legacy / openpulse_translational。',fluidMassModel);
end

M = zeros(12);
M([1 7],[1 7]) = mline*L/6*[2 1;1 2];
if strcmp(fluidMassModel,'openpulse_translational')
    Mf2 = mfluid*L/6*[2 1;1 2];
    M([1 7],[1 7]) = M([1 7],[1 7]) + Mf2;
end

switch beamTheory
    case {'timoshenko','timo'}
        Mby = timoshenko_bending_mass(mline,L,phi_y);
        Mbz = timoshenko_bending_mass(mline,L,phi_z);
        M(idx_y,idx_y) = Mbz;
        M(idx_z,idx_z) = Ssgn*Mby*Ssgn;
        if strcmp(fluidMassModel,'openpulse_translational')
            Mf2 = mfluid*L/6*[2 1;1 2];
            M([2 8],[2 8]) = M([2 8],[2 8]) + Mf2;
            M([3 9],[3 9]) = M([3 9],[3 9]) + Mf2;
        end

        Iy_fluid = pi/64*Di^4;
        Iz_fluid = Iy_fluid;
        if strcmp(fluidMassModel,'legacy')
            Iy_line = solid.rho*Iy + fluid.rho*Iy_fluid;
            Iz_line = solid.rho*Iz + fluid.rho*Iz_fluid;
        else
            Iy_line = solid.rho*Iy;
            Iz_line = solid.rho*Iz;
        end
        Mry = timoshenko_rotary_mass(Iy_line,L,phi_y);
        Mrz = timoshenko_rotary_mass(Iz_line,L,phi_z);
        M(idx_y,idx_y) = M(idx_y,idx_y) + Mrz;
        M(idx_z,idx_z) = M(idx_z,idx_z) + Ssgn*Mry*Ssgn;

    otherwise
        Mb = mline*L/420 * ...
            [156 22*L 54 -13*L;
             22*L 4*L^2 13*L -3*L^2;
             54 13*L 156 -22*L;
             -13*L -3*L^2 -22*L 4*L^2];
        M(idx_y,idx_y) = Mb;
        M(idx_z,idx_z) = Ssgn*Mb*Ssgn;
end

Ip_line = solid.rho*J;
M([4 10],[4 10]) = M([4 10],[4 10]) + Ip_line*L/6*[2 1;1 2];

Ke = T.'*K*T;
Me = T.'*M*T;
end

function Kb = bend_k_euler(EI,L)
Kb = EI/L^3 * ...
    [12 6*L -12 6*L;
     6*L 4*L^2 -6*L 2*L^2;
     -12 -6*L 12 -6*L;
     6*L 2*L^2 -6*L 4*L^2];
end

function Kb = bend_k_timoshenko(EI,L,phi)
fac = EI/(L^3*(1+phi));
Kb = fac * ...
    [12 6*L -12 6*L;
     6*L (4+phi)*L^2 -6*L (2-phi)*L^2;
     -12 -6*L 12 -6*L;
     6*L (2-phi)*L^2 -6*L (4+phi)*L^2];
end

function Mb = timoshenko_bending_mass(mline,L,phi)
p2 = phi^2;
fac = mline*L/(840*(1+phi)^2);
a = 312 + 588*phi + 280*p2;
b = (44 + 77*phi + 35*p2)*L;
c = 108 + 252*phi + 140*p2;
d = -(26 + 63*phi + 35*p2)*L;
e = (8 + 14*phi + 7*p2)*L^2;
f = -(6 + 14*phi + 7*p2)*L^2;
g = (26 + 63*phi + 35*p2)*L;
Mb = fac * [a b c d; b e g f; c g a -b; d f -b e];
end

function Mr = timoshenko_rotary_mass(Iline,L,phi)
p2 = phi^2;
fac = Iline/(30*L*(1+phi)^2);
r = (3 - 15*phi)*L;
s = (4 + 5*phi + 10*p2)*L^2;
t = (-1 - 5*phi + 5*p2)*L^2;
Mr = fac * [36 r -36 r; r s -r t; -36 -r 36 -r; r t -r s];
end

function kappa = shear_correction_annulus(Di,Do,nu)
m = Di/Do;
num = 6*(1+nu)*(1+m^2)^2;
den = (7+6*nu)*(1+m^2)^2 + (20+12*nu)*m^2;
kappa = num/den;
end
