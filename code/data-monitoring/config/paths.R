# ===================================================================
# Path Configuration for SocCEr Data Monitoring
# ===================================================================

# dataset root directory
get_dataset_root <- function() {
  # assumes we're in code/data-monitoring/ & dataset root is 2 levels up
  here("..", "..")
}

# get path to raw data for specific session & data type
get_raw_data_path <- function(session = "s1_r1", data_type = NULL) {
  base_path <- file.path(get_dataset_root(), "sourcedata", "raw", session)
  if (!is.null(data_type)) {
    return(file.path(base_path, data_type))
  }
  return(base_path)
}

# get path to checked data 
get_checked_data_path <- function(session = "s1_r1", data_type = NULL) {
  base_path <- file.path(get_dataset_root(), "sourcedata", "checked", session)
  if (!is.null(data_type)) {
    return(file.path(base_path, data_type))
  }
  return(base_path)
}

# get list of all subjects from raw data
get_subject_list <- function(data_type = "eeg", session = "s1_r1") {
  data_path <- get_raw_data_path(session, data_type)
  if (!dir.exists(data_path)) return(character(0))
  
  subject_folders <- list.dirs(data_path, recursive = FALSE, full.names = FALSE)
  subjects <- subject_folders[grepl("^sub-", subject_folders)]
  return(sort(subjects))
}

# get central tracker path
get_central_tracker_path <- function() {
  file.path(get_dataset_root(), "data-monitoring", "central-tracker_soccer-dataset.csv")
}

# eeg-specific paths
get_eeg_file_path <- function(subject_id, session = "s1_r1") {
  file.path(get_raw_data_path(session, "eeg"), subject_id)
}

# psychopy-specific paths
get_psychopy_file_path <- function(subject_id, session = "s1_r1") {
  file.path(get_raw_data_path(session, "psychopy"), subject_id)
}

# redcap-specific paths
get_redcap_file_path <- function(session = "s1_r1") {
  get_raw_data_path(session, "redcap")
}

# digi-specific paths
get_digi_file_path <- function(subject_id, session = "s1_r1") {
  file.path(get_raw_data_path(session, "digi"), subject_id)
}