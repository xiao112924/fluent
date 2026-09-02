function print_query_response(R)
fprintf('\n---------------- Query response ----------------\n');
fprintf('请求关注点坐标 : [%.9g %.9g %.9g]\n',R.point_requested);
fprintf('投影到管路中心线的坐标 : [%.9g %.9g %.9g]\n',R.point_projected);
fprintf('Distance         : %.6g m\n',R.distance);
fprintf('单元          : %d (%s %d)\n',R.element,R.element_part_type,R.element_part_id);
fprintf('Sensor direction : [%.6g %.6g %.6g]\n',R.direction);
fprintf('\n阶次      频率(Hz)       加速度(g)        位移(m)       压力(Pa)\n');
for k=1:numel(R.frequency)
    fprintf('%4d   %10.4f   %12.5g   %12.5g   %12.5g\n',...
        k,R.frequency(k),R.A_g(k),R.U_amp(k),R.P_amp(k));
end
fprintf('------------------------------------------------\n\n');
end
