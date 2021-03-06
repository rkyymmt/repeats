function [] = stability(out_name,varargin)
    cj_init('..');

    num_scenes = 1000;
    nx = 1000;
    ny = 1000;
    cc = [nx/2+0.5; ...
          ny/2+0.5];
    
    wplane = 10;
    hplane = 10;
    
    res = cell2table(cell(0,7), 'VariableNames', ...
                     {'solver','variant','ex_num','q','rms','rewarp','solver_time'});
    gt = cell2table(cell(0,4), 'VariableNames', ...
                    {'ex_num', 'scene_num', 'q_gt','sigma'});

    sample_type_strings = {'laf1x2','laf2x2','laf2x2s'};
    sample_type_list = categorical(1:3,1:3, ...
                                   sample_type_strings, ...
                                   'Ordinal',true);

    name_list = { '$\mH2.5\vl\vu\lambda$', ...
                  '$\mH3\vl\vu s_{\vu}\lambda$', ...
                  '$\mH3.5\vl\vu\vv\lambda$', ...                
                  '$\mH4\vl\vu\vv s_{\vv}\lambda$'};
    
    solver_names = categorical([1:numel(name_list)], ...
                               [1:numel(name_list)], ...
                               name_list, 'Ordinal', true);

    solver_list = [ ...
        WRAP.laf1x2_to_qlu(cc) WRAP.laf1x2_to_qlsu(cc) ...
        WRAP.laf2x2_to_qluv(cc) WRAP.laf2x2_to_qlusv(cc) ...
        ];
    
    solver_sample_type =  { 'laf1x2', 'laf1x2', 'laf2x2', 'laf2x2' };

    ex_num = 1;   

    for scene_num = 1:num_scenes
        f = 5*rand(1)+3;
        cam = CAM.make_ccd(f,4.8,nx,ny);
        [P,xborder] = PLANE.make_viewpoint(cam,10,10);
 
        q_norm = -5*rand(1);
        q_gt = q_norm/(sum(2*cc)^2);
        
        cspond_dict = containers.Map;
        for k = 2:3
            X = sample_lafs(sample_type_strings{k},wplane,hplane);
            cspond_dict(sample_type_strings{k}) = X;
        end
        cspond_dict('laf1x2') = cspond_dict('laf2x2');

        for k = 1:numel(solver_list)
            optq_list = nan(1,25);
            opt_rms_list = nan(1,25);
            opt_warp_list = nan(1,25);
            X = cspond_dict(solver_sample_type{k});
            %            solver_variants = {'gb','det'};
            solver_variants = {'det'};
            truth = PLANE.make_gt(scene_num,P,q_gt, ...
                                  cam.cc,0,X);
            X4 = reshape(X,4,[]);
            x = PT.renormI(P*X4);
            xd = CAM.rd_div(reshape(x,3,[]),cam.cc,q_gt);
            xdn = reshape(xd,9,[]);
            
%            figure;
%            plot(xborder(1,:),xborder(2,:),'g-');            
%            LAF.draw(gca,xdn(:,1:2),'Color','b');
%            keyboard;
%            GRID.render(P,X);  
%            
            for k2 = 1:numel(solver_variants)
                try
                    solver_list(k).set_solver(solver_variants{k2});
                    M = solver_list(k).fit(xdn,[1 3;2 4],[1:2]);
                catch err
                    M = [];
                end
                if ~isempty(M)
                    [optq,opt_rms,opt_warp,opt_time] = ...
                        calc_opt_res(truth,cam,M,P,hplane,wplane);
                else
                    disp('solver failure');
                    %                            optq = nan;
                    opt_rms = 1e5;
                    %                            opt_warp = nan;
                end

                res_row = { solver_names(k), ...
                            solver_variants{k2}, ...
                            ex_num, ...
                            optq, opt_rms, opt_warp, opt_time };
%                solver_names(k)
%                opt_time
                res = [res;res_row]; 
            end
        end
        gt_row = ...
            { ex_num, scene_num, q_gt, 0 };
        gt = [gt;gt_row];
        ex_num = ex_num+1;
    end
    disp(['Finished']);
    save('speed','res','gt','cam');
    
function [optq,opt_rms,opt_warp,opt_time] = calc_opt_res(gt,cam,M,P,w,h)    
    t = linspace(-0.5,0.5,10);
    [a,b] = meshgrid(t,t);
    x = transpose([a(:) b(:) ones(numel(a),1)]);
    M1 = [[w 0; 0 h] [0 0]';0 0 1];
    M2 = [1 0 0; 0 1 0; 0 0 0; 0 0 1];
    X = M2*M1*x;

    zu = floor(log2(gt.sU));
    zv = floor(log2(gt.sV));
    
    nthroot(gt.sU,zu);
    
    Hinf = eye(3,3);
    Hinf(3,:) = transpose(gt.l);
    Xu = bsxfun(@plus,X,[gt.U;0]);
    Xv = bsxfun(@plus,X,[gt.V;0]);
    
    x = CAM.rd_div(PT.renormI(P*X),cam.cc,gt.q);
    xu = CAM.rd_div(PT.renormI(P*Xu),cam.cc,gt.q);
    xv = CAM.rd_div(PT.renormI(P*Xv),cam.cc,gt.q);    
      
    if isfield(M,'q1')
        q1 = [M(:).q1];
        q2 = [M(:).q2];
    elseif isfield(M,'q')
        q1 = [M(:).q];
        q2 = q1;
    else
        q1 = zeros(1,numel(M));
        q2 = q1;
    end
    
    rms_list = zeros(1,numel(M));
    for k = 1:numel(M)
        df1 = [];
        df2 = [];
        for k2 = 1:2 
            H = [];
            if k2 == 1
                if isfield(M(k),'u')
                    H = eye(3)+1/gt.sU*M(k).u*M(k).l';
                elseif isfield(M(k),'Hu')
                    H = M(k).Hu^(1/gt.sU);
                end
                if ~isempty(H)
                    xp = CAM.rd_div(PT.renormI(H*CAM.ru_div(...
                        x,cam.cc,q2(k))),cam.cc,q1(k));
                    df1 = xp(1:2,:)-xu(1:2,:);
                end
            else
                if isfield(M(k),'v')
                    H = eye(3)+1/gt.sV*M(k).v*M(k).l';
                    xp = CAM.rd_div(PT.renormI(H*CAM.ru_div(...
                        x,cam.cc,q2(k))),cam.cc,q1(k));
                    df2 = xp(1:2,:)-xv(1:2,:);
                end
            end
        end
        diff = [df1(:);df2(:)];
        if ~isempty(diff)
            rms_list(k) = rms(diff);
        else
            rms_list(k) = nan;
        end
    end
    [opt_rms,best_ind] = min(rms_list);    
    
    mq = mean([q1;q2]);
    optq = mq(best_ind); 

    if isfield(M(best_ind),'l')
        opt_warp = ...
            calc_bmvc16_err(x,gt.l,gt.q,M(best_ind).l,optq,gt.cc);
    else
        opt_warp = nan;
    end
    
    if isfield(M(best_ind),'solver_time')
        opt_time = M(best_ind).solver_time;
    else
        keyboard;
    end
    
function X = sample_lafs(sample_type,w,h)
    switch sample_type
      case {'laf1x2','laf2x2'}
        X = PLANE.make_cspond_t(2,w,h);
      case 'laf2x2s'
        X = PLANE.make_cspond_same_t(2,w,h);
    end
