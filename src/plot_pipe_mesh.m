function plot_pipe_mesh(mesh,bends)
%PLOT_PIPE_MESH 显示自动重建后的中心线网格。
figure('Name','PipePulse 自动网格','Color','w');

plot3(mesh.nodes(:,1),mesh.nodes(:,2),mesh.nodes(:,3),'-o', ...
    'LineWidth',1.0,'MarkerSize',2);

axis equal;
grid on;
xlabel('X 坐标 (m)');
ylabel('Y 坐标 (m)');
zlabel('Z 坐标 (m)');

title(sprintf('自动生成的管路中心线网格：%d 个节点，%d 个单元', ...
    mesh.nnode,mesh.nelem));

hold on;
for i = 1:numel(bends)
    c = bends(i).center;
    plot3(c(1),c(2),c(3),'x', ...
        'MarkerSize',7,'LineWidth',1.2);
end
hold off;
end
