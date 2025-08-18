# ===================================================================
# Data Copying Functions
# ===================================================================

copy_subject_data <- function(subject_id, session, config) {
  # copy all enabled data types for one subject from raw to checked
  
  cat("  Copying data for", subject_id, "...\n")
  
  # copy eeg data
  if (config$check_eeg) {
    copy_eeg_data(subject_id, session)
  }
  
  # copy psychopy data
  if (config$check_psychopy) {
    copy_psychopy_data(subject_id, session)
  }
  
  # copy digi data
  if (config$check_digi) {
    copy_digi_data(subject_id, session)
  }
  
  # copy redcap data (when enabled)
  if (config$check_redcap) {
    copy_redcap_data(subject_id, session)
  }
  
  cat("  ✓ Completed copying for", subject_id, "\n")
}

copy_eeg_data <- function(subject_id, session) {
  # copy eeg files from raw to checked
  raw_path <- get_eeg_file_path(subject_id, session)
  checked_path <- file.path(get_checked_data_path(session, "eeg"), subject_id)
  
  # create checked directory if needed
  if (!dir.exists(checked_path)) {
    dir.create(checked_path, recursive = TRUE)
  }
  
  # copy all files from raw eeg folder
  if (dir.exists(raw_path)) {
    file.copy(from = list.files(raw_path, full.names = TRUE),
              to = checked_path,
              overwrite = TRUE)
    cat("    ✓ EEG data copied\n")
  }
}

copy_psychopy_data <- function(subject_id, session) {
  # copy psychopy files from raw to checked
  raw_path <- get_psychopy_file_path(subject_id, session)
  checked_path <- file.path(get_checked_data_path(session, "psychopy"), subject_id)
  
  # create checked directory structure if needed
  if (!dir.exists(checked_path)) {
    dir.create(checked_path, recursive = TRUE)
  }
  
  # copy practice and test folders
  if (dir.exists(raw_path)) {
    # copy entire folder structure (practice/ and test/ subdirs)
    file.copy(from = raw_path,
              to = dirname(checked_path),
              recursive = TRUE,
              overwrite = TRUE)
    cat("    ✓ PsychoPy data copied\n")
  }
}

copy_digi_data <- function(subject_id, session) {
  # copy digi files from raw to checked (with special logic)
  raw_path <- get_digi_file_path(subject_id, session)
  checked_path <- file.path(get_checked_data_path(session, "digi"), subject_id)
  
  # create checked directory if needed
  if (!dir.exists(checked_path)) {
    dir.create(checked_path, recursive = TRUE)
  }
  
  if (dir.exists(raw_path)) {
    # check for no-data.txt
    no_data_file <- file.path(raw_path, "no-data.txt")
    if (file.exists(no_data_file)) {
      # copy no-data.txt to track status
      file.copy(no_data_file, checked_path, overwrite = TRUE)
      cat("    ✓ Digi no-data status copied\n")
      return()
    }
    
    # detect environment
    is_hpc <- !(.Platform$OS.type == "windows")
    
    if (is_hpc) {
      # copy .gpg files on HPC
      gpg_files <- list.files(raw_path, pattern = "\\.gpg$", full.names = TRUE)
      if (length(gpg_files) > 0) {
        file.copy(gpg_files, checked_path, overwrite = TRUE)
        cat("    ✓ Digi encrypted data copied\n")
      }
    } else {
      # on local: don't copy digi-on-hpc.txt (it stays in raw only)
      cat("    ✓ Digi data on HPC (not copied locally)\n")
    }
  }
}

copy_redcap_data <- function(subject_id, session) {
  # placeholder for redcap copying
  cat("    ✓ REDCap copying not implemented yet\n")
}