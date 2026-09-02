function [Zp,Fw] = womersley_series_impedance(omega,Di,fluid)
%WOMERSLEY_SERIES_IMPEDANCE 圆管振荡流单位长度串联阻抗。
%
% 采用 e^(j*w*t) 约定：
% Q = -(A/(j*w*rho))*Fw * dp/dx
% Z' = j*w*rho/(A*Fw)
%
% Fw = 1 - 2*J1(lambda)/(lambda*J0(lambda))
% lambda = sqrt(-j)*alpha
% alpha = R*sqrt(w*rho/mu)

A = pi*Di^2/4;
R = Di/2;

if omega == 0
    Zp = 0;
    Fw = 1;
    return;
end

alpha = R*sqrt(omega*fluid.rho/fluid.mu);
lambda = sqrt(-1i)*alpha;

J0 = besselj(0,lambda);
J1 = besselj(1,lambda);
if abs(lambda*J0) < 1e-12
    Fw = 1;
else
    Fw = 1 - 2*J1/(lambda*J0);
end

Zp = 1i*omega*fluid.rho/(A*Fw);
end
