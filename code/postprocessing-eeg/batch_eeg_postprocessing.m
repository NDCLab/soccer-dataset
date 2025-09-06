% main postprocessing batch script for SocCEr ERP analyses
% coordinates grand average making, difference waves & electrode cluster finding

% This script processes EEG data that has been preprocessed with the MADE pipeline
% and creates condition-specific grand averages based on behavioral codes

% author: Marlene Buch I 2025

clear; 
clc;

%% user input: define subject list & important codes

% slash-separated string of subject IDs to be processed in this run
% subjects_to_process = "390001/390002/390003/390004/390005/390006/390007/390008/390009/390010/390011/390012/390013/390014/390015/390020/390021/390022/390023/390024/390025/390026/390027/390028/390030/390031/390032/390033";
subjects_to_process = "390011";

% convert subjects string to cell array
subjects_list = string(split(subjects_to_process, "/"));
subjects_list = subjects_list(subjects_list~=""); % remove empty entries
subjects = strcat("sub-", subjects_list); % add 'sub-' prefix
fprintf('subjects to process: %d total\n', length(subjects));

% trial codes (relevant for analyses only)
% code structure ABC where 
    % A = social condition
            % 1: social
            % 2: non-social
    % B = target visibility
            % 1: visible-target
            % 2: invisible-target
    % C = response type
            % 1: correct (vis)
            % 2: flanker error (vis / invis)
            % 3: non-flanker error (vis)
            % 4: non-flanker guess (invis)

% trial codes (relevant for analyses only)
codes = [111, 112, 113, 102, 104, 211, 212, 213, 202, 204]; 

% code-to-name mapping for output files
code_names = containers.Map([111, 112, 113, 102, 104, 211, 212, 213, 202, 204], ...
    {'social-vis-corr', 'social-vis-FE', 'social-vis-NFE', 'social-invis-FE', 'social-invis-NFG', ...
     'nonsoc-vis-corr', 'nonsoc-vis-FE', 'nonsoc-vis-NFE', 'nonsoc-invis-FE', 'nonsoc-invis-NFG'});

% minimum epochs per code per subject for inclusion
min_epochs_threshold = 1;

% minimum overall accuracy threshold per subject for inclusion
min_accuracy_threshold = 0.6;

% RT trimming parameters
rt_lower_bound = 150; % ms, set to 0 if no lower bound
rt_outlier_threshold = 3; % standard deviations, set to 0 if no outlier trimming

% two-stage averaging options
save_individual_averages = true; % save individual subject averages per condition

% paths & directories
main_dir = 'C:/Users/localadmin/Documents/08_SocCEr/soccer-dataset';
processed_data_dir = fullfile(main_dir, 'analyses/derivatives/preprocessed/s1_r1/eeg');
output_dir = fullfile(main_dir, 'analyses/derivatives/postprocessed/erp/resp-locked');

% create output directory if it doesn't exist
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('created output directory: %s\n', output_dir);
end

% define difference wave computations
% columns: minuend_code, subtrahend_code, wave_name
diff_waves_table = [
    % visible condition: error - correct within social condition
    112, 111, "diffWave_soc-vis-FE";      % social visible flanker error - correct
    113, 111, "diffWave_soc_vis_NFE";     % social visible nonflanker error - correct  
    212, 211, "diffWave_nonsoc-vis-FE";   % nonsocial visible flanker error - correct
    213, 211, "diffWave_nonsoc-vis-NFE";  % nonsocial visible nonflanker error - correct
    
    % invisible condition: error/NFG - visible correct
    102, 111, "diffWave_soc-invis-FE";      % social invisible flanker error - social visible correct
    104, 111, "diffWave_soc-invis-NFG";     % social invisible NFG - social visible correct  
    202, 211, "diffWave_nonsoc-invis-FE";   % nonsocial invisible flanker error - nonsocial visible correct
    204, 211, "diffWave_nonsoc-invis-NFG"   % nonsocial invisible NFG - nonsocial visible correct
];

fprintf('defined %d difference wave computations\n', size(diff_waves_table, 1))

cluster_size = 5; % nr of electrodes in cluster, values from 1 to 5 are permissible
ern_time_window = [0, 100];
pe_time_window = [200, 500];

%% step 1: check inclusion criteria & make grand averages
fprintf('\n=== STEP 1: CHECKING INCLUSION & MAKING GRAND AVERAGES ===\n');
fprintf('processing %d subjects for %d codes\n', length(subjects), length(code_names));
fprintf('inclusion threshold: minimum %d epochs per code per subject\n', min_epochs_threshold);
fprintf('inclusion threshold: overall accuracy of at least %.0f%%\n', min_accuracy_threshold * 100);

% function call: 
[included_subjects, grand_averages] = make_grand_averages(subjects, ...
    codes, min_epochs_threshold, min_accuracy_threshold, ...
    rt_lower_bound, rt_outlier_threshold, save_individual_averages, ...
    processed_data_dir, output_dir);

fprintf('step 1 completed: %d/%d subjects included\n', length(included_subjects), length(subjects));


%% step 2: compute difference waves  
fprintf('\n=== STEP 2: COMPUTING DIFFERENCE WAVES ===\n');
fprintf('computing configurable difference waves for ERP analyses\n');

% function call
difference_waves = compute_difference_waves(grand_averages, included_subjects, ...
    diff_waves_table, output_dir);

fprintf('step 2 completed: difference waves computed\n');

% Add this right after step 2 (difference waves computation)
fprintf('\n=== DEBUG: Data ranges ===\n');
field_names = fieldnames(difference_waves);
for i = 1:length(field_names)
    if ~ismember(field_names{i}, {'times', 'chanlocs', 'srate', 'nbchan'})
        data_field = difference_waves.(field_names{i});
        fprintf('%s: min=%.3f, max=%.3f, mean=%.3f µV\n', ...
            field_names{i}, min(data_field(:)), max(data_field(:)), mean(data_field(:)));
    end
end

% Check combined wave specifically
if exist('combined_visible_wave', 'var')
    fprintf('Combined wave: min=%.3f, max=%.3f, mean=%.3f µV\n', ...
        min(combined_visible_wave(:)), max(combined_visible_wave(:)), mean(combined_visible_wave(:)));
end

%% step 3: find electrode clusters based on difference waves
fprintf('\n=== STEP 3: FINDING ELECTRODE CLUSTERS ===\n');  
fprintf('identifying fronto-central (Ne/ERN) & centroparietal (Pe) electrode clusters\n');

% function call
electrode_clusters = find_electrode_clusters(difference_waves, output_dir, cluster_size, ern_time_window, pe_time_window);

fprintf('step 3 completed: electrode clusters identified\n');


%% final summary
fprintf('\n=== POSTPROCESSING COMPLETE ===\n');
fprintf('included subjects: %d/%d\n', length(included_subjects), length(subjects));
fprintf('output saved to: %s\n', output_dir);
fprintf('ready for statistical analysis!\n');