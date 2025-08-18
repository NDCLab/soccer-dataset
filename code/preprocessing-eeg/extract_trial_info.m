function EEG = extract_trial_info(EEG)
    % extract trial info from continuous data, grouped by fixation cross onsets
    fprintf('extracting trial information from continuous data...\n');
    
    % extract key mapping from triggers first
    key_mapping = extract_key_mapping(EEG);
    
    % build block condition timeline first
    block_conditions = build_block_condition_timeline(EEG);
    
    % find all fixation cross triggers (trial onsets)
    fixation_indices = [];
    for i = 1:length(EEG.event)
        if strcmp(EEG.event(i).type, 'S  1')
            fixation_indices = [fixation_indices, i];
        end
    end
    
    fprintf('found %d fixation triggers (trial onsets)\n', length(fixation_indices));
    
    % extract trial info for each fixation
    trial_info = struct();
    
    for i = 1:length(fixation_indices)
        fix_idx = fixation_indices(i);
        fix_latency = EEG.event(fix_idx).latency;
        
        % initialize trial
        trial_info(i).fixation_latency = fix_latency;
        trial_info(i).target = '';
        trial_info(i).flanker = '';
        trial_info(i).visInvis = '';
        trial_info(i).response_key = '';
        trial_info(i).responseType = 0; % default = no classification found
        trial_info(i).has_response = false;
        trial_info(i).correctKey = '';
        trial_info(i).flankerKey = '';
        
        % assign block condition based on timeline
        trial_info(i).block_condition = get_block_condition_at_time(block_conditions, fix_latency);
        
        % determine search window (from this fixation to next fixation or end)
        if i < length(fixation_indices)
            search_end = EEG.event(fixation_indices(i+1)).latency;
        else
            search_end = EEG.event(end).latency; % last trial goes to end of recording
        end
        
        % search for events in this trial window  
        for j = 1:length(EEG.event)
            event_lat = EEG.event(j).latency;
            if event_lat >= fix_latency && event_lat < search_end
                event_type = EEG.event(j).type;
                
                % target letter
                switch event_type
                    case 'S 16', trial_info(i).target = 'P';
                    case 'S 17', trial_info(i).target = 'W';
                    case 'S 18', trial_info(i).target = 'M';
                    case 'S 19', trial_info(i).target = 'V';
                    case 'S 20', trial_info(i).target = 'B';
                    case 'S 21', trial_info(i).target = 'R';
                end
                
                % flanker letter
                switch event_type
                    case 'S 32', trial_info(i).flanker = 'P';
                    case 'S 33', trial_info(i).flanker = 'W';
                    case 'S 34', trial_info(i).flanker = 'M';
                    case 'S 35', trial_info(i).flanker = 'V';
                    case 'S 36', trial_info(i).flanker = 'B';
                    case 'S 37', trial_info(i).flanker = 'R';
                end
                
                % visibility
                switch event_type
                    case 'S112', trial_info(i).visInvis = 'visible';
                    case 'S113', trial_info(i).visInvis = 'invisible';
                end
                
                % response key
                switch event_type
                    case 'S 40', trial_info(i).response_key = 's'; trial_info(i).has_response = true;
                    case 'S 41', trial_info(i).response_key = 'd'; trial_info(i).has_response = true;
                    case 'S 42', trial_info(i).response_key = 'f'; trial_info(i).has_response = true;
                end

                switch event_type
                    case 'S  7', trial_info(i).eeg_responseType = 1;  % correct
                    case 'S  8', trial_info(i).eeg_responseType = 2;  % visible flanker error
                    case 'S  9', trial_info(i).eeg_responseType = 2;  % invisible flanker error
                    case 'S 10', trial_info(i).eeg_responseType = 3;  % nonflanker error
                    case 'S 11', trial_info(i).eeg_responseType = 4;  % NFG ← CORRECT!
                    case 'S 12', trial_info(i).eeg_responseType = 7;  % multiple key
                    case 'S 13', trial_info(i).eeg_responseType = 9;  % backup
                    case 'S  5', trial_info(i).eeg_responseType = 8;  % too slow 
                end
            end
        end
        
        % calculate correctKey and flankerKey for this trial
        if ~isempty(trial_info(i).target) && ~isempty(trial_info(i).flanker)
            trial_info(i).correctKey = get_key_for_letter(trial_info(i).target, key_mapping);
            trial_info(i).flankerKey = get_key_for_letter(trial_info(i).flanker, key_mapping);
            
            % calculate responseType with NFG logic
            trial_info(i).responseType = calculate_response_type(trial_info(i));
        end
        
        % if no response found and responseType not set, classify as too slow
        if ~trial_info(i).has_response && trial_info(i).responseType == 0
            trial_info(i).responseType = 8; % too slow
        end
    end
    
    % store in EEG structure
    EEG.trial_info = trial_info;
    
    % report summary
    trials_with_responses = sum([trial_info.has_response]);
    fprintf('trial info extracted: %d total trials, %d with responses\n', ...
        length(trial_info), trials_with_responses);
    
    % show block condition distribution
    social_trials = sum(strcmp({trial_info.block_condition}, 'social'));
    nonsocial_trials = sum(strcmp({trial_info.block_condition}, 'nonsocial'));
    unknown_trials = sum(strcmp({trial_info.block_condition}, 'unknown'));
    fprintf('block conditions: %d social, %d nonsocial, %d unknown\n', ...
        social_trials, nonsocial_trials, unknown_trials);
    
    % show responseType distribution
    response_types = [trial_info.responseType];
    fprintf('responseType distribution:\n');
    for rt = [1,2,3,4,7,8,9]
        count = sum(response_types == rt);
        if count > 0
            type_names = {'correct','flanker_error','nonflanker_error','NFG','','','multiple_key','too_slow','error'};
            fprintf('  %d (%s): %d trials\n', rt, type_names{rt}, count);
        end
    end

    % ADD THIS - verify calculated vs EEG classification
fprintf('\n=== RESPONSE TYPE VERIFICATION ===\n');
matches = 0;
mismatches = 0;
for i = 1:length(trial_info)
    if trial_info(i).has_response && isfield(trial_info(i), 'eeg_responseType')
        if trial_info(i).responseType == trial_info(i).eeg_responseType
            matches = matches + 1;
        else
            mismatches = mismatches + 1;
            fprintf('MISMATCH trial %d: calculated=%d, EEG trigger=%d\n', ...
                i, trial_info(i).responseType, trial_info(i).eeg_responseType);
        end
    end
end
fprintf('Verification: %d matches, %d mismatches\n', matches, mismatches);
if mismatches == 0
    fprintf('PERFECT MATCH - all calculated responseTypes match EEG triggers\n');
else
    fprintf('%d discrepancies found between calculated and EEG classification\n', mismatches);
end
end

function key_mapping = extract_key_mapping(EEG)
    % extract key mapping from EEG triggers (different for each participant)
    key_mapping = struct();
    key_mapping.PW = '';
    key_mapping.MV = '';
    key_mapping.BR = '';
    
    for i = 1:length(EEG.event)
        switch EEG.event(i).type
            case 'S 70', key_mapping.PW = 's';
            case 'S 71', key_mapping.PW = 'd';
            case 'S 72', key_mapping.PW = 'f';
            case 'S 80', key_mapping.MV = 's';
            case 'S 81', key_mapping.MV = 'd';
            case 'S 82', key_mapping.MV = 'f';
            case 'S 90', key_mapping.BR = 's';
            case 'S 91', key_mapping.BR = 'd';
            case 'S 92', key_mapping.BR = 'f';
        end
    end
    
    fprintf('key mapping: PW->%s, MV->%s, BR->%s\n', key_mapping.PW, key_mapping.MV, key_mapping.BR);
end

function key = get_key_for_letter(letter, key_mapping)
    % get the key assigned to a specific letter
    switch letter
        case {'P', 'W'}, key = key_mapping.PW;
        case {'M', 'V'}, key = key_mapping.MV;
        case {'B', 'R'}, key = key_mapping.BR;
        otherwise, key = '';
    end
end

function responseType = calculate_response_type(trial_info)
    % calculate responseType using ONLY EEG triggers, following clean_csv.R order
    
    % FIRST: check for too slow trigger (S  5)
    if isfield(trial_info, 'eeg_responseType') && trial_info.eeg_responseType == 8
        responseType = 8; % too slow
        return;
    end
    
    % SECOND: check for multiple key trigger (S 12)
    if isfield(trial_info, 'eeg_responseType') && trial_info.eeg_responseType == 7
        responseType = 7; % multiple key
        return;
    end
    
    % THIRD: check for other classification triggers
    if isfield(trial_info, 'eeg_responseType') && trial_info.eeg_responseType > 0
        responseType = trial_info.eeg_responseType; % use whatever EEG classification was found
        return;
    end
    
    % FOURTH: if no classification trigger found but has response, calculate from response
    if trial_info.has_response
        response = trial_info.response_key;
        correctKey = trial_info.correctKey;
        flankerKey = trial_info.flankerKey;
        
        if strcmp(trial_info.visInvis, 'invisible')
            SMI = 0;
        else
            SMI = 1;
        end
        
        if SMI == 0 && ~strcmp(response, flankerKey)
            responseType = 4; % NFG
        elseif strcmp(response, correctKey) && SMI ~= 0
            responseType = 1; % correct
        elseif strcmp(response, flankerKey) && ~strcmp(response, correctKey)
            responseType = 2; % flanker error
        elseif ~strcmp(response, flankerKey) && ~strcmp(response, correctKey) && SMI ~= 0
            responseType = 3; % no-flanker error
        else
            responseType = 9; % error case
        end
    else
        % FIFTH: no response and no classification trigger = too slow
        responseType = 8; % too slow
    end
end

function block_conditions = build_block_condition_timeline(EEG)
    % build timeline of when block conditions change
    block_conditions = struct();
    condition_changes = [];
    
    for i = 1:length(EEG.event)
        if strcmp(EEG.event(i).type, 'S 96')
            condition_changes = [condition_changes; EEG.event(i).latency, 1]; % 1 = social
        elseif strcmp(EEG.event(i).type, 'S 97')
            condition_changes = [condition_changes; EEG.event(i).latency, 2]; % 2 = nonsocial
        end
    end
    
    if ~isempty(condition_changes)
        block_conditions.latencies = condition_changes(:,1);
        block_conditions.types = condition_changes(:,2);
        fprintf('found %d block condition changes\n', size(condition_changes,1));
    else
        block_conditions.latencies = [];
        block_conditions.types = [];
        fprintf('warning: no block condition triggers found\n');
    end
end

function condition = get_block_condition_at_time(block_conditions, time_point)
    % find which block condition is active at given time
    if isempty(block_conditions.latencies)
        condition = 'unknown';
        return;
    end
    
    % find most recent block condition change before this time
    valid_changes = block_conditions.latencies <= time_point;
    if any(valid_changes)
        last_change_idx = find(valid_changes, 1, 'last');
        if block_conditions.types(last_change_idx) == 1
            condition = 'social';
        else
            condition = 'nonsocial';
        end
    else
        condition = 'unknown'; % before any block condition was set
    end
end