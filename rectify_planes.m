%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function res = rectify_planes(x,Gsamp,Gapp,solver,cc,varargin)
cfg = struct('metric_upgrade', true);
[cfg,leftover] = cmp_argparse(cfg,varargin{:});
if cfg.metric_upgrade
    solver = WRAP.lafmn_to_qAl(solver);
end

[model_list,lo_res_list,stats_list] = ...
    fit_coplanar_patterns(solver,x, ...
                          Gsamp,Gsamp,cc,1);
res = struct('model_list', model_list, ...
             'lo_res_list', lo_res_list, ...
             'stats_list', stats_list);