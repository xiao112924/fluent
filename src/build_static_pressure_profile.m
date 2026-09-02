function p0 = build_static_pressure_profile(mesh,inletNode,outletNode,PinMean,PoutMean)
%BUILD_STATIC_PRESSURE_PROFILE 构造用于预应力的静压平均场。
%
% 假设：
%   1) 管路拓扑是一条顺序中心线；
%   2) 入口/出口位于该中心线两端；
%   3) 平均静压在入口和出口之间按中心线弧长线性变化。
%
% 输入：
%   PinMean  - 入口平均静压，Pa
%   PoutMean - 出口平均静压，Pa
%
% 输出：
%   p0       - 每个节点的平均静压，Pa
%
% 说明：
%   当前快速模型不求解稳态流阻，因此用线性静压梯度近似。
%   若入口/出口静压相同，则全管静压为常数。

s = zeros(mesh.nnode,1);
for e = 1:mesh.nelem
    n1 = mesh.elements(e,1);
    n2 = mesh.elements(e,2);
    L = norm(mesh.nodes(n2,:)-mesh.nodes(n1,:));
    if n2 == n1 + 1
        s(n2) = s(n1) + L;
    else
        % 当前网格生成器是顺序链式拓扑；若用户未来扩展拓扑，
        % 这里直接报错而不静默猜测。
        error('PipePulse:StaticPressureTopology',...
            '当前静压分布计算要求管路为顺序链式拓扑。');
    end
end

sin = s(inletNode);
sout = s(outletNode);

if abs(sin-sout) < eps
    error('PipePulse:StaticPressureBoundary',...
        '静压分布计算中，入口节点与出口节点不能相同。');
end

eta = (s-sout)/(sin-sout);
p0 = PoutMean + eta*(PinMean-PoutMean);
end
