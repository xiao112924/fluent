function plot_hbm_response(R)
%PLOT_HBM_RESPONSE 绘制线性与非线性HBM各阶响应比较。

figure('Color','w','Name','线性与非线性HBM响应比较');
plot(R.linear.frequency,R.linear.A_g,'o--','LineWidth',1.3,'MarkerSize',6);
hold on;
plot(R.hbm.frequency,R.hbm.A_g,'s-','LineWidth',1.4,'MarkerSize',6);
grid on;
xlabel('频率 (Hz)');
ylabel('加速度幅值 (g)');
title('线性频域与非线性AFT-HBM响应比较');
legend('线性频域','非线性HBM','Location','best');
end
