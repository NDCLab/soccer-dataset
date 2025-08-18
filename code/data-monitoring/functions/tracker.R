# ===================================================================
# Central Tracker Functions
# ===================================================================

create_central_tracker <- function() {
  # create central tracker CSV if it doesn't exist
  tracker_path <- get_central_tracker_path()
  
  if (!file.exists(tracker_path)) {
    cat("Creating central tracker at:", tracker_path, "\n")
    
    # get all subjects
    all_subjects <- get_subject_list("eeg", get_session_config()$default_session)
    
    # create initial tracker with basic columns
    tracker <- data.frame(
      id = all_subjects,
      eeg_s1_r1_e1 = 0,                    # 0=missing, 1=present
      psychopy_practice_s1_r1_e1 = 0,
      psychopy_test_s1_r1_e1 = 0,
      digi_s1_r1_e1 = 0,                   # 0=missing, 1=present, 2=no-data
      redcap_s1_r1_e1 = 0,
      data_checked = as.character(Sys.Date()),
      stringsAsFactors = FALSE
    )
    
    # create directory if needed
    dir.create(dirname(tracker_path), recursive = TRUE, showWarnings = FALSE)
    
    # save tracker
    write_csv(tracker, tracker_path)
    cat("✓ Central tracker created with", nrow(tracker), "subjects\n")
  } else {
    cat("Central tracker already exists\n")
  }
}

update_tracker <- function(subject_id, data_type, status) {
  # update tracker with file check results
  tracker_path <- get_central_tracker_path()
  
  if (!file.exists(tracker_path)) {
    create_central_tracker()
  }
  
  # read tracker
  tracker <- read_csv(tracker_path, show_col_types = FALSE)
  
  # find subject row
  subject_row <- which(tracker$id == subject_id)
  if (length(subject_row) == 0) {
    # add new subject if not found
    new_row <- data.frame(
      id = subject_id,
      eeg_s1_r1_e1 = 0,
      psychopy_practice_s1_r1_e1 = 0,
      psychopy_test_s1_r1_e1 = 0,
      digi_s1_r1_e1 = 0,
      redcap_s1_r1_e1 = 0,
      data_checked = as.character(Sys.Date()),
      stringsAsFactors = FALSE
    )
    tracker <- rbind(tracker, new_row)
    subject_row <- nrow(tracker)
  }
  
  # update specific data type
  column_name <- paste0(data_type, "_s1_r1_e1")
  if (column_name %in% names(tracker)) {
    tracker[subject_row, column_name] <- status
    tracker[subject_row, "data_checked"] <- Sys.Date()  # remove as.character()
  }
  
  # save updated tracker
  write_csv(tracker, tracker_path)
}

get_tracker_summary <- function() {
  # print summary of central tracker
  tracker_path <- get_central_tracker_path()
  
  if (!file.exists(tracker_path)) {
    cat("No central tracker found\n")
    return()
  }
  
  tracker <- read_csv(tracker_path, show_col_types = FALSE)
  
  cat("\n=== CENTRAL TRACKER SUMMARY ===\n")
  cat("Total subjects:", nrow(tracker), "\n")
  
  # count by data type
  data_cols <- c("eeg_s1_r1_e1", "psychopy_practice_s1_r1_e1", 
                 "psychopy_test_s1_r1_e1", "digi_s1_r1_e1", "redcap_s1_r1_e1")
  
  for (col in data_cols) {
    if (col %in% names(tracker)) {
      present <- sum(tracker[[col]] == 1, na.rm = TRUE)
      cat(col, ":", present, "/", nrow(tracker), "subjects\n")
    }
  }
  
  cat("Last updated:", max(tracker$data_checked, na.rm = TRUE), "\n")
}