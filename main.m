clear; clc;
global nodes elements vmaterials act_value act_con fix_transform I...
    shape_grad volume jacobi0 jacobi0_inv shape_jacobi fix gravity
%% initial
load('sample/cable_finger.mat');
shape_grad = eye(4,3); shape_grad(4,:) = -1;
jacobi0 = computejacobi(nodes,elements);
volume = cellfun(@(J) abs(det(J))/6,jacobi0,'UniformOutput',false);
jacobi0_inv = cellfun(@(J) inv(J),jacobi0,'UniformOutput',false);
shape_jacobi = cellfun(@(J0_inv) shape_grad*J0_inv,jacobi0_inv,...
    'UniformOutput',false);
vmaterials = cellfun(@(m,v) [m(1);1/m(2)]*v,mat2cell(materials,3,...
    ones(1,size(volume,2))),volume,'UniformOutput',false);
%% initial hessian matrix
I = cell(3,3);
for i = 1:9
    I{i} = zeros(3); I{i}(i) = 1;
end
hessian = zeros(size(nodes,1),size(nodes,1));
gravity = zeros(size(nodes,1),1); eg = [g;g;g;g];
for m = 1:size(elements,2)
    H = zeros(12); M = 0.25*materials(3,m)*volume{m}*eye(12);
    for i = 1:3
        H_part = zeros(12,4);
        for j = 1:3
            IJ = I{i,j}*shape_jacobi{m}';
            H_part = H_part+IJ(:)*shape_jacobi{m}(:,j)';
        end
        H(:,[i,i+3,i+6,i+9]) = H(:,[i,i+3,i+6,i+9])+H_part;
    end
    index = reshape([elements(:,m),elements(:,m)+1,elements(:,m)+2]',1,12);
    hessian(index,index) = hessian(index,index)+2*(4/3*vmaterials{m}(1)+...
        vmaterials{m}(2))*H;
    gravity(index)=gravity(index)+M*eg;
end
hessian([fix,fix+1,fix+2],:) = []; hessian(:,[fix,fix+1,fix+2]) = [];
fix_transform = eye(size(nodes,1)); fix_transform(:,[fix,fix+1,fix+2]) = [];
%% simulation
dx = zeros(size(nodes,1)-3*size(fix,1),1);
[dx,e,gradient,k] = L_BFGS(@objective,dx,hessian,0,6);
%% visualization
figure; hold on; axis equal; view(45,45);
[F,P] = freeBoundary(triangulation(((elements+2)./3)',...
    reshape(nodes,3,size(nodes,1)/3)'));
trisurf(F,P(:,1),P(:,2),P(:,3),'FaceColor',[0.85 0.85 0.85],'FaceAlpha',0.8);
[F,P] = freeBoundary(triangulation(((elements+2)./3)',...
    reshape(nodes+fix_transform*dx,3,size(nodes,1)/3)'));
trisurf(F,P(:,1),P(:,2),P(:,3),'FaceColor',[0.85 0.85 1],'FaceAlpha',1);
%% objective function
function [e, grad] = objective(dx)
    global nodes elements vmaterials act_value act_con fix_transform...
        jacobi0_inv shape_jacobi gravity
    tdx=fix_transform*dx; x = nodes+tdx;
    jacobi = computejacobi(x,elements);
    deform_grad = cellfun(@(J,J0inv) J*J0inv,jacobi,jacobi0_inv,...
        'UniformOutput',false);
    e = sum(cell2mat(cellfun(@(F,vm) vm(1)*(trace(F'*F)/(det(F'*F)^(1/3))-...
        3)+vm(2)*(det(F)-1)^2,deform_grad,vmaterials,'UniformOutput',false)));
    g_e = cellfun(@(F,T,vm) (vm(1)*2/(det(F'*F)^(1/3))*(-trace(F'*F)*...
        inv(F)'/3+F)+2*vm(2)*(det(F)-1)*det(F)*inv(F)')*T',deform_grad,...
        shape_jacobi,vmaterials,'UniformOutput',false);
    g_raw = -gravity;
    for i = 1:size(elements,2)
        index = [elements(:,i),elements(:,i)+1,elements(:,i)+2]';
        g_raw(index(:)) = g_raw(index(:))+g_e{i}(:);
    end
    if size(act_con,1) == 3 % pneumatic
        x1 = x([act_con(1,:);act_con(1,:)+1;act_con(1,:)+2]);
        x2 = x([act_con(2,:);act_con(2,:)+1;act_con(2,:)+2]);
        x3 = x([act_con(3,:);act_con(3,:)+1;act_con(3,:)+2]);
        actx = [x1;x2;x3];
        actg = cross(actx(7:9,:)-actx(1:3,:),actx(4:6,:)-actx(1:3,:))./6;
        acte = sum(act_value*dot(actg,x1)');
        actg = bsxfun(@times,act_value,[actg;actg;actg]);
    elseif size(act_con,1) == 2 % cable
        x1 = x([act_con(1,:);act_con(1,:)+1;act_con(1,:)+2]);
        x2 = x([act_con(2,:);act_con(2,:)+1;act_con(2,:)+2]);
        actx = x2-x1;
        acte = sqrt(sum(actx.^2));
        actg = actx./acte;
        actg = bsxfun(@times,act_value,[actg;-actg]);
        acte = -sum(act_value*acte');
    end
    e = e-acte-gravity'*tdx;
    for i = 1:size(act_con,2)
        index = [act_con(:,i),act_con(:,i)+1,act_con(:,i)+2]';
        g_raw(index(:)) = g_raw(index(:))-actg(:,i);
    end
    grad = fix_transform'*g_raw;
end
function J = computejacobi(x,element)
    global shape_grad
    x1 = x([element(1,:);element(1,:)+ 1;element(1,:)+ 2]);
    x2 = x([element(2,:);element(2,:)+ 1;element(2,:)+ 2]);
    x3 = x([element(3,:);element(3,:)+ 1;element(3,:)+ 2]);
    x4 = x([element(4,:);element(4,:)+ 1;element(4,:)+ 2]);
    J = [x1(:),x2(:),x3(:),x4(:)]*shape_grad;
    J = mat2cell(J,3*ones(1,size(J,1)/3),3)';
end