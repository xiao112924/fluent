function seg = load_straight_segments(file, sheet, length_unit)
%LOAD_STRAIGHT_SEGMENTS 读取直管段数据。
% 必须包含：
% 起点X 起点Y 起点Z 终点X 终点Y 终点Z 内径 外径
%
% 推荐表头：
% 序号,起点X,起点Y,起点Z,终点X,终点Y,终点Z,内径,外径,长度

if nargin < 2
    sheet = '';
end
if nargin < 3 || isempty(length_unit)
    length_unit = 'm';
end

[~,~,ext] = fileparts(file);
if strcmpi(ext,'.csv')
    T = readtable(file,'VariableNamingRule','preserve');
else
    if isempty(sheet)
        T = readtable(file,'VariableNamingRule','preserve');
    else
        T = readtable(file,'Sheet',sheet,'VariableNamingRule','preserve');
    end
end

names = T.Properties.VariableNames;

ix1 = find_column(names, {'起点X','x1','X1','start_x'});
iy1 = find_column(names, {'起点Y','y1','Y1','start_y'});
iz1 = find_column(names, {'起点Z','z1','Z1','start_z'});
ix2 = find_column(names, {'终点X','x2','X2','end_x'});
iy2 = find_column(names, {'终点Y','y2','Y2','end_y'});
iz2 = find_column(names, {'终点Z','z2','Z2','end_z'});
idi = find_column(names, {'内径','Di','di','inner_diameter'});
ido = find_column(names, {'外径','Do','do','outer_diameter'});

raw = [T{:,ix1},T{:,iy1},T{:,iz1},T{:,ix2},T{:,iy2},T{:,iz2},T{:,idi},T{:,ido}];
valid = all(isfinite(raw),2);
raw = raw(valid,:);

switch lower(length_unit)
    case 'm'
        scale = 1;
    case 'mm'
        scale = 1e-3;
    case 'cm'
        scale = 1e-2;
    otherwise
        error('PipePulse:LengthUnit','Unsupported length unit: %s',length_unit);
end
raw(:,1:8) = raw(:,1:8)*scale;

if isempty(raw)
    error('PipePulse:NoSegments','No valid straight segments found in %s.',file);
end

n = size(raw,1);
seg = repmat(struct('id',0,'p1',[],'p2',[],'Di',0,'Do',0,'L',0,'t',[]),n,1);
for i=1:n
    p1 = raw(i,1:3);
    p2 = raw(i,4:6);
    d = p2-p1;
    L = norm(d);
    if L <= 0
        error('PipePulse:ZeroLength','Straight segment %d has zero length.',i);
    end
    if raw(i,8) <= raw(i,7)
        error('PipePulse:BadDiameter','Segment %d has Do <= Di.',i);
    end
    seg(i).id = i;
    seg(i).p1 = p1;
    seg(i).p2 = p2;
    seg(i).Di = raw(i,7);
    seg(i).Do = raw(i,8);
    seg(i).L = L;
    seg(i).t = d/L;
end
end

function idx = find_column(names, candidates)
idx = [];
for k=1:numel(candidates)
    m = find(strcmpi(names,candidates{k}),1);
    if ~isempty(m)
        idx = m;
        return;
    end
end
error('PipePulse:MissingColumn','Missing required column. Accepted names: %s',strjoin(candidates,', '));
end
