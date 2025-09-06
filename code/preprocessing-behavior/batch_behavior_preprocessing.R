# ===================================================================
# SocCEr Behavioral Data Processing - Main Script
# ===================================================================

# load required libraries
library(here)       # for robust file paths
library(readr)      # for reading CSV files
library(dplyr)      # for data manipulation
library(stringr)    # for string operations
library(tidyr)      # for fill() function

# load configuration & functions
source(here("config", "paths.R"))
source(here("functions", "clean_csv.R"))
source(here("functions", "sanity_checks.R"))

# main processing workflow
cat("Starting SocCEr behavioral data processing...\n")

# get list of subjects to process
subjects <- get_subject_list()
cat("Found", length(subjects), "subjects to process\n")

# process each subject
for (subject_id in subjects) {
  cat("Processing", subject_id, "...\n")
  
  # clean data
  clean_csv(subject_id)
  
  # run sanity checks
  sanity_checks(subject_id)
  
  cat("Completed", subject_id, "\n")
}

cat("All subjects processed successfully!\n")