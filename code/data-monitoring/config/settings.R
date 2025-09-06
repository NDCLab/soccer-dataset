# ===================================================================
# Settings Configuration for SocCEr Data Monitoring
# ===================================================================

# file size thresholds (in bytes)
get_file_size_thresholds <- function() {
  list(
    # eeg files
    vhdr_min = 10383,              # VHDR files: at least 10.1 KB
    eeg_min = 927777240,           # EEG files: at least 906 MB 
    vmrk_min = 267003,             # VMRK files: at least 260.7 KB
    
    # psychopy practice files
    practice_csv_min = 222777,     # practice CSV: at least 217.6 KB
    practice_log_min = 2249516,    # practice LOG: at least 2196.8 KB
    practice_psydat_min = 381210,  # practice PSYDAT: at least 372.3 KB
    
    # psychopy test files
    test_csv_min = 444977,         # test CSV: at least 434.5 KB
    test_log_min = 4165431,        # test LOG: at least 4067.8 KB
    test_psydat_min = 809864       # test PSYDAT: at least 790.9 KB
  )
}

# session configuration
get_session_config <- function() {
  list(
    default_session = "s1_r1",          # for folder paths
    filename_session = "s1_r1_e1"       # for file naming
  )
}

# expected file patterns
get_file_patterns <- function() {
  list(
    eeg = c("_all_eeg_{session}.vhdr", "_all_eeg_{session}.eeg", "_all_eeg_{session}.vmrk"),
    psychopy_practice = c("_soccer-practice_psychopy_{session}.csv", 
                          "_soccer-practice_psychopy_{session}.log",
                          "_soccer-practice_psychopy_{session}.psydat"),
    psychopy_test = c("_soccer-test_psychopy_{session}.csv",
                      "_soccer-test_psychopy_{session}.log", 
                      "_soccer-test_psychopy_{session}.psydat")
  )
}

# which data types to check & copy
get_data_monitoring_config <- function() {
  list(
    check_eeg = TRUE,
    check_psychopy = TRUE,
    check_digi = TRUE,
    check_redcap = FALSE,  # disabled until implemented
    
    
    ## KNOWN PROBLEMATIC SUBJECTS
    # sub-390016: data collection incomplete
    # sub-390017: data collection incomplete
    # sub-390018: only first condition of test-phase completed
    # sub-390019: only first condition of test-phase completed
    # sub-390022: under current preregistration inadmissable (5 trials missing from EEG data, see study tracker)
    skip_subjects = c()
  )
}