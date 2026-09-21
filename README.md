# Linux Lab Scripts
A collection of Bash scripts for laboratory assignments for the "System Programming and OS Administration" course.

## Contents
- `count_files.sh` - script for counting files and files sizes in /etc
- `.github/workflows/bash-check.yml` - Workflow file for automated checks

## Using
```bash
./count_files.sh
```

## Script Realization
- Implemented file counting for a specified extension.
- Added the ability to pass the directory path via the command line.
- Implemented recursive file search in subdirectories.
- Added calculation of the total size of found files in kilobytes.

## GitHub Actions
Main verification command:
```bash
bash -n count_files.sh
```

## Author
Leonid Khrystenok, student of group PI-241
