function EEG = integrate_behavioral_data(EEG, BEH)
    % integrate behavioral data with EEG epochs with meticulous verification
    fprintf('integrating behavioral data with EEG epochs...\n');
    
    % verify prerequisites
    assert(height(BEH) == 864, 'expected 864 behavioral trials, found %d', height(BEH));
    assert(isfield(EEG, 'epoch'), 'EEG.epoch not found - run epoching first');
    assert(isfield(EEG.epoch(1), 'trial_idx'), 'trial_info not added to epochs - run add_trial_info_to_epochs first');
    
    fprintf('behavioral trials: %d\n', height(BEH));
    fprintf('EEG epochs: %d\n', EEG.trials);
    
    % initialize matching counters
    matched_count = 0;
    verification_failures = 0;
    
    % match each EEG epoch to behavioral data
    for epoch = 1:EEG.trials
        % get the trial_info index for this epoch
        trial_idx = EEG.epoch(epoch).trial_idx;
        
        if isempty(trial_idx) || trial_idx < 1 || trial_idx > height(BEH)
            fprintf('ERROR: epoch %d has invalid trial_idx = %d\n', epoch, trial_idx);
            verification_failures = verification_failures + 1;
            continue;
        end
        
        % get EEG trial info for verification
        eeg_trial = struct();
        eeg_trial.target = EEG.epoch(epoch).trial_target;
        eeg_trial.flanker = EEG.epoch(epoch).trial_flanker;
        eeg_trial.visInvis = EEG.epoch(epoch).trial_visInvis;
        eeg_trial.block_condition = EEG.epoch(epoch).trial_block;
        eeg_trial.response_key = EEG.epoch(epoch).trial_response_key;
        eeg_trial.responseType = EEG.epoch(epoch).trial_responseType;
        eeg_trial.correctKey = EEG.epoch(epoch).trial_correctKey;
        eeg_trial.flankerKey = EEG.epoch(epoch).trial_flankerKey;
        
        % verify match with behavioral data
        if verify_eeg_beh_match(eeg_trial, BEH, trial_idx, epoch)
            % add behavioral data to epoch
            EEG.epoch(epoch).beh_trial_nr = trial_idx;
            EEG.epoch(epoch).beh_code = BEH.code(trial_idx);
            EEG.epoch(epoch).beh_confidence = BEH.confidenceRating(trial_idx);
            EEG.epoch(epoch).beh_flankerResp_rt = BEH.flankerResponse_rt(trial_idx);
            EEG.epoch(epoch).beh_confidenceResp_rt = BEH.confidenceRating_rt(trial_idx);
            EEG.epoch(epoch).beh_SMI = BEH.SMI(trial_idx);
            EEG.epoch(epoch).beh_matched = 1;

            matched_count = matched_count + 1;
        else
            verification_failures = verification_failures + 1;
            fprintf('VERIFICATION FAILED: epoch %d, trial %d\n', epoch, trial_idx);
            EEG.epoch(epoch).beh_matched = 0;
        end
    end
    
    % final verification summary
    fprintf('\n=== BEHAVIORAL INTEGRATION SUMMARY ===\n');
    fprintf('EEG epochs: %d\n', EEG.trials);
    fprintf('successfully matched: %d\n', matched_count);
    fprintf('verification failures: %d\n', verification_failures);
    
    if verification_failures == 0 && matched_count == EEG.trials
        fprintf('PERFECT INTEGRATION - all epochs matched and verified\n');
    else
        fprintf('INTEGRATION ISSUES DETECTED\n');
        if verification_failures > 0
            fprintf('  - %d verification failures\n', verification_failures);
        end
        if matched_count ~= EEG.trials
            fprintf('  - match count mismatch: got %d, expected %d\n', matched_count, EEG.trials);
        end
    end
    
    % show code statistics
    codes = [EEG.epoch.beh_code];
    unique_codes = unique(codes);
    fprintf('behavioral codes found: [%s]\n', num2str(unique_codes));
    for code = unique_codes
        count = sum(codes == code);
        fprintf('  code %d: %d epochs\n', code, count);
    end
    
    fprintf('==========================================\n\n');
end

function is_match = verify_eeg_beh_match(eeg_trial, BEH, beh_idx, epoch_num)
    % meticulously verify that EEG and behavioral trials match
    
    % check all key characteristics
    target_match = strcmp(BEH.target{beh_idx}, eeg_trial.target);
    flanker_match = strcmp(BEH.flanker{beh_idx}, eeg_trial.flanker);
    
    % FIXED: handle visibility string differences
    eeg_vis = eeg_trial.visInvis;
    beh_vis = BEH.visInvis{beh_idx};
    visibility_match = strcmp(eeg_vis, beh_vis) || ...
                      (strcmp(eeg_vis, 'invisible') && strcmp(beh_vis, 'invis')) || ...
                      (strcmp(eeg_vis, 'visible') && strcmp(beh_vis, 'vis'));

    eeg_block = eeg_trial.block_condition;
    beh_block = BEH.block_condition{beh_idx};
    block_match = strcmp(eeg_block, beh_block) || ...
        (strcmp(eeg_block, 'nonsocial') && strcmp(beh_block, 'non-social')) || ...
        (strcmp(eeg_block, 'social') && strcmp(beh_block, 'social'));
    response_match = strcmp(BEH.flankerResponse_keys{beh_idx}, eeg_trial.response_key);
    
    % check responseType consistency
    responseType_match = (BEH.responseType(beh_idx) == eeg_trial.responseType);
    
    % check correctKey and flankerKey consistency
    correctKey_match = strcmp(BEH.correctKey{beh_idx}, eeg_trial.correctKey);
    flankerKey_match = strcmp(BEH.flankerKey{beh_idx}, eeg_trial.flankerKey);
    
    % overall match requires ALL checks to pass
    is_match = target_match && flanker_match && visibility_match && block_match && ...
               response_match && responseType_match && correctKey_match && flankerKey_match;
    
    if ~is_match
        fprintf('  MISMATCH DETAILS for epoch %d:\n', epoch_num);
        fprintf('    target: EEG=%s, BEH=%s (%d)\n', eeg_trial.target, BEH.target{beh_idx}, target_match);
        fprintf('    flanker: EEG=%s, BEH=%s (%d)\n', eeg_trial.flanker, BEH.flanker{beh_idx}, flanker_match);
        fprintf('    visibility: EEG=%s, BEH=%s (%d)\n', eeg_trial.visInvis, BEH.visInvis{beh_idx}, visibility_match);
        fprintf('    block: EEG=%s, BEH=%s (%d)\n', eeg_trial.block_condition, BEH.block_condition{beh_idx}, block_match);
        fprintf('    response: EEG=%s, BEH=%s (%d)\n', eeg_trial.response_key, BEH.flankerResponse_keys{beh_idx}, response_match);
        fprintf('    responseType: EEG=%d, BEH=%d (%d)\n', eeg_trial.responseType, BEH.responseType(beh_idx), responseType_match);
        fprintf('    correctKey: EEG=%s, BEH=%s (%d)\n', eeg_trial.correctKey, BEH.correctKey{beh_idx}, correctKey_match);
        fprintf('    flankerKey: EEG=%s, BEH=%s (%d)\n', eeg_trial.flankerKey, BEH.flankerKey{beh_idx}, flankerKey_match);
    end
end