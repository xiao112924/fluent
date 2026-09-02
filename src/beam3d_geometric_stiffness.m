function Kg = beam3d_geometric_stiffness(x1,x2,N,Di,Do,solid,beamTheory)
%BEAM3D_GEOMETRIC_STIFFNESS
% 3D 梁在恒定轴向预载下的几何刚度矩阵。
% 支持 Euler-Bernoulli 与 Timoshenko。
%
% 约定：
%   N > 0 : 轴向拉力 -> 应力刚化
%   N < 0 : 轴向压力 -> 应力软化

if nargin < 7 || isempty(beamTheory)
    beamTheory = 'euler_bernoulli';
end
beamTheory = lower(strtrim(beamTheory));

dx = x2(:)-x1(:);
L = norm(dx);
if L <= 0
    error('PipePulse:GeometricStiffness','梁单元长度必须为正值。');
end
if N == 0
    Kg = zeros(12);
    return;
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

switch beamTheory
    case {'timoshenko','timo'}
        E = solid.E;
        nu = solid.nu;
        G = E/(2*(1+nu));
        A = pi/4*(Do^2-Di^2);
        I = pi/64*(Do^4-Di^4);
        kappa = shear_correction_annulus(Di,Do,nu);
        phi = 12*E*I/(kappa*G*A*L^2);
        G4 = timo_geometric4(N,L,phi);
    case {'euler_bernoulli','euler','eb'}
        G4 = N/(30*L) * ...
            [36      3*L    -36      3*L;
             3*L     4*L^2  -3*L    -1*L^2;
            -36     -3*L      36     -3*L;
             3*L    -1*L^2  -3*L     4*L^2];
    otherwise
        error('未知梁理论: %s。',beamTheory);
end

Kloc = zeros(12);
idx = [2 6 8 12];
Kloc(idx,idx) = G4;
idx = [3 5 9 11];
Ssgn = diag([1 -1 1 -1]);
Kloc(idx,idx) = Ssgn*G4*Ssgn;
Kg = T.'*Kloc*T;
end

function G4 = timo_geometric4(N,L,phi)
den = (1+phi)^2;
a = (6/5 + 2*phi + phi^2)/den;
b = (L/10)/den;
c = (2*L^2/15 + L^2*phi/6 + L^2*phi^2/12)/den;
d = (-L^2/30 - L^2*phi/6 - L^2*phi^2/12)/den;
G4 = (N/L) * ...
    [a b -a b;
     b c -b d;
     -a -b a -b;
     b d -b c];
end

function kappa = shear_correction_annulus(Di,Do,nu)
m = Di/Do;
num = 6*(1+nu)*(1+m^2)^2;
den = (7+6*nu)*(1+m^2)^2 + (20+12*nu)*m^2;
kappa = num/den;
end
