function node = find_nearest_node(nodes,point)
d2 = sum((nodes-point(:).').^2,2);
[~,node] = min(d2);
end
