function y = phaseVocoder(x, M, win, hop, alpha)
% PHASEVOCODER Classical STFT Phase Vocoder for pitch-preserving time-stretching.
%
% Inputs:
%   x     : Input audio signal (mono or stereo; stereo is averaged to mono)
%   M     : FFT / frame size (e.g., 1024)
%   win   : Analysis/synthesis window column vector of length M (e.g., hann(M))
%   hop   : Analysis hop size in samples (e.g., M / 4)
%   alpha : Time-stretching factor (alpha > 1 slows down; alpha < 1 speeds up)
%
% Output:
%   y     : Time-stretched output signal (peak-safe, overlap-add normalized)

    % Convert to mono column vector
    if size(x, 2) > 1
        x = mean(x, 2);
    end
    x = x(:);
    win = win(:);

    % Synthesis hop size
    synHop = max(1, round(alpha * hop));

    % Number of analysis frames
    L = length(x);
    numFrames = floor((L - M) / hop) + 1;
    if numFrames < 1
        error('Input signal is shorter than FFT size M.');
    end

    % Zero-pad input to safely index all frames
    x = [x; zeros(M, 1)];

    % Preallocate output and overlap-add window normalization buffer
    outLen = (numFrames - 1) * synHop + M;
    y = zeros(outLen, 1);
    winSum = zeros(outLen, 1);

    % Expected bin phase advance per analysis hop
    expectedPhaseAdvance = 2 * pi * hop * (0:M-1)' / M;

    lastPhase = zeros(M, 1);
    currentPhase = zeros(M, 1);

    for n = 1:numFrames
        % Analysis: window and FFT
        inIdx = (n - 1) * hop + (1:M);
        frame = x(inIdx) .* win;
        X = fft(frame, M);

        mag = abs(X);
        phase = angle(X);

        % Phase unwrapping and instantaneous frequency estimation
        if n > 1
            deltaPhase = phase - lastPhase;
            deviation = deltaPhase - expectedPhaseAdvance;
            deviation = mod(deviation + pi, 2 * pi) - pi;   % Wrap to [-pi, pi]
            trueFreq = expectedPhaseAdvance + deviation;
            currentPhase = currentPhase + synHop * trueFreq / hop;
        else
            currentPhase = phase;
        end
        lastPhase = phase;

        % Synthesis: IFFT and overlap-add
        Y = mag .* exp(1i * currentPhase);
        y_frame = real(ifft(Y, M));

        outIdx = (n - 1) * synHop + (1:M);
        y(outIdx) = y(outIdx) + y_frame .* win;
        winSum(outIdx) = winSum(outIdx) + win.^2;
    end

    % Overlap-add window normalization to preserve amplitude across alpha values
    nonzero = winSum > 1e-8;
    y(nonzero) = y(nonzero) ./ winSum(nonzero);

    % Guard against clipping on audiowrite
    peak = max(abs(y));
    if peak > 0.99
        y = 0.99 * y / peak;
    end
end
