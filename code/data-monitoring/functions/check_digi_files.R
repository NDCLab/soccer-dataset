# ===================================================================
# Digi File Checking Functions
# ===================================================================

check_digi_files <- function(subject_id, session = "s1_r1", filename_session = "s1_r1_e1") {
  # check digi files for one subject
  issues <- c()
  
  digi_path <- get_digi_file_path(subject_id, session)
  
  # check if digi directory exists
  if (!dir.exists(digi_path)) {
    issues <- c(issues, paste("digi directory missing for", subject_id))
    return(issues)
  }
  
  # check for no-data.txt file
  no_data_file <- file.path(digi_path, "no-data.txt")
  if (file.exists(no_data_file)) {
    # track that no data was collected (will update tracker)
    return(issues)  # no issues, but tracker should show "no-data"
  }
  
  # detect if we're on HPC or local
  is_hpc <- !(.Platform$OS.type == "windows")
  
  if (is_hpc) {
    # on HPC: expect encrypted .gpg files with correct naming
    expected_filename <- paste0(subject_id, "_all_digi_", filename_session, ".zip.gpg")
    expected_filepath <- file.path(digi_path, expected_filename)
    
    if (!file.exists(expected_filepath)) {
      issues <- c(issues, paste("digi: missing encrypted file", expected_filename, "for", subject_id))
    } else {
      # check file size (should be > 1MB for real digi data)
      result <- check_file_size(expected_filepath, 1048576)  # 1MB minimum
      if (result$status == "too_small") {
        size_desc <- paste(round(result$size/1024/1024, 1), "MB")
        issues <- c(issues, paste("digi: encrypted file too small", expected_filename, paste0("(", size_desc, ")")))
      }
    }
    
  } else {
    # on local: expect digi-on-hpc.txt file
    hpc_file <- file.path(digi_path, "digi-on-hpc.txt")
    if (!file.exists(hpc_file)) {
      issues <- c(issues, paste("digi: missing digi-on-hpc.txt for", subject_id))
    }
  }
  
  return(issues)
}

check_file_size <- function(filepath, min_size_bytes) {
  # helper function for file size checking
  if (!file.exists(filepath)) {
    return(list(exists = FALSE, size = 0, status = "missing"))
  }
  
  size <- file.size(filepath)
  if (size < min_size_bytes) {
    return(list(exists = TRUE, size = size, status = "too_small"))
  }
  
  return(list(exists = TRUE, size = size, status = "ok"))
}