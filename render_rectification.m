%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function [rimg,trect,T,A,refpt] = render_rectification(img,H,cc,q,varargin)
cfg = struct('cspond', [], ...
             'boundary', [], ...
             'minscale', 0.1, ...
             'maxscale', 5); 

[cfg,lefotver] = cmp_argparse(cfg,varargin{:});

[ny,nx,~] = size(img);
dims = [ny nx];

if isempty(cfg.boundary) && ...
        isempty(cfg.rect) &&...
        ~isempty(cfg.cspond)
    v = cfg.cspond;
    x =  PT.renormI(H*CAM.ru_div(v,cc,q));
    idx = convhull(x(1,:),x(2,:));
    mux = mean(x(:,idx),2);
    refpt = CAM.rd_div(PT.renormI(inv(H)*mux),cc,q);
    boundary = IMG.calc_rectification_boundary(dims,transpose(H(3,:)),cc,q, ...
                                               cfg.minscale,cfg.maxscale, ...
                                               refpt);
    leftover = cat(2,leftover, ...
                   'boundary',boundary, ...
                   'cspond',cspond);
end

[rimg,trect,T,A] = ...
    IMG.ru_div_rectify(img,cc,H,q, ...
                       'Fill', [255 255 255]', ...
                       'Dims', dims, ...
                       leftover{:});