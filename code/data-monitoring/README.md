# SocCEr Data Monitoring

Automated data quality checking and file management for the SocCEr dataset.

## Overview

This R project provides automated monitoring of raw data files, validates file integrity, and copies verified data to the checked folder. It maintains a central tracker CSV with the status of all subjects' data.

## Structure

```
code/data-monitoring/
├── main.R                     # Main script - run this
├── README.md                  # This file
├── data-monitoring.Rproj      # R project file
├── config/
│   ├── paths.R                # Path configuration  
│   └── settings.R             # File size thresholds & settings
└── functions/
    ├── check_eeg_files.R      # EEG file validation
    ├── check_psychopy_files.R # PsychoPy file validation
    ├── check_digi_files.R     # Digi file validation
    ├── check_redcap_files.R   # REDCap validation (placeholder)
    ├── copy_data.R            # File copying functions
    └── tracker.R              # Central tracker management
```

## Quick Start

1. **open R project**: `data-monitoring.Rproj`
2. **configure settings** (optional): `config/settings.R`
3. **run monitoring**: execute `main.R`

## Detailed Usage

### Configuration

Edit `config/settings.R` to customize:

```r
# Enable/disable data types
check_eeg = TRUE
check_psychopy = TRUE
check_digi = TRUE
check_redcap = FALSE

# Skip problematic subjects
skip_subjects = c("sub-390022")
```

### Running the Monitor

```r
# open & run main.R
```

### Expected Output

```
Starting SocCEr data monitoring...
Creating central tracker at: ../../data-monitoring/central-tracker_soccer-dataset.csv
Found 25 total subjects, 24 to process
Skipping: sub-390022

Checking sub-390001 ...
✓ sub-390001 passed all checks - copying data...
  Copying data for sub-390001 ...
    ✓ EEG data copied
    ✓ PsychoPy data copied
    ✓ Digi no-data status copied

=== CENTRAL TRACKER SUMMARY ===
Total subjects: 25
eeg_s1_r1_e1 : 20 / 25 subjects
psychopy_practice_s1_r1_e1 : 22 / 25 subjects
psychopy_test_s1_r1_e1 : 19 / 25 subjects
digi_s1_r1_e1 : 25 / 25 subjects
```

## File Checking Logic

### EEG Files
- **Location**: `sourcedata/raw/s1_r1/eeg/sub-XXXXXX/`
- **Expected files**: 
  - `sub-XXXXXX_all_eeg_s1_r1_e1.vhdr` (≥10 KB)
  - `sub-XXXXXX_all_eeg_s1_r1_e1.eeg` (≥906 MB)  
  - `sub-XXXXXX_all_eeg_s1_r1_e1.vmrk` (≥260 KB)

### PsychoPy Files
- **Location**: `sourcedata/raw/s1_r1/psychopy/sub-XXXXXX/`
- **Expected structure**:
  ```
  practice/
  ├── sub-XXXXXX_soccer-practice_psychopy_s1_r1_e1.csv (≥217 KB)
  ├── sub-XXXXXX_soccer-practice_psychopy_s1_r1_e1.log (≥2196 KB)
  └── sub-XXXXXX_soccer-practice_psychopy_s1_r1_e1.psydat (≥372 KB)
  test/
  ├── sub-XXXXXX_soccer-test_psychopy_s1_r1_e1.csv (≥434 KB)
  ├── sub-XXXXXX_soccer-test_psychopy_s1_r1_e1.log (≥4067 KB)
  └── sub-XXXXXX_soccer-test_psychopy_s1_r1_e1.psydat (≥790 KB)
  ```

### Digi Files
- **Location**: `sourcedata/raw/s1_r1/digi/sub-XXXXXX/`
- **Local environment**: Expects `digi-on-hpc.txt` (not copied)
- **HPC environment**: Expects `sub-XXXXXX_all_digi_s1_r1_e1.zip.gpg` (≥1 MB)
- **No data collected**: `no-data.txt` (copied to track status)

### REDCap Files
- **Status**: Placeholder - not implemented yet
- **Location**: `sourcedata/raw/s1_r1/redcap/`

## Environment Support

### Local (Windows)
- uses relative paths via `here()` package
- expects `digi-on-hpc.txt` status files for digi data
- runs interactively in RStudio

### HPC (Linux)
- automatically detected via `.Platform$OS.type`
- handles encrypted `.gpg` files for digi data  
- same code, different file handling logic

## Output Files

### Central Tracker
- **Location**: `data-monitoring/central-tracker_soccer-dataset.csv`
- **Columns**:
  - `id`: subject identifier
  - `eeg_s1_r1_e1`: EEG data status (0=missing, 1=present)
  - `psychopy_practice_s1_r1_e1`: practice data status
  - `psychopy_test_s1_r1_e1`: test data status  
  - `digi_s1_r1_e1`: digi data status (0=missing, 1=present, 2=no-data)
  - `redcap_s1_r1_e1`: REDCap status (placeholder)
  - `data_checked`: last check date

### Checked Data
- **Location**: `sourcedata/checked/s1_r1/`
- **Structure**: mirrors raw data structure
- **Content**: only files that passed all validation checks

## Troubleshooting

### Common Issues

**"File not found" errors**
- check that you're running from the correct R project
- verify raw data exists in expected locations
- check subject naming conventions

**"Too small" file warnings**
- files exist but are smaller than expected thresholds
- may indicate incomplete data collection or transfer issues
- review thresholds in `config/settings.R`

**Skipped subjects not working**
- ensure subject IDs in `skip_subjects` match exactly (e.g., "sub-390022")
- check for typos in subject ID format

### Getting Help

1. **Check the console output** for specific error messages
2. **Review the central tracker CSV** for subject-by-subject status
3. **Verify file paths** using the path functions:
   ```r
   source("config/paths.R")
   get_dataset_root()
   get_raw_data_path("s1_r1", "eeg")
   ```

## Dependencies

- **R packages**: `here`, `readr`, `dplyr`
- **System**: works on Windows (local) and Linux (HPC)
- **Data structure**: expects BIDS-like organization

## Version History

- **v1.0**: initial implementation with EEG, PsychoPy, and Digi checking
- **v1.1**: added central tracker functionality
- **v1.2**: added environment detection for local vs HPC usage

---

**Project**: SocCEr Dataset (NDCLab & KU Eichstätt-Ingolstadt)  
**Author**: Marlene Buch  
**Last updated**: August 2025