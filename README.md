# Linux Lab Scripts
A collection of Bash scripts for laboratory assignments for the "System Programming and OS Administration" course.

## Lab5

## Description

In this lab a DEB package **`count-files`** was created for Debian-based systems.
The package installs a Bash script that shows statistics for a directory:
number of regular files, directories, symbolic links, files with a given extension and total size.

What was done:
- built a DEB package from the script using `debhelper`;
- added a configuration file `/etc/count-files.conf`;
- added `postinst` and `prerm` maintainer scripts;
- published the package to a PPA on Launchpad and installed it from there;
- compared the DEB and RPM packaging processes.

---

## Building the package

1. Installed the packaging tools: `build-essential`, `debhelper`, `devscripts`, `dh-make`.
2. Created the folder `count-files-1.0`, copied `count_files.sh` into it and generated the `debian/` directory with `dh_make`.
3. Filled in `debian/control` (package name, description, dependencies) and `debian/changelog` (version `1.0-1`).
4. Wrote `debian/rules` so that the script is installed as `/usr/bin/count_files`.
5. Built the package with `dpkg-buildpackage -us -uc -b` → `count-files_1.0-1_all.deb`.
6. Checked the package with `dpkg -I` and `dpkg -c`, installed it with `dpkg -i`, ran `count_files` and removed it with `apt remove`.

---

## Self-study tasks

### Configuration file

`/etc/count-files.conf` sets the default directory and the file extension to count:

```bash
TARGET_DIR="/boot"
EXTENSION="txt"
```

The script sources this file; the user can still enter another path at the prompt.
The config is installed by `debian/rules`. Since it lives in `/etc`, `debhelper` automatically marks it
as a **conffile**: local edits are preserved on upgrade.

### Maintainer scripts `postinst` and `prerm`

- **`postinst`** (`configure`): writes an entry to `/var/log/count-files.log`
  and prints a message with the current config settings.
- **`prerm`** (`remove` / `upgrade`): prints a message and logs the removal.
<img width="600" height="auto" alt="8" src="https://github.com/user-attachments/assets/66996213-c9b4-418e-9605-5902d2dbdcb3" />
<img width="600" height="auto" alt="9" src="https://github.com/user-attachments/assets/dc2e998e-8d88-4126-aa0b-7956319495f8" />


### PPA on Launchpad

1. Created a Launchpad account and a GPG key (`gpg --full-generate-key`).
2. Uploaded the key to `keyserver.ubuntu.com` and imported its fingerprint into Launchpad
   (confirmed by decrypting the verification email with `gpg -d`).
3. Created the PPA **`ppa:leonidhr/count-files`**.
4. Prepared a source package: Ubuntu series in `debian/changelog`, `.orig.tar.gz` archive,
   signed build with `debuild -S -sa -k<KEYID>`.
5. Uploaded it with `dput ppa:leonidhr/count-files count-files_1.0-1_source.changes`.

> **Issue:** `launchpad.net` and `keyserver.ubuntu.com` were unreachable from the local network.
> Solved by using the **Cloudflare WARP** VPN client.
<img width="600" height="auto" alt="15" src="https://github.com/user-attachments/assets/b94c0a48-ba32-4ce8-8197-6afbefc803b5" />

### RPM vs DEB comparison

| Aspect | DEB | RPM |
|---|---|---|
| Package description | `debian/` directory with several files | single `.spec` file |
| Build tool | `dpkg-buildpackage`, `debuild`, `debhelper` | `rpmbuild` |
| Build instructions | Makefile `debian/rules` | `%prep`, `%build`, `%install` sections |
| File list | collected automatically | declared explicitly in `%files` |
| Config files | files in `/etc` become conffiles automatically | marked with `%config(noreplace)` |
| Maintainer scripts | `preinst`, `postinst`, `prerm`, `postrm` files | `%pre`, `%post`, `%preun`, `%postun` |
| Script argument | string: `configure`, `remove`, `upgrade` | number: count of installed versions |
| Version | `upstream-revision` (`1.0-1`) | `Version` + `Release` |
| Arch-independent | `Architecture: all` | `BuildArch: noarch` |
| Package managers | `dpkg` / `apt` | `rpm` / `dnf`, `zypper` |
| Remove with config | separate `remove` and `purge` | `rpm -e` (modified configs saved as `.rpmsave`) |
| Hosted repositories | Launchpad PPA (source upload only) | Fedora COPR, openSUSE OBS |
| Linter | `lintian` | `rpmlint` |

**Conclusion:** both formats describe metadata, dependencies, files and install scripts.
RPM keeps everything in one explicit `.spec` file. DEB splits it across `debian/`,
while `debhelper` automates most of the routine work, at the cost of a stricter syntax
(TABs in `rules`, exact spacing in `changelog`).

---

## Build from source

```bash
sudo apt install build-essential debhelper devscripts
cd count-files-1.0
dpkg-buildpackage -us -uc -b
```

## Install

From the `.deb` file:
```bash
sudo apt install ./packages/count-files_1.0-1_all.deb
```

From the PPA:
```bash
sudo add-apt-repository ppa:leonidhr/count-files
sudo apt update
sudo apt install count-files
```

## Usage

```bash
count_files
# Enter the path to the directory [/boot]:
```

<img width="600" height="auto" alt="6" src="https://github.com/user-attachments/assets/dad79b06-2e2f-4ed1-841e-c88703dc5afa" />


## Remove

```bash
sudo apt remove count-files  
```

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
