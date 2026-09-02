# 当前 5% 阻尼 + HBM 打包版（2026-09-02）

本仓库为当前正式 PipePulse 版本：Timoshenko 管梁 + 修正压力传递 + 5% 结构阻尼 + AFT-HBM。

当前默认案例参数：

- 整体结构阻尼：`zeta = 5%`
- 两端平动刚度：`Kt = 1.598676e7 N/m`
- 两端转动刚度：`Kr = 1.237086e3 N*m/rad`
- 两端平动阻尼：`Ct = 758.545 N*s/m`
- 两端转动阻尼：`Cr = 1.900684 N*m*s/rad`
- 两端参数完全相同。
- 动态压力使用当前原始 1~8 阶出入口表达式，不使用额外 `1.62` 幅值放大。
- 压力沿程默认采用 `endpoint_constrained` 线性复压力插值；旧 `acoustic_bvp` 仅用于对照。

主要入口：

- `run_final.m`：线性 Timoshenko 频域计算。
- `run_hbm.m`：AFT-HBM 多谐波非线性计算。
- `run_hbm_sweep.m`：HBM 单频扫频/延拓计算。

HBM 非线性形式保留二次、三次非线性边界项；入口/出口 XYZ 平移自由度可叠加非线性，转动边界保持线性。

## 动态压力传递

默认：

```matlab
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

每一阶入口和出口复压力沿管路中心线弧长做端点约束线性插值，再转为结构节点压力推力，避免在缺少真实端部声学阻抗时由双端定压声学 BVP 产生异常驻波放大。

旧模式仍保留：

```matlab
cfg.fluid.pressure_field_model = 'acoustic_bvp';
```

压力推力符号采用：单元起点 `-p1*A*t`，终点 `+p2*A*t`。
