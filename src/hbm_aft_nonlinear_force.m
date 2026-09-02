function [Fnl,uTime,fTime] = hbm_aft_nonlinear_force(Q,k2,k3,nTime)
%HBM_AFT_NONLINEAR_FORCE AFT计算二次+三次非线性边界力谐波。
%
% 非线性边界力：
%   Fnl = k2*u^2 + k3*u^3
%
% Q(:,1)   : 零频(DC)位移，实数
% Q(:,n+1) : 第n阶复位移幅值，满足
%            u(t)=Q0+sum(real(Qn*exp(j*n*theta)))
%
% 输出Fnl采用同一复幅值约定：
% Fnl(:,1)   = mean(Fnl(t))
% Fnl(:,n+1) = 2/N * sum(Fnl(t)*exp(-j*n*theta))

if nargin < 4 || isempty(nTime)
    nTime = 128;
end
if nTime < 8 || floor(nTime) ~= nTime
    error('PipePulse:HBMTimeSamples','nTime必须为不小于8的整数。');
end

[nBoundary,nCol] = size(Q);
nHarm = nCol - 1;
if nHarm < 1
    error('PipePulse:HBMHarmonics','Q至少必须包含一个动态谐波。');
end
if nTime <= 4*nHarm
    error('PipePulse:HBMAliasing', ...
        '二次+三次非线性AFT要求nTime > 4*nHarm，以避免高阶分量混叠到保留谐波。');
end

k2vec = expand_coefficient(k2,nBoundary,'k2','PipePulse:HBMK2');
k3vec = expand_coefficient(k3,nBoundary,'k3','PipePulse:HBMK3');

theta = 2*pi*(0:nTime-1)/nTime;
uTime = repmat(real(Q(:,1)),1,nTime);
for n = 1:nHarm
    uTime = uTime + real(Q(:,n+1) * exp(1i*n*theta));
end

fTime = k2vec .* (uTime.^2) + k3vec .* (uTime.^3);
Fnl = complex(zeros(nBoundary,nHarm+1));
Fnl(:,1) = mean(fTime,2);
for n = 1:nHarm
    Fnl(:,n+1) = (2/nTime) * sum(fTime .* exp(-1i*n*theta),2);
end
end

function cvec = expand_coefficient(c,nBoundary,name,id)
if isscalar(c)
    if ~isfinite(c)
        error(id,'%s必须为有限标量或有限向量。',name);
    end
    cvec = repmat(c,nBoundary,1);
else
    cvec = c(:);
    if numel(cvec) ~= nBoundary || any(~isfinite(cvec))
        error(id,'%s必须为标量或与边界自由度数量一致的有限向量。',name);
    end
end
end
