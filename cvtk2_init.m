function [] = cvtk2_init(wbs_demo_path)
[cvtk_base_path, name, ext] = fileparts(mfilename('fullpath'));

addpath([cvtk_base_path '/eg']);
addpath([cvtk_base_path '/line']);
addpath([cvtk_base_path '/pt']);
addpath([cvtk_base_path '/rnsc']);
addpath([cvtk_base_path '/tc']);
addpath([cvtk_base_path '/scene']);
addpath([cvtk_base_path '/ao']);

addpath([wbs_demo_path]);

% wbs demo init
setpaths
