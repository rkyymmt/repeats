function [] = rt_sensitivity()
nx = 1000;
ny = 1000;
cc = [nx/2+0.5; ...
      ny/2+0.5];

name_list = {'$\mH22\vl s$', ...
             '$\mH22\lambda$', ...
             '$\mH22\vl', ...
             '$\mH222\vl\lambda s_i$', ...
             '$\mH32\vl\lambda s_i$', ...
             '$\mH4\vl\lambda s_i$'}; 

solver_list = [ ...
    WRAP.laf22_to_l(cc,'solver_type','linear'), ...        
    WRAP.laf22_to_qH(cc) ...
    WRAP.laf22_to_l(cc,'solver_type','polynomial'), ... 
    WRAP.laf222_to_ql(cc), ...
    WRAP.laf32_to_ql(cc), ...
    WRAP.laf4_to_ql(cc) ] ;

dstr = datestr(now,'yyyymmdd');
out_name = ['ct_sensitivity_' dstr '.mat'];

new_sensitivity(out_name,name_list,solver_list, ...
                'nx',nx,'ny',ny,'cc',cc);
