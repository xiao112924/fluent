function H = extract_pressure_harmonics(fun,f0,nh,ns)
%EXTRACT_PRESSURE_HARMONICS 从任意周期函数句柄提取傅里叶复幅值。
%
% 约定：
% p(t)=mean + Re(P_n*exp(j*n*w0*t))
% P_n = a_n - j*b_n，对应 a*cos + b*sin

T = 1/f0;
t = (0:ns-1).'/ns*T;
y = fun(t);
y = y(:);
if numel(y) ~= ns
    error('PipePulse:PressureFunction','Pressure function must return one value per time sample.');
end

H.mean = mean(y);
H.P = complex(zeros(nh,1));
for n=1:nh
    H.P(n) = 2/ns * sum(y .* exp(-1i*2*pi*n*f0*t));
end
H.t = t;
end
