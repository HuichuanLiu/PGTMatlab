function model = origin_gmm(X, K_or_centroids)  
% ============================================================  
% Expectation-Maximization iteration implementation of  
% Gaussian Mixture Model.  
%  
% PX = GMM(X, K_OR_CENTROIDS)  
% [PX MODEL] = GMM(X, K_OR_CENTROIDS)  
%  
%  - X: N-by-D data matrix.  
%  - K_OR_CENTROIDS: either K indicating the number of  
%       components or a K-by-D matrix indicating the  
%       choosing of the initial K centroids.  
%  
%  - PX: N-by-K matrix indicating the probability of each  
%       component generating each point.  
%  - MODEL: a structure containing the parameters for a GMM:  
%       MODEL.Miu: a K-by-D matrix.  
%       MODEL.Sigma: a D-by-D-by-K matrix.  
%       MODEL.Pi: a 1-by-K vector.  
% ============================================================  
% @SourceCode Author: Pluskid (http://blog.pluskid.org)  
% @Appended by : Sophia_qing (http://blog.csdn.net/abcjennifer)  
      
  
%% Generate Initial Centroids  
    threshold = 1e-15;  
    [N, D] = size(X);  
   
    if isscalar(K_or_centroids) %if K_or_centroid is a 1*1 number  
        K = K_or_centroids;  
        Rn_index = randperm(N); %random index N samples  
        centroids = X(Rn_index(1:K), :); %generate K random centroid  
    else % K_or_centroid is a initial K centroid  
        K = size(K_or_centroids, 1);   
        centroids = K_or_centroids;  
    end  
   
    %% initial values  
    [pMiu pPi pSigma] = init_params();  
   
    Lprev = -inf; %????????  

    %% EM Algorithm 
    Ls = zeros(1200);
    p = 1;
    while p<=1000  
        %% Estimation Step  
        Px = calc_prob();  
   
        % new value for pGamma(N*k), pGamma(i,k) = Xi??k?Gaussian?????  
        % ???xi??pGamma(i,k)???k?Gaussian???  
        pGamma = Px .* repmat(pPi, N, 1); %?? = pi(k) * N(xi | pMiu(k), pSigma(k))  
        pGamma = pGamma ./ repmat(sum(pGamma, 2), 1, K); %?? = pi(j) * N(xi | pMiu(j), pSigma(j))???j??  
   
        %% Maximization Step - through Maximize likelihood Estimation  
          
        Nk = sum(pGamma, 1); %Nk(1*k) = ?k?????????????????Nk????N?  
          
        % update pMiu  
        pMiu = diag(1./Nk) * pGamma' * X; %update pMiu through MLE(????? = 0??)  
        pPi = Nk/N;  
          
        % update k? pSigma  
        for kk = 1:K   
            Xshift = X-repmat(pMiu(kk, :), N, 1);  
            pSigma(:, :, kk) = (Xshift' * ...  
                (diag(pGamma(:, kk)) * Xshift)) / Nk(kk);  
        end  
   
        % check for convergence  
%         L = sum(log(Px*pPi'));  
%         if L-Lprev < threshold  
%             break;  
%         end  
%         Lprev = L;
        Ls(p)=sum(log(Px*pPi'));
        p = p+1;
    end  
    
        model = [];  
        model.u = pMiu;  
        model.pSigma = pSigma;  
        model.a = pPi;   
   
    %% Function Definition  
      
    function [pMiu pPi pSigma] = init_params()  
        pMiu = centroids; %k*D, ?k?????  
        pPi = zeros(1, K); %k?GMM?????influence factor?  
        pSigma = zeros(D, D, K); %k?GMM??????????D*D?  
   
        % ???????N*K????x-pMiu?^2 = x^2+pMiu^2-2*x*Miu  
        distmat = repmat(sum(X.*X, 2), 1, K) + ... %x^2, N*1???replicateK?  
            repmat(sum(pMiu.*pMiu, 2)', N, 1) - ...%pMiu^2?1*K???replicateN?  
            2*X*pMiu';  
        [~, labels] = min(distmat, [], 2);%Return the minimum from each row  
   
        for k=1:K  
            Xk = X(labels == k, :);  
            pPi(k) = size(Xk, 1)/N;  
            pSigma(:, :, k) = cov(Xk);  
        end  
    end  
   
    function Px = calc_prob()   
        %Gaussian posterior probability   
        %N(x|pMiu,pSigma) = 1/((2pi)^(D/2))*(1/(abs(sigma))^0.5)*exp(-1/2*(x-pMiu)'pSigma^(-1)*(x-pMiu))  
        Px = zeros(N, K);  
        for k = 1:K  
            Xshift = X-repmat(pMiu(k, :), N, 1); %X-pMiu  
            inv_pSigma = inv(pSigma(:, :, k));  
            tmp = sum((Xshift*inv_pSigma) .* Xshift, 2);  
            coef = (2*pi)^(-D/2) * sqrt(det(inv_pSigma));  
            Px(:, k) = coef * exp(-0.5*tmp);  
        end  
    end  
end  