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

## 压力到结构载荷模型

压力场与压力到结构载荷的转换分开配置。当前示例仍使用：

```matlab
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

并显式选择新的物理耦合模型：

```matlab
cfg.coupling.pressure_load_model = 'wall_stress_coupling';
cfg.coupling.wall_formulation = 'thick_wall';
cfg.coupling.capped_end = true;
cfg.coupling.external_pressure = 0;
```

`simple_thrust` 保留旧版 `p*A_i` 端部推力，且旧配置若缺少 `pressure_load_model` 字段仍默认使用该模式，以保证向后兼容。`wall_stress_coupling` 根据内外压、管径、泊松比、薄/厚壁形式和封闭端条件计算管壁轴向压力合力，再沿单元轴向组装到结构节点。

该改动不包含任何逐阶幅值修正、实验拟合系数或人为声学损失倍率。
