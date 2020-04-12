%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function v = ru_div_tform(u,T)
    if isfield(T.tdata,'cc')
        v = CAM.ru_div(u',T.tdata.cc,T.tdata.q)';
    else
        q = T.tdata.q;
        v = CAM.ru_div(u',q,namedargs2cell(rmfield(T.tdata,'q')))';
    end
end