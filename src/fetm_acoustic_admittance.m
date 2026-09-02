function Ye = fetm_acoustic_admittance(k,Zv,L)
%FETM_ACOUSTIC_ADMITTANCE OpenPulse-style two-node acoustic FETM admittance.
% k  : complex wave number [1/m]
% Zv : characteristic volume impedance p/Q [Pa*s/m^3]
% L  : element length [m]
%
% Ye = i/(Zv*sin(kL))*[-cos(kL) 1; 1 -cos(kL)]

if L <= 0
    error('PipePulse:FETMLength','FETM单元长度必须为正值。');
end
if ~isfinite(abs(Zv)) || abs(Zv) == 0
    error('PipePulse:FETMImpedance','特征体积阻抗必须为有限非零值。');
end
s = sin(k*L);
if abs(s) < 1e-12
    error('PipePulse:FETMSingularity', ...
        'FETM单元满足 sin(kL)≈0；请细化声学网格或检查频率。');
end
c = cos(k*L);
Ye = (1i/(Zv*sin(k*L))) * [-c,1;1,-c];
end
