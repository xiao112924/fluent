function [R,Fnl] = hbm_residual(Q,G,Qlin,k2,k3,nTime)
%HBM_RESIDUAL 计算边界降阶AFT-HBM残差。
%
% 零频： R0 = Q0 + G0*Fnl0
% n阶：  Rn = Qn - Qlin_n + Gn*Fnl_n
%
% 非线性力：Fnl = k2*u^2 + k3*u^3
% 方程来源：D_n U_n + B Fnl_n = Fext_n。

[nBoundary,nCol] = size(Q);
nHarm = nCol-1;
if size(Qlin,1) ~= nBoundary || size(Qlin,2) ~= nCol
    error('PipePulse:HBMQlin','Qlin尺寸必须与Q一致。');
end
if numel(G) ~= nHarm+1
    error('PipePulse:HBMReceptance','G必须包含DC和全部动态谐波的边界柔度矩阵。');
end

Fnl = hbm_aft_nonlinear_force(Q,k2,k3,nTime);
R = complex(zeros(size(Q)));
R(:,1) = real(Q(:,1)) + G{1}*Fnl(:,1);
for n = 1:nHarm
    R(:,n+1) = Q(:,n+1) - Qlin(:,n+1) + G{n+1}*Fnl(:,n+1);
end
end
