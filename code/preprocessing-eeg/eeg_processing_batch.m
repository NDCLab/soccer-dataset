% =========================================================================
% LOCAL PIPELINE EXECUTION SCRIPT
%
% This script serves as a local wrapper to define inputs and run the main 
% 'MADE_pipeline_SocCEr' function. It is the local equivalent of the
% 'eeg_processing_batch.sub' file used for HPC submission.
% =========================================================================

% --- Environment Setup ---
clear all;
clc;

% For Local Execution: Start a parallel pool to speed up 'parfor' loops.
% This is optional but recommended if your machine has multiple cores.
% parpool;

% fprintf('Local pipeline run started at: %s\n', datestr(now));


% --- Define Pipeline Inputs ---
% These variables are passed as arguments to the main pipeline function.

% The 'dataset' variable may be used to construct paths inside the pipeline.
% Set to an empty string if your paths are already absolute.
dataset = 'soccer-dataset'; 

% The specific session to be processed.
session = 's1_r1';

% A slash-separated string of subject IDs to be processed in this run.
subjects_to_process = "390001/390002/390003/390004/390005";


% --- Execute Pipeline ---
% A try/catch block is used for robust error handling during local execution.
% It ensures that if the pipeline fails, an informative error is displayed.
try
    % Call the main pipeline function with the variables defined above.
    MADE_pipeline_SocCEr(dataset, subjects_to_process, session);
    
    % A success message is printed to the command window upon completion.
    fprintf('\nSUCCESS: EEG preprocessing on subjects %s complete.\n', subjects_to_process);

catch ME
    % If an error occurs in the pipeline, this block will execute.
    fprintf(2, '\nERROR: EEG preprocessing on subjects %s failed.\n', subjects_to_process);
    fprintf(2, 'ERROR MESSAGE: %s\n', ME.message);
    
    % Rethrow the error to display the full stack trace for debugging.
    rethrow(ME);
end