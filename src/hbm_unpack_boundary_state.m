function Q = hbm_unpack_boundary_state(z,nBoundary,nHarm)
%HBM_UNPACK_BOUNDARY_STATE 将实数Newton未知向量还原为DC+复谐波矩阵。
n0 = nBoundary;
nh = nBoundary*nHarm;
if numel(z) ~= n0 + 2*nh
    error('PipePulse:HBMStateSize','HBM状态向量长度不正确。');
end
q0 = z(1:n0);
r = z(n0+(1:nh));
im = z(n0+nh+(1:nh));
H = reshape(r + 1i*im,nBoundary,nHarm);
Q = [q0,H];
end
