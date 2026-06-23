% Implement of the standard l-bfgs algorithm.
function [x1,f1,g1,k] = L_BFGS(myFx, x0, hessian, maxIter, m)
    gradToler = 1e-5; % tolerance for the norm of the slope
    n = length(x0); S = zeros(n, m); Y = zeros(n, m); YS = zeros(m);
    % If hessian is empty, the scaled identity matrix is used as the initial
    % guess of Hessian matrix
    % If hessian is a function handle, the initial guess of Hessian matrix
    % is calculated by this function in each iteration steps.
    % If hessian is a matrix, the input hessian matrix is used as the
    % initial guess of Hessian matrix in every iteration steps;
    if isempty(hessian)
        prehessian = 0;
        invhessian = [];
    elseif isa(hessian, 'function_handle')
        prehessian = 1;
        invhessian = inv(hessian(x0));
    else
        prehessian = 2;
        invhessian = inv(hessian);
    end
    [f0, g0] = feval(myFx, x0);
    if norm(g0, inf) < gradToler
        x1 = x0; f1 = f0; g1 = g0; k = 0;
        disp('alread minimum');
        return
    end
    if prehessian > 0
        drt = -invhessian * g0;
    else
        drt = -g0;
    end
    fprintf('%6s %12s %18s\n', 'iter', 'fval', 'norm(g,inf)');
    k = 1;
    while true
        [x1, f1, g1] = linesearch(myFx, drt, x0, f0, g0);
        gnorm = norm(g1, inf);
        if mod(k, 20) == 0
            fprintf('%6s %12s %18s\n', 'iter', 'fval', 'norm(g,inf)');
        end
        fprintf('%5d %15.4e %15.4e\n', k, f1, gnorm);
        if gnorm < gradToler
            break;
        end
        if maxIter > 0 && k > maxIter
            break;
        end
        s0 = x1 - x0; y0 = g1 - g0; ys = y0' * s0;
        if (k <= m)
            S(:, k) = s0; Y(:, k) = y0; YS(k) = ys;
            drt = getHg_lbfgs(g1,S(:,1:k),Y(:,1:k),YS(:,1:k),prehessian,invhessian);
        elseif (k > m)
            S(:,1:(m-1)) = S(:,2:m); Y(:,1:(m-1)) = Y(:,2:m);
            YS(1:(m-1)) = YS(2:m); S(:,m) = s0;
            Y(:,m) = y0; YS(m) = ys;
            drt = getHg_lbfgs(g1,S,Y,YS,prehessian,invhessian);
        end
        x0 = x1; g0 = g1; f0 = f1; k = k + 1;
        if prehessian == 1
            invhessian = inv(hessian(x0));
        end
    end
end

function Hg = getHg_lbfgs(g,S,Y,YS,prehessian,invhessian)
    [~,k] = size(S); alpha = zeros(k,1); beta = zeros(k,1); q = -g;
    % first loop
    for i = k:-1:1
        alpha(i) = S(:,i)'*q/YS(i);
        q = q-alpha(i)*Y(:,i);
    end
    % Multiply by Initial Hessian
    if prehessian > 0
        r = invhessian*q;
    else
        r = YS(k)/(Y(:,k)'*Y(:,k))*q;
    end
    % second loop
    for i = 1:k
        beta(i) = Y(:,i)'*r/YS(i);
        r = r+S(:,i)*(alpha(i)-beta(i));
    end
    Hg = r;
end

function [x1,f1,g1] = linesearch(myFx,drt,x0,f0,g0)
    dec = 0.4; inc = 2.5; ftol = 1e-4; wolfe = 0.9; max_linesearch = 20;
    alg = 1; % 1:ARMIJO, 2: WOLFE, 3: STRONG_WOLFE
    % Projection of gradient on the search direction
    dg0 = g0'*drt;
    % Make sure d points to a descent direction
    if dg0 > 0
        disp("the moving direction increases the objective function value");
    end
    test_decr = ftol * dg0; step = 1;
    for iter = 1:max_linesearch
        x1 = x0+step*drt; [f1,g1] = myFx(x1);
        if f1 > f0+step*test_decr
            width = dec;
        else
            if alg == 1 % Armijo condition is met
                break;
            end
            dg = g1'*drt;
            if dg < wolfe*dg0
                width = inc;
            else
                if alg == 2 % Regular Wolfe condition is met
                    break;
                end
                if dg > -wolfe*dg0
                    width = dec;
                else % Strong Wolfe condition is met
                    break;
                end
            end
        end
        step = step*width;
    end
end
