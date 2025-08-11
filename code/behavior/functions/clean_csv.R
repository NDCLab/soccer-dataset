# ===================================================================
# Data Cleaning Functions
# ===================================================================

clean_csv <- function(subject_id) {
  # get file paths
  input_file <- get_subject_test_csv(subject_id)
  output_file <- get_clean_output_path(subject_id)
  
  # check if input file exists
  if (!file.exists(input_file)) {
    warning("input file not found for ", subject_id, ": ", input_file)
    return(FALSE)
  }
  
  # read the data
  raw_data <- read_csv(input_file, show_col_types = FALSE)
  
  suppressWarnings({
    # clean the data - keep only essentials for EEG integration
    clean_data <- raw_data %>%
      
      # remove practice trials (where practiceTrials.thisTrialN is not NA)
      filter(is.na(practiceTrials.thisTrialN)) %>%
      
      # remove empty rows (where SMI is empty/NA)
      filter(!is.na(SMI)) %>%
      
      # keep only essential columns
      select(
        id,
        target,
        flanker,
        SMI,
        visInvis,
        block_condition,
        correctKey,
        flankerKey,
        flankerResponse.keys,
        flankerResponse.rt,
        ConfidenceRating,
        confidencePrompt.started
      ) %>%
      
      # fill down block condition info
      fill(block_condition, .direction = "down") %>%
      
      # create trial counter
      mutate(trial_nr = row_number()) %>%
      
      # clean stimulus names & response data
      mutate(
        # extract letter from stimulus filenames (e.g., "stimuli/B.jpg" → "B")
        target = str_extract(target, "(?<=/)[A-Z](?=\\.jpg)"),
        flanker = str_extract(flanker, "(?<=/)[A-Z](?=\\.jpg)"),
        
        # extract letter from response
        flankerResponse.keys = str_extract(flankerResponse.keys, "(?<=')[a-zA-Z]+(?=')")
      ) %>%
      
      # create response type and trial codes
      mutate(
        # extract numeric RT for deadline checking
        rt_numeric = as.numeric(str_extract(flankerResponse.rt, "[0-9\\.]+")),
        
        # response type classification
        responseType = case_when(
          # too slow (8): no response OR response after 2000ms cutoff without confidence prompt
          is.na(flankerResponse.keys) | flankerResponse.keys == "None" ~ 8,
          !is.na(rt_numeric) & rt_numeric > 2000 & is.na(confidencePrompt.started) ~ 8,
          
          # double response (7): multiple keypresses (contains comma in rt string)
          str_detect(flankerResponse.rt, ",") ~ 7,
          
          # other response types
          SMI == 0 & flankerResponse.keys != flankerKey ~ 4,                   # NFG
          flankerResponse.keys == correctKey & SMI != 0 ~ 1,                   # correct
          flankerResponse.keys == flankerKey & flankerResponse.keys != correctKey & SMI != 0 ~ 2, # visible flanker error
          flankerResponse.keys == flankerKey & flankerResponse.keys != correctKey & SMI == 0 ~ 2, # invisible flanker error  
          flankerResponse.keys != flankerKey & flankerResponse.keys != correctKey & SMI != 0 ~ 3, # no-flanker error
          TRUE ~ 9 # error case
        ),
        
        # confidence rating: set to NA when no confidence prompt, otherwise reverse scale
        # NOTE: PsychoPy defaults to 3.5 even when no confidence judgment was made
        confidenceRating = case_when(
          is.na(confidencePrompt.started) ~ NA_real_,  # no confidence prompt = no rating
          TRUE ~ 7 - ConfidenceRating  # reverse scale for valid ratings
        ),
        
        # create trial code
        d1 = ifelse(block_condition == "social", 1, 2),
        d2 = ifelse(SMI == 0, 0, 1),
        code = (d1 * 100) + (d2 * 10) + responseType,
        
        # convert RT to numeric for final output
        flankerResponse.rt = rt_numeric
      ) %>%
      
      # remove intermediate columns and confidencePrompt.started
      select(-d1, -d2, -rt_numeric, -confidencePrompt.started, -ConfidenceRating)
  })
  
  # write clean data
  write_csv(clean_data, output_file)
  
  cat("  cleaned data saved:", nrow(clean_data), "trials →", basename(output_file), "\n")
  return(TRUE)
}