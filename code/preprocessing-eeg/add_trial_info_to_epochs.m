function EEG = add_trial_info_to_epochs(EEG)
    % add trial_info to EEG epochs with verification
    fprintf('adding trial_info to EEG epochs...\n');
    
    % verify prerequisites
    if ~isfield(EEG, 'trial_info')
        error('EEG.trial_info not found - run extract_trial_info first');
    end
    if ~isfield(EEG, 'epoch')
        error('EEG.epoch not found - run epoching first');
    end
    
    % STEP 1: verify counts match expectation
    total_trials = length(EEG.trial_info);
    trials_with_responses = sum([EEG.trial_info.has_response]);
    trials_without_responses = total_trials - trials_with_responses;
    actual_epochs = EEG.trials;
    
    fprintf('total trial_info entries: %d\n', total_trials);
    fprintf('trials with responses: %d\n', trials_with_responses);
    fprintf('trials without responses: %d\n', trials_without_responses);
    fprintf('actual epochs: %d\n', actual_epochs);
    
    if trials_with_responses ~= actual_epochs
        error('mismatch: %d trials with responses but %d epochs', trials_with_responses, actual_epochs);
    end
    
    % STEP 2: match each epoch to trial_info sequentially through trials with responses
    matched_count = 0;
    trial_info_idx = 1; % start from first trial
    
    for epoch = 1:EEG.trials
        % find response trigger in this epoch
        epoch_events = EEG.epoch(epoch).eventtype;
        response_triggers = epoch_events(ismember(epoch_events, {'S 40', 'S 41', 'S 42'}));
        
        if isempty(response_triggers)
            error('epoch %d has no response trigger', epoch);
        end
        
        % get response key from trigger
        actual_response = '';
        switch response_triggers{1}
            case 'S 40', actual_response = 's';
            case 'S 41', actual_response = 'd';
            case 'S 42', actual_response = 'f';
        end
        
        % find next trial with response in trial_info
        trial_found = false;
        while trial_info_idx <= length(EEG.trial_info) && ~trial_found
            if EEG.trial_info(trial_info_idx).has_response
                % check if response keys match
                expected_response = EEG.trial_info(trial_info_idx).response_key;
                
                if strcmp(expected_response, actual_response)
                    % verify this is the right match
                    if verify_trial_epoch_match(EEG.trial_info(trial_info_idx), EEG, epoch)
                        % add trial_info to this epoch
                        EEG.epoch(epoch).trial_idx = trial_info_idx;
                        EEG.epoch(epoch).trial_target = EEG.trial_info(trial_info_idx).target;
                        EEG.epoch(epoch).trial_flanker = EEG.trial_info(trial_info_idx).flanker;
                        EEG.epoch(epoch).trial_visInvis = EEG.trial_info(trial_info_idx).visInvis;
                        EEG.epoch(epoch).trial_block = EEG.trial_info(trial_info_idx).block_condition;
                        EEG.epoch(epoch).trial_responseType = EEG.trial_info(trial_info_idx).responseType;
                        EEG.epoch(epoch).trial_response_key = EEG.trial_info(trial_info_idx).response_key;
                        EEG.epoch(epoch).trial_correctKey = EEG.trial_info(trial_info_idx).correctKey;
                        EEG.epoch(epoch).trial_flankerKey = EEG.trial_info(trial_info_idx).flankerKey;
                        EEG.epoch(epoch).trial_matched = 1;
                        
                        matched_count = matched_count + 1;
                        trial_found = true;
                    else
                        fprintf('verification failed for epoch %d, trial_info %d\n', epoch, trial_info_idx);
                    end
                end
                trial_info_idx = trial_info_idx + 1;
            else
                % skip trials without responses
                trial_info_idx = trial_info_idx + 1;
            end
        end
        
        if ~trial_found
            error('could not match epoch %d to any trial_info entry', epoch);
        end
    end
    
    % STEP 3: final verification
    fprintf('\n=== TRIAL_INFO TO EPOCHS SUMMARY ===\n');
    fprintf('successfully matched: %d/%d epochs\n', matched_count, EEG.trials);
    
    if matched_count == EEG.trials
        fprintf('PERFECT MATCHING - all epochs have trial_info\n');
    else
        fprintf('MATCHING ISSUES - %d epochs unmatched\n', EEG.trials - matched_count);
    end
    
    % show responseType distribution in epochs
    epoch_response_types = [EEG.epoch.trial_responseType];
    fprintf('epoch responseType distribution:\n');
    for rt = [1,2,3,4,7,8,9]
        count = sum(epoch_response_types == rt);
        if count > 0
            type_names = {'correct','flanker_error','nonflanker_error','NFG','','','multiple_key','too_slow','error'};
            fprintf('  %d (%s): %d epochs\n', rt, type_names{rt}, count);
        end
    end
    fprintf('=====================================\n\n');
end

function is_match = verify_trial_epoch_match(trial_info, EEG, epoch_idx)
    % verify using only the triggers actually present in epochs
    
    epoch_events = EEG.epoch(epoch_idx).eventtype;
    
    % check 1: response trigger matches expected response (already checked in main function)
    response_triggers = epoch_events(ismember(epoch_events, {'S 40', 'S 41', 'S 42'}));
    if ~isempty(response_triggers)
        expected_response = trial_info.response_key;
        actual_response = '';
        switch response_triggers{1}
            case 'S 40', actual_response = 's';
            case 'S 41', actual_response = 'd'; 
            case 'S 42', actual_response = 'f';
        end
        response_match = strcmp(expected_response, actual_response);
    else
        response_match = false;
    end
    
    % check 2: classification trigger matches (if present)
    classification_triggers = epoch_events(ismember(epoch_events, {'S  7', 'S  8', 'S  9', 'S 10', 'S 11', 'S 12', 'S 13'}));
    if ~isempty(classification_triggers)
        % convert classification trigger to responseType
        eeg_response_type = 0;
        switch classification_triggers{1}
            case 'S  7', eeg_response_type = 1;
            case 'S  8', eeg_response_type = 2;
            case 'S  9', eeg_response_type = 2;
            case 'S 10', eeg_response_type = 3;
            case 'S 11', eeg_response_type = 4;
            case 'S 12', eeg_response_type = 7;
            case 'S 13', eeg_response_type = 9;
        end
        classification_match = (eeg_response_type == trial_info.responseType);
    else
        classification_match = true; % no classification trigger to verify
    end
    
    % overall match - requires both checks to pass
    is_match = response_match && classification_match;
    
    if ~is_match
        fprintf('  verification details: response=%d, classification=%d\n', ...
            response_match, classification_match);
    end
end