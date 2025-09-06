% --- Direct ERP Plotting Script for Two .set Files ---
% This script loads two specified EEGLAB .set files and plots the ERP 
% waveform from a single electrode for comparison.

clear; 
clc; 
close all;

% PREREQUISITE: Make sure EEGLAB is running in MATLAB.

%% User Settings: PASTE YOUR FILE PATHS AND SETTINGS HERE

% 1. Specify the full path to the FIRST .set file you want to plot
file_path_1 = 'C:\Users\localadmin\Documents\08_SocCEr\soccer-dataset\analyses\derivatives\postprocessed\erp\resp-locked\grandAVG_111_social-vis-corr.set';

% 2. Specify the full path to the SECOND .set file you want to plot
file_path_2 = 'C:\Users\localadmin\Documents\08_SocCEr\soccer-dataset\analyses\derivatives\postprocessed\erp\resp-locked\grandAVG_112_social-vis-FE.set';

% 3. Choose the electrode you want to plot
electrode_to_plot = '1'; 

%% 1. Load the two EEG .set Files

% Check if files exist before trying to load
if ~exist(file_path_1, 'file')
    error('File not found: %s', file_path_1);
end
if ~exist(file_path_2, 'file')
    error('File not found: %s', file_path_2);
end

fprintf('Loading File 1: %s\n', file_path_1);
EEG1 = pop_loadset(file_path_1);

fprintf('Loading File 2: %s\n', file_path_2);
EEG2 = pop_loadset(file_path_2);

%% 2. Prepare Data for Plotting

% Find the index number of the electrode you want to plot
% (We assume both files have the same channel locations)
electrode_labels = {EEG1.chanlocs.labels};
electrode_index = find(strcmp(electrode_labels, electrode_to_plot));

if isempty(electrode_index)
    error('Electrode "%s" not found. Check spelling or choose another.', electrode_to_plot);
end

% Get the time vector for the x-axis from the first file
time_vector = EEG1.times;

% --- Extract the ERP data for the chosen electrode ---
% For these average files, the data is 2D: [channels x timepoints]
erp_data_1 = EEG1.data(electrode_index, :); 
erp_data_2 = EEG2.data(electrode_index, :); 

%% 3. Create the Plot

figure; % Create a new figure window
hold on; % Allow multiple lines on the same plot

% Plot the two ERP waveforms
plot(time_vector, erp_data_1, 'LineWidth', 1.5);
plot(time_vector, erp_data_2, 'LineWidth', 1.5, 'LineStyle', '--');

% --- Add labels and formatting ---
title(['ERP Comparison at Electrode: ' electrode_to_plot]);
xlabel('Time (ms)');
ylabel('Amplitude (\muV)');

% Use the filenames for the legend to be explicit
legend({EEG1.setname, EEG2.setname}, 'Location', 'southwest', 'Interpreter', 'none');

% Add zero lines for reference
xline(0, '--', 'Color', [0.5 0.5 0.5]);
yline(0, '--', 'Color', [0.5 0.5 0.5]);

% Invert the y-axis (ERP convention: negative is up)
set(gca, 'YDir', 'reverse');

% Tidy up the plot
grid on;
box on;
hold off;

fprintf('Plot created successfully!\n');