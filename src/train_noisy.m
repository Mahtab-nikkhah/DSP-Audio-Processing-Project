function code = train_noisy(traindir, n, snr_db, window_type)
% TRAIN_NOISY Train VQ speaker codebooks with Additive White Gaussian Noise (AWGN).
%
% Inputs:
%   traindir    : Directory containing training WAV files
%   n           : Number of speakers to enroll
%   snr_db      : Target signal-to-noise ratio in dB
%   window_type : Window function handle (default: @hamming)
%
% Output:
%   code        : 1 x n cell array of VQ codebooks trained on noisy audio

    if nargin < 4 || isempty(window_type)
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

        % Pure-MATLAB AWGN injection at exact measured signal power
        sig_power   = mean(s.^2);
        noise_power = sig_power / (10^(snr_db / 10));
        s_noisy     = s + sqrt(noise_power) * randn(size(s));

        v = mfcc(s_noisy, fs, window_type);
        code{i} = vqlbg(v, k);
    end
end
