function m = melfb(p, n, fs)
% MELFB Compute a Mel-spaced triangular filterbank matrix.
%
% Inputs:
%   p  : Number of triangular filters in the filterbank
%   n  : FFT length
%   fs : Sampling frequency in Hz
%
% Output:
%   m  : Sparse matrix of size [p, 1 + floor(n/2)]

    f0  = 700 / fs;
    fn2 = floor(n / 2);
    lr  = log(1 + 0.5 / f0) / (p + 1);

    % Convert Mel boundary frequencies to FFT bin numbers
    bl = n * (f0 * (exp([0, 1, p, p + 1] * lr) - 1));

    b1 = floor(bl(1)) + 1;
    b2 = ceil(bl(2));
    b3 = floor(bl(3));
    b4 = min(fn2, ceil(bl(4))) - 1;

    pf = log(1 + (b1:b4) / n / f0) / lr;
    fp = floor(pf);
    pm = pf - fp;

    r = [fp(b2:b4), 1 + fp(1:b3)];
    c = [b2:b4, 1:b3] + 1;
    v = 2 * [1 - pm(b2:b4), pm(1:b3)];

    m = sparse(r, c, v, p, 1 + fn2);
end
