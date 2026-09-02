function JID = identify_boundary_sensor_joint(cfg)
%IDENTIFY_BOUNDARY_SENSOR_JOINT 联合识别实验测点位置与线性边界参数。
% 外层：在原 query.point 沿管路弧长限定窗口内遍历实际网格节点。
% 内层：每个候选节点调用 identify_experiment_response，识别
%       [Kt, Kr, Ct, Cr, zeta]。
%
% 默认用途是检验“小范围测点误差 + 合理边界变化”能否解释实验差异，
% 不允许在整根管路任意挑选数学最优点。

seg = load_straight_segments(cfg.geometry.file, ...
    cfg.geometry.sheet, cfg.geometry.length_unit);
bends = reconstruct_bends(seg,cfg);
mesh = build_pipe_mesh(seg,bends,cfg);

% 网格由入口到出口依次建立，可直接累计相邻节点距离得到弧长坐标。
s = zeros(mesh.nnode,1);
for i = 2:mesh.nnode
    s(i) = s(i-1) + norm(mesh.nodes(i,:)-mesh.nodes(i-1,:));
end

q0 = cfg.query.point(:).';
[~,centerNode] = min(vecnorm(mesh.nodes-q0,2,2));
s0 = s(centerNode);
halfWindow = cfg.identification.sensor_search_half_window_m;
candidateNodes = find(abs(s-s0) <= halfWindow + 1e-12);
if isempty(candidateNodes)
    error('PipePulse:NoSensorCandidate','测点搜索窗口内没有候选节点。');
end

scaleBounds = cfg.identification.joint_boundary_scale_bounds(:).';
if numel(scaleBounds) ~= 2 || scaleBounds(1) <= 0 || scaleBounds(2) <= scaleBounds(1)
    error('cfg.identification.joint_boundary_scale_bounds 必须为 [lower upper] 且 0<lower<upper。');
end

baseInitial = cfg.identification.initial(:).';
baseBounds = cfg.identification.bounds;
localLB = max(baseBounds(1,:),baseInitial*scaleBounds(1));
localUB = min(baseBounds(2,:),baseInitial*scaleBounds(2));
if any(localLB >= localUB)
    error('联合识别局部边界与原 identification.bounds 不相容。');
end

n = numel(candidateNodes);
summary = nan(n,10);
allID = cell(n,1);

for ic = 1:n
    node = candidateNodes(ic);
    cfgNode = cfg;
    cfgNode.query.point = mesh.nodes(node,:);
    cfgNode.identification.initial = baseInitial;
    cfgNode.identification.bounds = [localLB;localUB];
    cfgNode.identification.display = 'off';

    fprintf('Joint ID: candidate %d/%d, node %d, ds = %+8.3f mm\n', ...
        ic,n,node,1e3*(s(node)-s0));
    ID = identify_experiment_response(cfgNode);
    allID{ic} = ID;
    summary(ic,:) = [node, s(node)-s0, ID.rmse_g, ID.relative_rmse, ...
        ID.params.Kt,ID.params.Kr,ID.params.Ct,ID.params.Cr,ID.params.zeta,ID.objective];
end

[~,ibest] = min(summary(:,4));
bestID = allID{ibest};
bestNode = candidateNodes(ibest);

JID.best_sensor_node = bestNode;
JID.sensor_distance_m = s(bestNode)-s0;
JID.best_sensor_point = mesh.nodes(bestNode,:);
JID.best = bestID;
JID.center_sensor_node = centerNode;
JID.center_sensor_point = mesh.nodes(centerNode,:);
JID.candidate_nodes = candidateNodes;
JID.candidate_ids = allID;
JID.arc_length = s;
JID.boundary_bounds = [localLB;localUB];

T = array2table(summary,'VariableNames', ...
    {'SensorNode','SensorDistance_m','RMSE_g','RelativeRMSE', ...
     'Kt_N_per_m','Kr_Nm_per_rad','Ct_Ns_per_m','Cr_Nms_per_rad','zeta','Objective'});
JID.candidate_table = T;

if ~exist(cfg.output.folder,'dir'), mkdir(cfg.output.folder); end
writetable(T,fullfile(cfg.output.folder,'joint_candidate_summary.csv'));

B = table(bestNode,JID.sensor_distance_m,JID.best_sensor_point(1), ...
    JID.best_sensor_point(2),JID.best_sensor_point(3),bestID.rmse_g,bestID.relative_rmse, ...
    bestID.params.Kt,bestID.params.Kr,bestID.params.Ct,bestID.params.Cr,bestID.params.zeta, ...
    'VariableNames',{'SensorNode','SensorDistance_m','X','Y','Z','RMSE_g','RelativeRMSE', ...
    'Kt_N_per_m','Kr_Nm_per_rad','Ct_Ns_per_m','Cr_Nms_per_rad','zeta'});
writetable(B,fullfile(cfg.output.folder,'joint_best_solution.csv'));

R = table((1:numel(bestID.target_g)).',bestID.frequency,bestID.target_g,bestID.calculated_g, ...
    bestID.relative_error_percent,'VariableNames', ...
    {'Order','Frequency_Hz','Experiment_g','Calculated_g','RelativeError_percent'});
writetable(R,fullfile(cfg.output.folder,'joint_best_response.csv'));
save(fullfile(cfg.output.folder,'joint_identification.mat'),'JID');
end
