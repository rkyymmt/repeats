%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
classdef PatternPrinter < handle
    properties    
        x = [];
        
        q0 = [];
        A0 = [];
        l0 = [];
        X0 = [];
        Rtij0 = [];
        
        rtree = [];
        Tlist = [];
        Gm = [];
        inverted = [];
        
        cc = [];
        
        M = [];
        
        params = [];
        dz0 = [];
        
        num_Rt_params = [];
        motion_model = 'Rt';
    end
    
    methods(Static)
        function err = errfun(dz,mle_impl)
            [q,Hinf,X,Rtij] = mle_impl.unpack(dz);            
            [Gs,Rti] = composite_xforms(mle_impl.Tlist, ...
                                        mle_impl.Gm,mle_impl.inverted, ...
                                        Rtij,X,size(mle_impl.x,2));
            [Xp,inl] = sfm(X,Gs,Rti);
            Hinv = inv(Hinf);
            xp = PT.renormI(Hinv*reshape(Xp,3,[]));
            xpd = CAM.rd_div(xp,mle_impl.cc,q/sum(2*mle_impl.cc)^2);
            x = reshape(mle_impl.x(:,inl),3,[]);
            err = reshape(xpd(1:2,:)-x(1:2,:),[],1);
%            C = 4;
%            err = sqrt(C^2*2*(sqrt(1+(err/C).^2)-1));
        end
    end

    methods(Access = public)
        function this = PatternPrinter(cc,x,rtree,Gs,Tlist, ...
                                       Gm,is_inverted, ...
                                       q,A0,l0,X,Rtij,varargin)
            this = cmp_argparse(this,varargin{:});
            
            this.rtree = rtree;
            this.Tlist = Tlist;

%            this.Gm = sparse(rtree.Edges.EndNodes(:,1), ...
%                             rtree.Edges.EndNodes(:,2), ...
%                             Gm);
%            this.inverted = sparse(rtree.Edges.EndNodes(:,1), ...
%                                   rtree.Edges.EndNodes(:,2), ...
%                                   is_inverted); 

            this.Gm = zeros(max(rtree.Edges.EndNodes(:,1)), ...
                            max(rtree.Edges.EndNodes(:,2)));
            this.inverted = this.Gm;
            this.Gm(sub2ind(size(this.Gm),...
                            rtree.Edges.EndNodes(:,1), ...
                            rtree.Edges.EndNodes(:,2))) = Gm;
            this.inverted(sub2ind(size(this.inverted),...
                                  rtree.Edges.EndNodes(:,1), ...
                                  rtree.Edges.EndNodes(:,2))) = is_inverted;
            
            this.cc = reshape(cc,2,[]);
            this.x = x;
            this.Tlist = Tlist;
            
            this.pack(q,A0,l0,X,Rtij);
        end
        
        function [] = pack(this,q,A0,l0,X,Rtij)
            this.q0 = q*sum(2*this.cc)^2;
            if A0(2,1) == 0
                this.A0 = [1 0 A0(4)/A0(1) A0(5)/A0(1)];
            else
                this.A0 = reshape(A0(1:2,1:2),1,[]);
            end
            this.l0 = l0;
            this.X0 = X;
            this.Rtij0 = Rtij;
            q_idx = 1;
            switch this.motion_model
              case 't'
                H_idx = [1:3]+q_idx(end);
                X_idx = [1:6*size(X,2)]+H_idx(end);
                Rtij_idx = ...
                    [1:2*size(Rtij,2)]+X_idx(end);
                this.num_Rt_params = 2;
              case 'Rt'
                H_idx = [1:4]+q_idx(end);
                X_idx = [1:6*size(X,2)]+H_idx(end);
                Rtij_idx = ...
                    [1:3*size(Rtij,3)]+X_idx(end);
                this.num_Rt_params = 3;
            end
            this.params =  struct('q', q_idx,'H', H_idx, ...
                                  'X', X_idx, 'Rtij', Rtij_idx);
            this.dz0 = zeros(this.params.Rtij(end),1);
        end
        
        function [q,Hinf,X,Rtij,A,l] = unpack(this,dz)
            dq = dz(this.params.q);
            
            dH = dz(this.params.H);
            dX = zeros(9,size(this.X0,2));
            dX([1 2 4 5 7 8],:) = reshape(dz(this.params.X),6,[]);
            dRtij = reshape(dz(this.params.Rtij),this.num_Rt_params,[]);
 
            q = this.q0+dq;
            X = this.X0+dX;
            Rtij = this.Rtij0;
            A = eye(3);
            l = zeros(3,1);
            if numel(dH) == 3
                l = this.l0+dH(1:3);
                Rtij(2:3,:) = Rtij(2:3,:)+dRtij; 
            elseif numel(dH) == 4
                %                if this.A0(2) == 0
                    A(1,1) = this.A0(1);
                    A(2,1) = this.A0(2);
                    A(1,2) = this.A0(3)+dH(1);
                    A(2,2) = this.A0(4)+dH(2);
                    l = this.l0+[dH(3:4);0];
%                else
%                    A(1,1) = this.A0(1)+dH(1);
%                    A(2,1) = this.A0(2)+dH(2);
%                    A(1,2) = this.A0(3)+dH(3);
%                    A(2,2) = this.A0(4)+dH(4);
%                    l(1:2) =  transpose([A(1,1) A(1,2)]);
%                    l(3) = -det(A(1:2,1:2));
%                end
                Rtij2 = multiprod(this.Rtij0,Rt.params_to_mtx(dRtij));
            end
            Hinf = A;
            Hinf(3,:) = transpose(l);
        end
        
        function Jpat = make_Jpat(this)
            [Gs,Rti] = composite_xforms(this.Tlist, ...
                                        this.Gm,this.inverted, ...
                                        this.Rtij0,this.X0,size(this.x,2));
            [Xp,inl] = sfm(this.X0,Gs,Rti);
            Gs = Gs(inl);
            
            active_vertices = unique(this.rtree.Edges.EndNodes);
            m = 6*numel(active_vertices);
            n = this.params.Rtij(end);

            [dq_ii dq_jj] = meshgrid(1:m,this.params.q);
            [dH_ii dH_jj] = meshgrid(1:m,this.params.H);
            dG_ii = [];dG_jj = [];

            for k = 1:numel(Gs)
                [aa,bb] = meshgrid(6*(k-1)+transpose([1:2]), ...
                                   6*(Gs(k)-1)'+transpose([1:2])+this.params.H(end));
                [cc,dd] = meshgrid(6*(k-1)+transpose([3:4]), ...
                                   6*(Gs(k)-1)'+transpose([3:4])+ ...
                                   this.params.H(end));
                [ee,ff] = meshgrid(6*(k-1)+transpose([5:6]), ...
                                   6*(Gs(k)-1)'+transpose([5:6])+ ...
                                   this.params.H(end));                
                dG_ii = cat(1,dG_ii,aa(:),cc(:),ee(:));
                dG_jj = cat(1,dG_jj,bb(:),dd(:),ff(:));
            end
            
            dRti_dj_ii = [];
            dRti_dj_jj = [];
            
            for k = 1:numel(this.Tlist)
                T = this.Tlist{k};
                TR  = shortestpathtree(this.rtree,T(1), ...
                                       'OutputForm','cell');
                keyboard;
                idx = find(~cellfun('isempty',TR));
                TR = TR(idx); 
                [~,Locb] = ismember(idx,inl);
                Locb = reshape(nonzeros(Locb),1,[]);
                for k2 = 1:numel(Locb)
                    tr = TR{k2};
                    gm = this.Gm(sub2ind(size(this.Gm),tr(1:end-1),tr(2:end)));
                    [aa,bb] = meshgrid(6*(Locb(k2)-1)+transpose([1:6]), ...
                                       this.num_Rt_params*(gm-1)+...
                                       transpose(1:this.num_Rt_params)+...
                                       this.params.X(end));
                    dRti_dj_ii = cat(1,dRti_dj_ii,aa(:));
                    dRti_dj_jj = cat(1,dRti_dj_jj,bb(:));
                end
            end
            v = ones(numel([dq_ii(:); dH_ii(:); dG_ii;dRti_dj_ii]),1);
            Jpat = ...
                sparse([dq_ii(:); dH_ii(:); dG_ii;dRti_dj_ii], ...
                       [dq_jj(:); dH_jj(:); dG_jj;dRti_dj_jj], ...
                       v,m,n);
        end
            
        function err = calc_err(this,dz)
            if nargin < 2
                dz = this.dz0;
            end
            err = PatternPrinter.errfun(dz,this);
        end 
                
        function [M,stats] = fit(this,varargin)
            err0 = this.errfun(this.dz0,this);
            Jpat = this.make_Jpat();
            
            %            lb = -6/(2*sum(this.cc))^2;
            lb=-6;
            if numel(this.dz0) <= numel(err0)
                lb = transpose([lb -inf(1,numel(this.dz0)-1)]);
                ub = transpose([0 inf(1,numel(this.dz0)-1)]);
                options = optimoptions(@lsqnonlin, ...
                                       'Algorithm', 'trust-region-reflective', ...
                                       'Display','none', ...
                                       'JacobPattern', Jpat, ...
                                       'Display', 'iter', ...
                                       varargin{:});

                %%                
%                options = optimoptions(@lsqnonlin, ...
%                                       'Algorithm', 'trust-region-reflective', ...
%                                       'Display','none', ...
%                                       'Display', 'iter', ...
%                                       varargin{:});
                [dz,resnorm,err] = lsqnonlin(@(dz) PatternPrinter.errfun(dz,this), ...
                                              this.dz0,lb,ub, ...
                                              options);
            else
                dz = this.dz0;
                err = err0;
                resnorm = sum(err.^2);
            end

            [q,~,X,Rtij,A,l] = this.unpack(dz);

            [Gs,Rti,Gm] = composite_xforms(this.Tlist, ...
                                           this.Gm,this.inverted, ...
                                           Rtij,X,size(this.x,2)); 
            [Xp,inl] = sfm(X,Gs,Rti);
            
            M = struct('q',q/sum(2*this.cc)^2, ...
                       'cc', this.cc, ...
                       'A',A,'l',l,'X',X, ...
                       'Rti', Rti,'Gs',Gs, ...
                       'Gm',Gm);
            
            stats = struct('dz', dz, ...
                           'resnorm', resnorm, ...
                           'err', err, ...
                           'err0', err0, ...
                           'sqerr0', sum(reshape(err0,6,[]).^2), ...
                           'sqerr', sum(reshape(err,6,[]).^2));            
        end
    end
end
