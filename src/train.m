function code = train(traindir, n, window_type)
% TRAIN Train VQ speaker codebooks from training WAV files (s1.wav .. sn.wav).
%
% Inputs:
%   traindir    : Directory containing training WAV files
%   n           : Number of speakers to enroll
%   window_type : Window function handle (default: @hamming)
%
% Output:
%   code        : 1 x n cell array of VQ codebooks

    if nargin < 3 || isempty(window_type)
        window_type = @hamming;
    end

    k = 64;                     % Codebook size (number of LBG centroids)
    code = cell(1, n);

    for i = 1:n
        file = fullfile(traindir, sprintf('s%d.wav', i));
        [s, fs] = audioread(file);
        if size(s, 2) > 1
            s = mean(s, 2);
        end
        s = s / (sqrt(mean(s.^2)) + eps);

        v = mfcc(s, fs, window_type);
        code{i} = vqlbg(v, k);
    end
end
