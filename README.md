# Linux Lab Scripts
A collection of Bash scripts for laboratory assignments for the "System Programming and OS Administration" course.

## Lab4

## Description

This laboratory work demonstrates how to create, build, install, and manage an RPM package on a Linux system.

The package contains a Bash script called `count_files`, which analyzes a specified directory and displays statistics about its contents.

The script provides information about:

- the number of regular files;
- the number of directories;
- the number of symbolic links;
- the number of files with a specified extension;
- the total size of files in kilobytes.

## Version 2.0

Version 2.0 introduces several additional features:

- a configuration file for storing default settings;
- a manual page for the `count_files` command;
- `%pre` script for actions performed before package installation;
- `%post` script for actions performed after package installation;
- configurable directory and file extension.

## Configuration
The configuration file is installed to: `/etc/count-files.conf`

Example:
```bash
TARGET_DIR="/boot"
EXTENSION="txt"
```

## Building the Package
The RPM package can be built using:
```bash
rpmbuild -ba ~/rpmbuild/SPECS/count-files.spec
```

After a successful build, the binary RPM package is located in:
`~/rpmbuild/RPMS/noarch/`

<img width="600" height="auto" alt="1" src="https://github.com/user-attachments/assets/5e024914-ddc6-4f31-af88-03ecf6615a40" />


## Installation
The package can be installed using:
```bash
sudo rpm -ivh --nodeps ~/rpmbuild/RPMS/noarch/count-files-2.0-1.noarch.rpm
```
The --nodeps option was used because Lubuntu is based on Debian and manages packages with apt/dpkg. Therefore, RPM cannot recognize dependencies installed through apt and may incorrectly report them as missing.

## Running the Program
After installation, run:
``` bash
count_files
```

<img width="600" height="auto" alt="6" src="https://github.com/user-attachments/assets/72372ac7-9c0e-4662-90cf-12d3439f8789" />


The program will ask for the directory to analyze. Press Enter to use the default directory from the configuration file.

## Manual Page
The package includes a manual page.
To view it, use:
```bash
man count_files
```

<img width="600" height="auto" alt="man file" src="https://github.com/user-attachments/assets/7886f12b-8b3d-48ff-a937-e8a1a635ed12" />

## Lab3 - lab2
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

<img width="400" height="auto" alt="Снимок экрана 2026-09-22 001352" src="https://github.com/user-attachments/assets/95c6bae3-dd8f-41be-ba52-aab0af18a94f" />

## GitHub Actions
Main verification command:
```bash
bash -n count_files.sh
```

## Author
Leonid Khrystenok, student of group PI-241
