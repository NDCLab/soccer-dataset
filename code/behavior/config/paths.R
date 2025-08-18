# ===================================================================
# Path Configuration for SocCEr Dataset
# ===================================================================

# dataset root directory (adjust if needed)
get_dataset_root <- function() {
  # assumes we're in code/behavior/ & dataset root is 2 levels up
  here("..", "..")
}

# get path to checked data
get_checked_data_path <- function() {
  file.path(get_dataset_root(), "sourcedata", "checked", "s1_r1", "psychopy")
}

# get list of all subjects
get_subject_list <- function() {
  data_path <- get_checked_data_path()
  subject_folders <- list.dirs(data_path, recursive = FALSE, full.names = FALSE)
  subjects <- subject_folders[grepl("^sub-", subject_folders)]
  return(sort(subjects))
}

# get path to subject's test csv file
get_subject_test_csv <- function(subject_id) {
  data_path <- get_checked_data_path()
  csv_file <- paste0(subject_id, "_soccer-test_psychopy_s1_r1_e1.csv")
  file.path(data_path, subject_id, "test", csv_file)
}

# get path for clean output file
get_clean_output_path <- function(subject_id) {
  data_path <- get_checked_data_path()
  clean_file <- paste0(subject_id, "_soccer-test_psychopy_s1_r1_e1_clean.csv")
  file.path(data_path, subject_id, "test", clean_file)
}