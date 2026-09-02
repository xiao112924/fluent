function z = hbm_pack_boundary_state(Q)
%HBM_PACK_BOUNDARY_STATE 将DC+复谐波矩阵打包为实数Newton未知向量。
q0 = real(Q(:,1));
H = Q(:,2:end);
z = [q0; real(H(:)); imag(H(:))];
end
