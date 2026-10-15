
clc;
clear;
close all;

% =========================================================
% 1. INPUT SIGNAL SETTINGS - CHANGE THESE VALUES
% =========================================================

N = 256;             % Number of samples
Fs = 1000;           % Sampling frequency in Hz
A1 = 1100;            % Amplitude of first sine wave
f1 = 20;              % Frequency of first sine wave
A2 = 1000;             % Amplitude of second sine wave
f2 = 180;             % Frequency of second sine wave
DC = 2000;            % DC offset

windowSize = 12;       % Moving-average filter window

% Generate input signal
n = (0:N-1)';
t = n/Fs;

x = DC + A1*sin(2*pi*f1*t) ...
       + A2*sin(2*pi*f2*t);

samples = round(x);
samples = double(samples(:));

% Ensure all input samples fit in unsigned 16-bit format
if any(samples < 0) || any(samples > 65535)
    error('Input samples must be between 0 and 65535.');
end

fprintf('Generated %d input samples.\n', N);

% =========================================================
% 2. MATLAB REFERENCE MOVING-AVERAGE FILTER
% =========================================================

% Initial missing samples are treated as zero.
% The divisor remains windowSize for every output.
reference = zeros(N,1);

for k = 1:N
    firstIndex = max(1, k-windowSize+1);

    reference(k) = floor( ...
        sum(samples(firstIndex:k))/windowSize);
end

% =========================================================
% 3. UART COMMUNICATION WITH ZEDBOARD
% =========================================================

portName = 'COM3';
baudRate = 115200;

% Create serial connection (MATLAB R2013a)
s = serial(portName, ...
    'BaudRate', baudRate, ...
    'DataBits', 8, ...
    'Parity', 'none', ...
    'StopBits', 1, ...
    'FlowControl', 'none', ...
    'Timeout', 5);

try
    fopen(s);
    flushinput(s);

    fprintf('UART connected: %s\n', portName);
    fprintf('Sending samples to FPGA...\n');

    fpga_output = zeros(N,1);

    for k = 1:N

        % Convert input to 16-bit unsigned value
        sample = uint16(samples(k));

        % Send low byte first, then high byte
        lowByte  = uint8(bitand(sample, 255));
        highByte = uint8(bitshift(sample, -8));

        fwrite(s, [lowByte; highByte], 'uint8');

        % Read the two-byte FPGA result
        response = fread(s, 2, 'uint8');

        if numel(response) ~= 2
            error('UART timeout at sample %d. Check COM3 and Vitis.', k);
        end

        % Reconstruct unsigned 16-bit output
        fpga_output(k) = double(response(1)) ...
                       + 256*double(response(2));

        % Optional error marker used by the Vitis application
        if fpga_output(k) == 65535
            error('FPGA error marker received at sample %d.', k);
        end

        if mod(k,32) == 0 || k == N
            fprintf('Received %d / %d samples\n', k, N);
        end
    end

    fclose(s);
    delete(s);
    clear s;

catch ME
    % Close and delete serial port after errors
    if strcmp(get(s,'Status'),'open')
        fclose(s);
    end

    delete(s);
    clear s;
    rethrow(ME);
end

fprintf('FPGA processing completed.\n');

% =========================================================
% 4. COMPARE MATLAB AND FPGA OUTPUTS
% =========================================================

% Error = FPGA result - MATLAB reference
errorValues = fpga_output - reference;

maxError = max(abs(errorValues));
mismatchCount = sum(errorValues ~= 0);

fprintf('\nMaximum absolute error: %g\n', maxError);
fprintf('Number of mismatches: %d\n', mismatchCount);

if mismatchCount == 0
    fprintf('PASS: All FPGA outputs match MATLAB reference.\n');
else
    fprintf('CHECK: Some FPGA outputs do not match.\n');
end

% =========================================================
% 5. PLOT INPUT, REFERENCE AND FPGA OUTPUT
% =========================================================

figure;

plot(t, samples, 'b-', 'LineWidth', 1.2);
hold on;
plot(t, reference, 'g--', 'LineWidth', 1.5);
plot(t, fpga_output, 'r:', 'LineWidth', 1.5);

grid on;
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Moving Average Filter: MATLAB and FPGA');
legend('Input Signal', 'MATLAB Reference', ...
       'FPGA Output', 'Location', 'best');

% Plot FPGA error
figure;

plot(t, errorValues, 'k-', 'LineWidth', 1.2);
grid on;
xlabel('Time (seconds)');
ylabel('Error');
title('FPGA Output Error');

% =========================================================
% 6. SAVE ALL RESULTS IN ONE EXCEL FILE
% =========================================================

% Select the folder only ONCE
outputFolder = uigetdir(pwd, 'Select folder for DSP Excel results');

if isequal(outputFolder, 0)
    disp('Excel saving cancelled.');
else
    excelFile = fullfile(outputFolder, 'DSP_FPGA_Results.xlsx');

    % Sheet 1: All sample-by-sample results
    headers = {'Sample Index', 'Time (s)', ...
        'Input Sample', 'MATLAB Reference', ...
        'FPGA Output', 'Error'};

    results = [(1:N)', t, samples, reference, ...
               fpga_output, errorValues];

    % Write column headings and sample data
    xlswrite(excelFile, headers, 'Results', 'A1');
    xlswrite(excelFile, results, 'Results', 'A2');

    % Sheet 2: Run configuration and comparison summary
    summary = {
        'Parameter', 'Value';
        'Sample Count', N;
        'Sampling Frequency (Hz)', Fs;
        'DC Offset', DC;
        'Amplitude 1', A1;
        'Frequency 1 (Hz)', f1;
        'Amplitude 2', A2;
        'Frequency 2 (Hz)', f2;
        'Moving Average Window', windowSize;
        'Maximum Absolute Error', maxError;
        'Mismatch Count', mismatchCount;
        'Result', 'See mismatch count above'
    };

    if mismatchCount == 0
        summary{end,2} = 'PASS';
    else
        summary{end,2} = 'CHECK';
    end

    xlswrite(excelFile, summary, 'Summary', 'A1');

    fprintf('\nAll results saved in one Excel workbook:\n%s\n', ...
        excelFile);
end
