function [] = greedy_repeats_init(src_path,opt_path)
%set(0,'DefaultFigureRenderer','OpenGL');
%set(0,'DefaultFigureRendererMode', 'manual');
%
[cur_path, name, ext] = fileparts(mfilename('fullpath'));

addpath(genpath(cur_path))

if nargin < 1
    src_path = '~/src/';
end

if nargin < 2
    opt_path = '~/opt/';
end

if ~exist('+MMS','dir')
    addpath(fullfile([opt_path 'mex']));
end

if ~exist('vgtk_init','file')
    vgtk_path = fullfile(src_path, '/vgtk');
    cd(vgtk_path);
    feval('vgtk_init');
    cd(cur_path);
end

if ~exist('cvdb_init','file')
    cvdb_path = fullfile(src_path, '/cvdb');
    cd(cvdb_path);
    feval('cvdb_init'); 
    cd(cur_path);
end

if ~exist('ColumnType','file')
    addpath([src_path '/ckvs']);
end

%if ~exist('+DR','dir')
%    cmpfeat_path = fullfile(src_path, 'cmpfeat');
%    cd(cmpfeat_path);
%    feval('cmpfeat_init'); 
%    cd(cur_path);
%end
