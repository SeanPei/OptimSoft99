function hessian=strainenergyhessian(dx)
    global nodes elements vmaterials fix_transform jacobi0_inv shape_jacobi fix
    x = nodes+fix_transform*dx;
    hessian = zeros(size(nodes,1),size(nodes,1));
    jacobi = computejacobi(x,elements);
    deform_grad = cellfun(@(J,J0inv) J*J0inv,jacobi,jacobi0_inv,'UniformOutput',false);
    for i=1:size(deform_grad,2)
        F=deform_grad{i}; C=F'*F; J=det(F); I1=trace(C); I3=J*J;
        I1bar=I1/nthroot(I3,3);
        IF = zeros(9,9);
        for j = 1:3
            for k = 1:3
                I = zeros(3); I(j,k) = 1;
                IF(j*3-2:j*3,k*3-2:k*3) = I;
            end
        end
        dJdF=J*inv(F)'; dI1dF = 2*F; dI1dFdF = 2*IF;
        dI1bardF = -2*I1bar*dJdF/(3.0*J)+dI1dF/nthroot(I3,3);
        FinvT = inv(F)'; dJdFdF=kron(FinvT,FinvT);
        for j=1:3
            for k=1:3
                dJdFdF(j*3-2:j*3,k*3-2:k*3) = dJdFdF(j*3-2:j*3,k*3-2:k*3)-...
                    FinvT*IF(k*3-2:k*3,j*3-2:j*3)*FinvT;
            end
        end
        dJdFdF = J*dJdFdF; dJFkrondJF = kron(dJdF,dJdF);
        dI1barFkrondJF = kron(dI1bardF,dJdF);
        dJFkrondI1F = kron(dJdF,dI1dF);
        dPdF = zeros(9,9);
        dI1bardFdF = 2/(3.0*I3)*I1bar*dJFkrondJF-2/(3.0*J)*...
            dI1barFkrondJF-2/(3*J)*I1bar*dJdFdF-2/(3.0*nthroot(J^5, 3))*...
            dJFkrondI1F+1/nthroot(J^2,3)*dI1dFdF;
        dPdF = dPdF+vmaterials{i}(1)*dI1bardFdF;
        volume_dPdF = dJFkrondJF+(J - 1)*dJdFdF;
        volume_dPdF = 2*vmaterials{i}(2)*volume_dPdF;
        dPdF = dPdF+volume_dPdF;
        
        H = zeros(12);
        for j = 1:3
            H_part = zeros(12,4);
            for k = 1:3
                IJ = dPdF(j*3-2:j*3,k*3-2:k*3)*shape_jacobi{i}';
                H_part = H_part+IJ(:)*shape_jacobi{i}(:,k)';
            end
            H(:,[j,j+3,j+6,j+9]) = H(:,[j,j+3,j+6,j+9])+H_part;
        end
        [V,D] = eig(H); V=real(V); D=real(D); D(D<1e-6) = 1e-6; H=V*D*V';
        index = reshape([elements(:,i),elements(:,i)+1,elements(:,i)+2]',1,12);
        hessian(index,index) = hessian(index,index)+H;
    end
    hessian([fix,fix+1,fix+2],:) = []; hessian(:,[fix,fix+1,fix+2]) = [];
end
%% compute jacobi matrix
function J = computejacobi(x,element)
    global shape_grad
    x1 = x([element(1,:);element(1,:)+ 1;element(1,:)+ 2]);
    x2 = x([element(2,:);element(2,:)+ 1;element(2,:)+ 2]);
    x3 = x([element(3,:);element(3,:)+ 1;element(3,:)+ 2]);
    x4 = x([element(4,:);element(4,:)+ 1;element(4,:)+ 2]);
    J = [x1(:),x2(:),x3(:),x4(:)]*shape_grad;
    J = mat2cell(J,3*ones(1,size(J,1)/3),3)';
end