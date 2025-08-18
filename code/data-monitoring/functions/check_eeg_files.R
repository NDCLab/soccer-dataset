# ===================================================================
# EEG File Checking Functions
# ===================================================================

check_eeg_files <- function(subject_id, session = "s1_r1", filename_session = "s1_r1_e1") {
  # check EEG files for one subject
  issues <- c()
  thresholds <- get_file_size_thresholds()
  patterns <- get_file_patterns()
  
  eeg_path <- get_eeg_file_path(subject_id, session)
  
  for (pattern in patterns$eeg) {
    filename <- paste0(subject_id, gsub("\\{session\\}", filename_session, pattern))
    filepath <- file.path(eeg_path, filename)
    
    # determine threshold by file extension
    ext <- tools::file_ext(filename)
    threshold <- switch(ext,
                        "vhdr" = thresholds$vhdr_min,
                        "eeg" = thresholds$eeg_min,
                        "vmrk" = thresholds$vmrk_min,
                        0)
    
    result <- check_file_size(filepath, threshold)
    
    if (!result$exists) {
      issues <- c(issues, paste("eeg missing:", filename))
    } else if (result$status == "too_small") {
      size_desc <- if (ext == "eeg") paste(round(result$size/1e6, 1), "MB") else paste(round(result$size/1024, 1), "KB")
      issues <- c(issues, paste("eeg too small:", filename, paste0("(", size_desc, ")")))
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