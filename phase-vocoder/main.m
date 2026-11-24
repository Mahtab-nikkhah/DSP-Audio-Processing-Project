%% Classical Phase Vocoder — Time-Stretching & Spectrogram Analysis
% Processes a speech sample with stretching factors alpha = 0.5, 1.0, and 1.5,
% exports the time-stretched WAV files, and saves comparison spectrograms.

clear; clc; close all;

%% Parameters
filename = fullfile('..', 'speaker-recognition', 'test', 's8.wav'); % Replace with any WAV file
M        = 1024;                                                     % FFT size
win      = 0.5 * (1 - cos(2 * pi * (0:M-1)' / (M - 1)));            % Hann window (no toolbox needed)
hop      = M / 4;                                                    % Analysis hop size (75% overlap)
noverlap = M - hop;
alphas   = [0.5, 1.0, 1.5];

output_dir = 'outputs';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Load Audio
if ~isfile(filename)
    error('Audio file not found: %s', filename);
end
[x, fs] = audioread(filename);
if size(x, 2) > 1
    x = mean(x, 2);
end
fprintf('Loaded "%s" (fs = %d Hz, duration = %.2f s)\n', filename, fs, length(x) / fs);

%% Apply Phase Vocoder for Each Stretching Factor
output_signals = cell(1, length(alphas));
for i = 1:length(alphas)
    alpha = alphas(i);
    y = phaseVocoder(x, M, win, hop, alpha);
    output_signals{i} = y;

    out_wav = fullfile(output_dir, sprintf('output_alpha_%s.wav', strrep(num2str(alpha, '%.1f'), '.', '_')));
    audiowrite(out_wav, y, fs);
    fprintf('Saved %s (duration = %.2f s)\n', out_wav, length(y) / fs);
end

%% Generate and Save Comparison Spectrograms
figure('Name', 'Phase Vocoder Spectrogram Comparison', 'Position', [80, 80, 1150, 720]);

subplot(2, 2, 1);
spectrogram(x, win, noverlap, M, fs, 'yaxis');
ylim([0, 8]);
title(sprintf('Original Signal (%.2f s)', length(x) / fs));

for i = 1:length(alphas)
    alpha = alphas(i);
    y = output_signals{i};
    subplot(2, 2, i + 1);
    spectrogram(y, win, noverlap, M, fs, 'yaxis');
    ylim([0, 8]);
    title(sprintf('Time-Stretched (\\alpha = %.1f, %.2f s)', alpha, length(y) / fs));
end

saveas(gcf, fullfile(output_dir, 'phase_vocoder_spectrograms.png'));
fprintf('Saved spectrogram comparison to %s\n', fullfile(output_dir, 'phase_vocoder_spectrograms.png'));
