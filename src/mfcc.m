function c = mfcc(s, fs, window_type)
% MFCC Extract Mel-Frequency Cepstral Coefficients from a speech signal.
%
% Inputs:
%   s           : Input speech signal (mono or stereo)
%   fs          : Sampling frequency in Hz
%   window_type : Window function handle (@hamming or @hann), default: @hamming
%
% Output:
%   c           : 12 x numFrames matrix of MFCC feature vectors (excluding c0)

    if nargin < 3 || isempty(window_type)
        window_type = @hamming;
    end

    % Convert stereo to mono column vector
    if size(s, 2) > 1
        s = mean(s, 2);
    end
    s = s(:);

    % Pre-emphasis filter
    s = filter([1, -0.9375], 1, s);

    % Frame blocking: 25 ms frames with 50% overlap, power-of-2 FFT size
    frame_len = round(0.025 * fs);
    nfft      = 2^nextpow2(frame_len);
    inc       = floor(frame_len / 2);

    if length(s) < frame_len
        s = [s; zeros(frame_len - length(s), 1)];
    end
    nf = floor((length(s) - frame_len) / inc) + 1;

    indf = inc * (0:(nf - 1));
    inds = (1:frame_len)';
    frames = s(indf(ones(frame_len, 1), :) + inds(:, ones(1, nf)));

    % Windowing (works with or without Signal Processing Toolbox)
    win_name = lower(func2str(window_type));
    n_idx = (0:frame_len-1)';
    if strcmp(win_name, 'hamming')
        w = 0.54 - 0.46 * cos(2 * pi * n_idx / (frame_len - 1));
    elseif strcmp(win_name, 'hann') || strcmp(win_name, 'hanning')
        w = 0.5 * (1 - cos(2 * pi * n_idx / (frame_len - 1)));
    else
        w = feval(window_type, frame_len);
    end
    frames = frames .* w(:, ones(1, nf));

    % Power spectrum (one-sided)
    spec = abs(fft(frames, nfft)).^2;
    spec = spec(1:(floor(nfft / 2) + 1), :);

    % 20-channel Mel-spaced filterbank
    n_filters = 20;
    bank = full(melfb(n_filters, nfft, fs));
    bank = bank / (max(bank(:)) + eps);

    mel_energy = max(bank * spec, 1e-12);

    % Type-II DCT (coefficients c1..c12)
    n_ceps = 12;
    n_vec = 0:(n_filters - 1);
    dct_mat = zeros(n_ceps, n_filters);
    for k = 1:n_ceps
        dct_mat(k, :) = cos((2 * n_vec + 1) * k * pi / (2 * n_filters));
    end

    c = dct_mat * log(mel_energy);
end
