function d = disteu(x, y)
% DISTEU Pairwise Euclidean distances between columns of two matrices.
%
% Inputs:
%   x, y : Feature matrices whose columns are feature vectors (D x N, D x P)
%
% Output:
%   d    : N x P matrix where d(i, j) = ||x(:, i) - y(:, j)||_2

    [M, N]  = size(x);
    [M2, P] = size(y);

    if M ~= M2
        error('Matrix feature dimensions do not match (%d vs %d).', M, M2);
    end

    d = zeros(N, P);
    if N < P
        copies = zeros(1, P);
        for n = 1:N
            d(n, :) = sum((x(:, n + copies) - y).^2, 1);
        end
    else
        copies = zeros(1, N);
        for p = 1:P
            d(:, p) = sum((x - y(:, p + copies)).^2, 1)';
        end
    end

    d = sqrt(max(d, 0));
end
