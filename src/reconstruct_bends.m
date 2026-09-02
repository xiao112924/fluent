function bends = reconstruct_bends(seg, cfg)
%RECONSTRUCT_BENDS 根据相邻直管端部切点与切向自动反算圆弧。
%
% 规则：
% 第 i 段终点 seg(i).p2 与第 i+1 段起点 seg(i+1).p1
% 被视为同一弯管的两个切点，切向分别由两段直管方向给出。

n = numel(seg)-1;
bends = repmat(struct('id',0,'p1',[],'p2',[],'center',[],'R',0,...
    'theta',0,'normal',[],'Di',0,'Do',0,'fit_error',0),n,1);

for i=1:n
    p1 = seg(i).p2(:);
    p2 = seg(i+1).p1(:);
    t1 = seg(i).t(:)/norm(seg(i).t);
    t2 = seg(i+1).t(:)/norm(seg(i+1).t);

    cp = cross(t1,t2);
    s = norm(cp);
    if s < 1e-10
        error('PipePulse:ParallelSegments',...
            'Segments %d and %d are parallel; a unique circular bend cannot be reconstructed.',i,i+1);
    end
    nplane = cp/s;

    % 对给定弯曲平面，半径方向与切向垂直。
    r1 = cross(nplane,t1);
    r2 = cross(nplane,t2);

    A = [r1, -r2];
    ab = A \ (p2-p1);
    c1 = p1 + ab(1)*r1;
    c2 = p2 + ab(2)*r2;
    center = 0.5*(c1+c2);
    R1 = norm(p1-center);
    R2 = norm(p2-center);
    R = 0.5*(R1+R2);
    fiterr = max([norm(c1-c2),abs(R1-R2)]);

    if fiterr > cfg.geometry.arc_fit_tol
        error('PipePulse:BendFit',...
            ['Bend %d between segments %d-%d is inconsistent. Fit error %.6g m exceeds %.6g m. ' ...
             'Check that straight-segment endpoints are true bend tangency points.'],...
             i,i,i+1,fiterr,cfg.geometry.arc_fit_tol);
    end

    rr = abs(R1-R2)/max(R,eps);
    if rr > cfg.geometry.arc_radius_rel_tol
        error('PipePulse:BendRadiusMismatch','Bend %d radius mismatch %.3f%%.',i,100*rr);
    end

    v1 = (p1-center)/R;
    v2 = (p2-center)/R;
    theta = atan2(dot(nplane,cross(v1,v2)), dot(v1,v2));

    % 选择与入口切向一致的圆弧方向。
    tangent_test = sign_nonzero(theta)*cross(nplane,v1);
    if dot(tangent_test,t1) < 0
        nplane = -nplane;
        theta = atan2(dot(nplane,cross(v1,v2)), dot(v1,v2));
    end

    if abs(theta) > pi
        theta = theta - sign(theta)*2*pi;
    end

    % 直管方向变化的几何转角应与圆弧角绝对值一致。
    turn = acos(max(-1,min(1,dot(t1,t2))));
    if abs(abs(theta)-turn) > 5e-3
        % 不直接终止，只在明显错误时终止。
        if abs(abs(theta)-turn) > 0.05
            error('PipePulse:BendAngle','Bend %d reconstructed angle inconsistent with tangents.',i);
        end
    end

    if abs(seg(i).Di-seg(i+1).Di) > 1e-6 || abs(seg(i).Do-seg(i+1).Do) > 1e-6
        warning('PipePulse:BendDiameter',...
            'Adjacent segment diameters differ at bend %d. Bend diameter uses arithmetic average.',i);
    end

    bends(i).id = i;
    bends(i).p1 = p1.';
    bends(i).p2 = p2.';
    bends(i).center = center.';
    bends(i).R = R;
    bends(i).theta = theta;
    bends(i).normal = nplane.';
    bends(i).Di = 0.5*(seg(i).Di+seg(i+1).Di);
    bends(i).Do = 0.5*(seg(i).Do+seg(i+1).Do);
    bends(i).fit_error = fiterr;
end
end

function s = sign_nonzero(x)
if x >= 0
    s = 1;
else
    s = -1;
end
end
