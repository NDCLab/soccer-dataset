# ===================================================================
# Data Sanity Check Functions
# ===================================================================

sanity_checks <- function(subject_id) {
  # get clean file path
  clean_file <- get_clean_output_path(subject_id)
  
  # check if clean file exists
  if (!file.exists(clean_file)) {
    warning("clean file not found for ", subject_id)
    return(FALSE)
  }
  
  # read clean data
  data <- read_csv(clean_file, show_col_types = FALSE)
  
  # initialize issues list
  issues <- c()
  
  # check 1: trial count (should be EXACTLY 864)
  if (nrow(data) != 864) {
    issues <- c(issues, paste("incorrect trial count:", nrow(data), "(expected 864)"))
  }
  
  # check 2: target and flanker letters should be valid
  valid_letters <- c("P", "W", "M", "V", "B", "R")
  invalid_targets <- sum(!data$target %in% valid_letters, na.rm = TRUE)
  invalid_flankers <- sum(!data$flanker %in% valid_letters, na.rm = TRUE)
  
  if (invalid_targets > 0) {
    issues <- c(issues, paste("invalid target letters:", invalid_targets))
  }
  if (invalid_flankers > 0) {
    issues <- c(issues, paste("invalid flanker letters:", invalid_flankers))
  }
  
  # check 3: SMI values should be appropriate
  # invisible trials should have SMI = 0
  invis_wrong_smi <- sum(data$visInvis == "invis" & data$SMI != 0, na.rm = TRUE)
  if (invis_wrong_smi > 0) {
    issues <- c(issues, paste("invisible trials with SMI ≠ 0:", invis_wrong_smi))
  }
  
  # visible trials should have SMI > 0
  vis_wrong_smi <- sum(data$visInvis == "vis" & data$SMI == 0, na.rm = TRUE)
  if (vis_wrong_smi > 0) {
    issues <- c(issues, paste("visible trials with SMI = 0:", vis_wrong_smi))
  }
  
  # check 4: response types should be valid (1-4, 7-8) - flag any type 9
  valid_response_types <- c(1, 2, 3, 4, 7, 8)
  invalid_response_types <- sum(!data$responseType %in% valid_response_types, na.rm = TRUE)
  if (invalid_response_types > 0) {
    issues <- c(issues, paste("invalid response types:", invalid_response_types))
  }
  
  # specifically flag type 9 responses (indicates coding error)
  if (any(data$responseType == 9, na.rm = TRUE)) {
    type_9_count <- sum(data$responseType == 9, na.rm = TRUE)
    issues <- c(issues, paste("type 9 responses found (coding error):", type_9_count))
  }
  
  # check 5: trial codes should be valid 3-digit numbers
  invalid_codes <- sum(data$code < 100 | data$code > 299, na.rm = TRUE)
  if (invalid_codes > 0) {
    issues <- c(issues, paste("invalid trial codes:", invalid_codes))
  }
  
  # check 6: confidence ratings should be in valid range (1-6) or NA
  invalid_confidence <- sum(!is.na(data$confidenceRating) & 
                              (data$confidenceRating < 1 | data$confidenceRating > 6), na.rm = TRUE)
  if (invalid_confidence > 0) {
    issues <- c(issues, paste("confidence ratings outside 1-6 range:", invalid_confidence))
  }
  
  # check 7: confidence ratings should be NA for responseType 8 (too slow)
  confidence_when_too_slow <- sum(data$responseType == 8 & !is.na(data$confidenceRating), na.rm = TRUE)
  if (confidence_when_too_slow > 0) {
    issues <- c(issues, paste("confidence ratings present for too-slow trials:", confidence_when_too_slow))
  }
  
  # check 8: responseType 8 logic
  # missing responses should be type 8
  no_response_wrong_type <- sum(is.na(data$flankerResponse.keys) & data$responseType != 8, na.rm = TRUE)
  if (no_response_wrong_type > 0) {
    issues <- c(issues, paste("missing responses not coded as type 8:", no_response_wrong_type))
  }
  
  # check 9: block condition should be social or non-social
  invalid_conditions <- sum(!data$block_condition %in% c("social", "non-social"), na.rm = TRUE)
  if (invalid_conditions > 0) {
    issues <- c(issues, paste("invalid block conditions:", invalid_conditions))
  }
  
  # check 10: reaction times should be positive for valid responses
  negative_rts <- sum(!is.na(data$flankerResponse.rt) & data$flankerResponse.rt <= 0, na.rm = TRUE)
  if (negative_rts > 0) {
    issues <- c(issues, paste("negative or zero reaction times:", negative_rts))
  }
  
  # print results
  if (length(issues) == 0) {
    cat("  ✅ all sanity checks passed\n")
  } else {
    cat("  ⚠️  issues found:\n")
    for (issue in issues) {
      cat("    -", issue, "\n")
    }
    
    # print summary info only if issues found
    response_type_summary <- table(data$responseType, useNA = "ifany")
    condition_summary <- table(data$block_condition, useNA = "ifany")
    confidence_na_count <- sum(is.na(data$confidenceRating))
    
    cat("  response types:", paste(names(response_type_summary), "=", response_type_summary, collapse = ", "), "\n")
    cat("  conditions:", paste(names(condition_summary), "=", condition_summary, collapse = ", "), "\n")
    cat("  confidence NAs:", confidence_na_count, "out of", nrow(data), "\n")
  }
  
  return(length(issues) == 0)
}