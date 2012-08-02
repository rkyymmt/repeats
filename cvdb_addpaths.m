[cvdb_base_path, name, ext] = fileparts(mfilename('fullpath'));

addpath([cvdb_base_path '/ins']);
addpath([cvdb_base_path '/upd']);
addpath([cvdb_base_path '/sel']);
addpath([cvdb_base_path '/util']);
addpath([cvdb_base_path '/serialization']);

javaaddpath([cvdb_base_path '/vendor/mysql-connector/mysql-connector-' ...
             'java-5.1.14-bin.jar']);
javaaddpath([cvdb_base_path '/vendor/imagedb/imagedb.jar']);
javaaddpath([cvdb_base_path '/vendor/imagedb/imtools.jar']);

% add widebaseline stereo dependencies
addpath([src_base_path '/wbs/matlab/utils']);
addpath([src_base_path '/wbs/matlab/utils/json']);
addpath([src_base_path '/wbs/matlab/utils/uniaccess']);

