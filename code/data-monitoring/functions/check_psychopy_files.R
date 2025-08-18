# ===================================================================
# PsychoPy File Checking Functions
# ===================================================================

check_psychopy_files <- function(subject_id, session = "s1_r1", filename_session = "s1_r1_e1") {
  # check psychopy files for one subject
  issues <- c()
  thresholds <- get_file_size_thresholds()
  patterns <- get_file_patterns()
  
  psychopy_path <- get_psychopy_file_path(subject_id, session)
  
  # check practice files
  practice_path <- file.path(psychopy_path, "practice")
  for (pattern in patterns$psychopy_practice) {
    filename <- paste0(subject_id, gsub("\\{session\\}", filename_session, pattern))
    filepath <- file.path(practice_path, filename)
    
    # determine threshold by file extension
    ext <- tools::file_ext(filename)
    threshold <- switch(ext,
                        "csv" = thresholds$practice_csv_min,
                        "log" = thresholds$practice_log_min,
                        "psydat" = thresholds$practice_psydat_min,
                        0)
    
    result <- check_file_size(filepath, threshold)
    
    if (!result$exists) {
      issues <- c(issues, paste("psychopy practice missing:", filename))
    } else if (result$status == "too_small") {
      size_desc <- paste(round(result$size/1024, 1), "KB")
      issues <- c(issues, paste("psychopy practice too small:", filename, paste0("(", size_desc, ")")))
    }
  }
  
  # check test files
  test_path <- file.path(psychopy_path, "test")
  for (pattern in patterns$psychopy_test) {
    filename <- paste0(subject_id, gsub("\\{session\\}", filename_session, pattern))
    filepath <- file.path(test_path, filename)
    
    # determine threshold by file extension
    ext <- tools::file_ext(filename)
    threshold <- switch(ext,
                        "csv" = thresholds$test_csv_min,
                        "log" = thresholds$test_log_min,
                        "psydat" = thresholds$test_psydat_min,
                        0)
    
    result <- check_file_size(filepath, threshold)
    
    if (!result$exists) {
      issues <- c(issues, paste("psychopy test missing:", filename))
    } else if (result$status == "too_small") {
      size_desc <- paste(round(result$size/1024, 1), "KB")
      issues <- c(issues, paste("psychopy test too small:", filename, paste0("(", size_desc, ")")))
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