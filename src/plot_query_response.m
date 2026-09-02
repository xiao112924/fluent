function plot_query_response(R)
%PLOT_QUERY_RESPONSE 输出关注方向加速度的时域与谐波频域图。

figure('Name','PipePulse query response','Color','w');

subplot(1,2,1);
plot(R.time,R.a_time/9.80665,'LineWidth',1.2);
xlabel('时间 (s)');
ylabel('加速度 (g)');
title('Time-domain response');
grid on;

subplot(1,2,2);
stem(R.frequency,R.A_g,'filled','LineWidth',1.1);
xlabel('频率 (Hz)');
ylabel('加速度幅值 (g)');
title('Harmonic spectrum');
grid on;
end
