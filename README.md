# PipePulse：Timoshenko 管路结构 + 液压声学网络 + AFT-HBM

当前功能分支在原有 Timoshenko 管梁、预应力、5%结构阻尼和 AFT-HBM 基础上，加入了 OpenPulse 启发的 FETM 液压声学网络层。

## 当前2.8工程基线

`example_case.m` 保留已经验证过的实验复现组合：

- Timoshenko 管梁；
- 整体结构阻尼 `zeta = 5%`；
- 两端对称弹性支撑：
  - `Kt = 1.598676e7 N/m`
  - `Kr = 1.237086e3 N*m/rad`
  - `Ct = 758.545 N*s/m`
  - `Cr = 1.900684 N*m*s/rad`
- 原始1~8阶入口/出口压力，不使用额外1.62倍率；
- 压力场：`endpoint_constrained`；
- 压力到结构载荷：`simple_thrust`；
- 预应力：`legacy`。

该组合用于当前已有两端实测压力的2.8实验复现。OpenPulse wall-stress耦合和OpenPulse预应力仍保留为独立诊断模式，但不作为2.8正式默认值。

## 四种压力场模式

### 1. `endpoint_constrained`

```matlab
cfg.fluid.pressure_field_model = 'endpoint_constrained';
```

当入口和出口复压力都来自测量时，沿中心线弧长插值。当前2.8实验默认使用该模式，因为它不假设未知的外部液压声学回路。

### 2. `acoustic_network`

```matlab
cfg.fluid.pressure_field_model = 'acoustic_network';
```

这是面向新管路预测的通用模式。结构网格可以自动转换为 OpenPulse-style FETM 管路声学网络，并可继续加入：

- FETM管段；
- 集中阻力；
- 液柱惯性；
- 串联R-L；
- 任意被动复阻抗；
- 液体容腔/等效顺应性；
- 无反射/常阻抗/RLC端接；
- 压力源；
- 体积流量源；
- 带有限源阻抗的Thevenin压力源。

示例见：

```matlab
cfg = example_acoustic_network();
```

### 3. `fetm_impedance`

单根测试管 + 单压力源 + 单端阻抗的诊断模式。用于检查声学传播、阻抗和液柱共振，不推荐代表完整液压试验台。

### 4. `acoustic_bvp`

旧双端声学边值模型，仅保留兼容。缺少真实端部声学阻抗时可能在液柱声学固有频率附近产生异常放大，不推荐作为默认。

## 通用声学网络配置

最简单的入口压力源 + 无反射出口：

```matlab
cfg = example_case();
cfg.fluid.pressure_field_model = 'acoustic_network';
cfg.fluid.network.auto_from_structural_mesh = true;
cfg.fluid.network.proportional_loss = 0;

cfg.fluid.network.sources = {
    struct('type','pressure','node','inlet')
};

cfg.fluid.network.terminations = {
    struct('node','outlet','type','anechoic')
};
```

不同类型元件使用 cell array，可以混装：

```matlab
cfg.fluid.network.elements = {
    struct('type','resistance','nodes',[20 21],'R',2.0e8)
    struct('type','inertance','nodes',[30 31],'Lh',5.0e5)
    struct('type','chamber','nodes',40,'volume',1.0e-4)
};
```

泵存在有限源阻抗时推荐使用Thevenin形式：

```matlab
cfg.fluid.network.sources = {
    struct('type','thevenin_pressure', ...
           'node','inlet', ...
           'impedance',8.0e9)
};
```

`impedance` 单位为 `Pa*s/m^3`。

## 压力到结构载荷模型

当前2.8正式默认：

```matlab
cfg.coupling.pressure_load_model = 'simple_thrust';
```

即按 `p*A_i` 沿单元轴向组装。该离散在直管内部自动抵消，在弯头/方向变化处自然保留压力合力。

OpenPulse启发的：

```matlab
cfg.coupling.pressure_load_model = 'wall_stress_coupling';
```

仍然保留，可选择 `thin_wall` / `thick_wall`、`capped_end` 和外压。它适合作为独立物理对照，不应与完整 `p*A_i` 推力简单叠加。

## HBM

主要入口：

- `run_final.m`：线性频域计算；
- `run_hbm.m`：AFT-HBM 多谐波非线性计算；
- `run_hbm_sweep.m`：HBM 单频扫频/延拓。

HBM非线性接口未因声学网络升级而改写。当前仍支持二次、三次非线性弹性边界项。

## 当前验证结论

- `endpoint_constrained + simple_thrust` 仍是当前2.8实验最好的工程复现基线；
- `acoustic_network` 已通过匹配端行波、T形支路流量守恒、Thevenin/Norton源等价和容腔顺应性解析验证；
- 当前2.8试验台的两端实测压力不能由“单根均匀管 + 单个被动终端”完整解释，因此不能继续靠结构边界识别去补偿缺失的外部液压网络；
- 对新管路做真正预测时，应提供泵源流量/压力谱、源阻抗、阀/节流、外接管段、容腔/蓄能器和终端阻抗等实际液压网络参数。

详细结果见 `validation/acoustic_network/`、`validation/fetm_impedance/` 和 `validation/openpulse_consistent/`。
