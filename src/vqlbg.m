function r = vqlbg(d, k)
% VQLBG Vector Quantization codebook training using the Linde-Buzo-Gray (LBG) algorithm.
%
% Inputs:
%   d : Feature matrix (D x N), where each column is a training feature vector
%   k : Target number of codebook centroids (power of 2, e.g., 16 or 64)
%
% Output:
%   r : Trained VQ codebook matrix (D x k)

    e = 0.01;                   % Splitting & convergence threshold
    max_iter = 100;             % Safety cap per splitting stage
    r = mean(d, 2);             % Initial centroid (mean of all training vectors)

    for i = 1:log2(k)
        % Binary split of existing centroids
        r = [r * (1 - e), r * (1 + e)];

        dpr = 1e12;             % Previous iteration distortion
        for iter = 1:max_iter
            z = disteu(d, r);
            [m, ind] = min(z, [], 2);
            D = mean(m);

            % Update each centroid using assigned vectors (guard empty clusters)
            for j = 1:size(r, 2)
                assigned = (ind == j);
                if any(assigned)
                    r(:, j) = mean(d(:, assigned), 2);
                end
            end

            % Check relative distortion improvement
            if abs(dpr - D) / (D + eps) < e
                break;
            end
            dpr = D;
        end
    end
end
