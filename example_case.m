function cfg = example_case()
%EXAMPLE_CASE 通用算例配置示例
%
% 用户通常只需要修改这个文件和直管段数据文件。

cfg.name = '2p8_example';

% ---------- 直管段 ----------
% 支持 .xlsx / .xls / .csv
cfg.geometry.file = fullfile('examples','straight_segments_2p8.csv');
cfg.geometry.sheet = '直管段信息';  % CSV时忽略
cfg.geometry.length_unit = 'm';

% 自动弯管重建容差
cfg.geometry.arc_radius_rel_tol = 0.03;   % 两端反算半径相对误差上限
cfg.geometry.arc_fit_tol = 5e-5;         % m

% ---------- 自动网格 ----------
cfg.mesh.size = 0.005;        % 目标单元长度，m
cfg.mesh.min_bend_elements = 4;

% ---------- 固体材料 ----------
cfg.solid.name = 'Structural Steel';
cfg.solid.E = 2.00e11;        % Pa
cfg.solid.nu = 0.30;
cfg.solid.rho = 7850;         % kg/m^3

% ---------- 梁理论 ----------
% euler_bernoulli / timoshenko
% 当前默认采用 Timoshenko 梁：考虑横向剪切变形与截面转动惯量。
cfg.structure.beam_theory = 'timoshenko';

% ---------- 流体 ----------
cfg.fluid.name = 'Hydraulic Oil';
cfg.fluid.rho = 850;          % kg/m^3
cfg.fluid.mu = 0.030;         % Pa*s
cfg.fluid.bulk = 1.50e9;      % Pa
cfg.fluid.mean_velocity = 0;  % m/s
cfg.fluid.wave_speed_override = NaN;

% 动态压力沿程模型：
% endpoint_constrained（推荐）：入口/出口复压力均已知时，沿弧长插值，
% 不额外引入1D液柱驻波峰。
% acoustic_bvp：保留旧版Womersley声学边值模型，用于有明确声学端部模型时对照。
cfg.fluid.pressure_field_model = 'endpoint_constrained';


% ---------- 静压预应力 ----------
% true: 将入口/出口平均静压用于结构几何刚度
% false: 退化为旧版，不考虑静压应力刚化
cfg.prestress.enabled = true;

% 闭口端压力推力系数：
% 1.0 -> N0 = (p0-p_external)*Ai
cfg.prestress.closed_end_factor = 1.0;

% 管外环境压力（表压模型可设0）
cfg.prestress.external_pressure = 0;  % Pa

% ---------- 结构阻尼 ----------
% 当前 Timoshenko 线性基线的结构阻尼比。
cfg.damping.zeta = 0.05;      % 5%（当前案例固定整体结构阻尼）
cfg.damping.f1 = 100;         % Rayleigh拟合频率1, Hz
cfg.damping.f2 = 1500;        % Rayleigh拟合频率2, Hz

% ---------- 边界 ----------
% fixed / free / elastic
% 当前默认使用重新识别后的 Timoshenko 两端对称弹性支撑。
cfg.boundary.inlet.type = 'elastic';
cfg.boundary.outlet.type = 'elastic';

Kt = 1.598676e7;              % N/m（当前采用的两端对称平动刚度）
Kr = 1.237086e3;              % N*m/rad（当前采用的两端对称转动刚度）
Ct = 7.585450e2;              % N*s/m（当前采用的两端对称平动阻尼）
Cr = 1.900684;                % N*m*s/rad（当前采用的两端对称转动阻尼）

cfg.boundary.inlet.K = [Kt Kt Kt Kr Kr Kr];
cfg.boundary.inlet.C = [Ct Ct Ct Cr Cr Cr];
cfg.boundary.outlet.K = cfg.boundary.inlet.K;
cfg.boundary.outlet.C = cfg.boundary.inlet.C;

% ---------- 出入口坐标 ----------
% 若留空，则默认：
% outlet = 第一段起点，inlet = 最后一段终点
cfg.boundary.outlet_point = [];
cfg.boundary.inlet_point = [];

% ---------- 脉动压力 ----------
% 必须给基频和最大谐波阶数。
cfg.excitation.base_frequency = 178.813925756;
cfg.excitation.max_harmonic = 8;
cfg.excitation.fft_samples = 16384;

w = 2*pi*cfg.excitation.base_frequency;

% 最终入口/出口压力表达式已直接写入，求解时不再进行额外幅值缩放。
cfg.excitation.Pin = @(t) ...
    20000056.839769 ...
    +80965.065988*cos(1*w*(t-2)) -1657.460805*sin(1*w*(t-2)) ...
    +51310.397883*cos(2*w*(t-2)) +66067.412788*sin(2*w*(t-2)) ...
    -22151.791870*cos(3*w*(t-2)) -4612.573408*sin(3*w*(t-2)) ...
    -9874.823200*cos(4*w*(t-2)) -9064.173884*sin(4*w*(t-2)) ...
    +549.262011*cos(5*w*(t-2)) -6174.990032*sin(5*w*(t-2)) ...
    +10644.665397*cos(6*w*(t-2)) +15443.898297*sin(6*w*(t-2)) ...
    -12744.888046*cos(7*w*(t-2)) -11100.822572*sin(7*w*(t-2)) ...
    +3180.555256*cos(8*w*(t-2)) -1213.434758*sin(8*w*(t-2));

cfg.excitation.Pout = @(t) ...
    19789995.992700 ...
    -20298.642981*cos(1*w*(t-2)) -14651.014808*sin(1*w*(t-2)) ...
    +33679.129126*cos(2*w*(t-2)) -21200.864167*sin(2*w*(t-2)) ...
    -21515.645284*cos(3*w*(t-2)) +13336.490118*sin(3*w*(t-2)) ...
    -4149.666848*cos(4*w*(t-2)) -7160.571062*sin(4*w*(t-2)) ...
    +2913.181709*cos(5*w*(t-2)) -914.042992*sin(5*w*(t-2)) ...
    -6617.873292*cos(6*w*(t-2)) -1808.714386*sin(6*w*(t-2)) ...
    +4342.431205*cos(7*w*(t-2)) -240.743892*sin(7*w*(t-2)) ...
    -888.717697*cos(8*w*(t-2)) +535.681065*sin(8*w*(t-2));

% ---------- 可选物理项 ----------
cfg.coupling.include_momentum = true;
cfg.coupling.include_viscous_wall_shear = false;


% ---------- 预应力模态与结构FRF ----------
cfg.modal.n_modes = 10;   % 输出前10阶预应力固有频率

cfg.frf.fmin = 50;        % Hz
cfg.frf.fmax = 1600;      % Hz
cfg.frf.df = 2;           % Hz，连续扫频步长

% ---------- 实验响应识别 ----------
% 原实验测点 -X 方向 1~8 阶加速度幅值，单位 g。
cfg.identification.experimental_acceleration_g = ...
    [0.84 0.68 0.61 0.38 0.12 0.25 0.165 0.115];
% 识别参数：两端对称 Kt/Kr/Ct/Cr + 结构阻尼比 zeta。
cfg.identification.initial = [Kt Kr Ct Cr cfg.damping.zeta];
% 工程搜索边界 [lower; upper]，列顺序 Kt, Kr, Ct, Cr, zeta。
cfg.identification.bounds = ...
    [1e6  1e1  1e0  1e-6 5e-4; ...
     1e9  1e5  1e5  1e1  5e-2];
cfg.identification.max_iterations = 120;
cfg.identification.display = 'iter';
% 联合识别：仅在原实验测点沿管路弧长 ±30 mm 内搜索节点，
% 每个候选点重新识别 Kt/Kr/Ct/Cr/zeta。
cfg.identification.sensor_search_half_window_m = 0.03;
% 相对于 cfg.identification.initial 的逐参数倍率上下限。
cfg.identification.joint_boundary_scale_bounds = [0.2 5.0];

% ---------- 非线性弹支 AFT-HBM ----------
% HBM 与当前线性 Timoshenko 主模型共用几何、流体、预应力和线性边界。
% 非线性仅叠加在入口/出口 XYZ 平移自由度：
%   F_nl = k2*u^2 + k3*u^3
cfg.boundary.nonlinear.enabled = false;  % run_hbm / run_hbm_sweep 会自动开启
cfg.boundary.nonlinear.k2 = 1.0e12;      % N/m^2；设0可关闭二次项
cfg.boundary.nonlinear.k3 = 1.0e17;      % N/m^3；设0可关闭三次项

cfg.hbm.n_harmonics = 8;
cfg.hbm.n_time_samples = 128;
cfg.hbm.tol = 1e-7;
cfg.hbm.max_iter = 25;
cfg.hbm.continuation_steps = 5;
cfg.hbm.fd_rel_step = 1e-5;
cfg.hbm.fd_abs_step = 1e-12;
cfg.hbm.min_line_search = 1/128;

% 单频非线性扫频配置
cfg.hbm_sweep.fmin = 850;       % Hz
cfg.hbm_sweep.fmax = 1030;      % Hz
cfg.hbm_sweep.df = 2;           % Hz
cfg.hbm_sweep.k3_values = [0 3e16 1e17];

% ---------- 输出 ----------
cfg.output.folder = fullfile(pwd,'output');
cfg.output.save_mat = true;
cfg.output.plot_mesh = true;

% ---------- 示例关注点 ----------
cfg.query.point = [13.79358931845804 -0.3716080287539151 -1.582937114159075];
cfg.query.direction = [-1 0 0];
end
