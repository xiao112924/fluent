function R = print_hbm_response(linearResult,hbmResult,point,direction)
%PRINT_HBM_RESPONSE 打印非线性HBM响应及与线性结果的比较。

Rlin = query_point_response(linearResult,point,direction);
Rhbm = query_point_response(hbmResult,point,direction);

fprintf('\n====================================================\n');
fprintf('非线性弹支 AFT-HBM 结果\n');
fprintf('k3 = %.6e N/m^3\n',hbmResult.hbm.k3);
fprintf('HBM收敛 = %d\n',hbmResult.hbm.converged);
fprintf('总Newton迭代记录数 = %d\n',hbmResult.hbm.iterations);
fprintf('最终相对残差 = %.6e\n',hbmResult.hbm.relative_residual);
fprintf('----------------------------------------------------\n');
fprintf('阶次    频率(Hz)      线性(g)        HBM(g)       变化(%%)\n');
for n = 1:numel(Rhbm.frequency)
    change = 100*(Rhbm.A_g(n)-Rlin.A_g(n))/max(Rlin.A_g(n),eps);
    fprintf('%2d   %11.6f   %12.6g   %12.6g   %+10.4f\n', ...
        n,Rhbm.frequency(n),Rlin.A_g(n),Rhbm.A_g(n),change);
end
fprintf('====================================================\n');

R.linear = Rlin;
R.hbm = Rhbm;
end
