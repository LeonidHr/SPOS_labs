# Linux Lab Scripts
A collection of Bash scripts for laboratory assignments for the "System Programming and OS Administration" course.

## Lab8

## Description

Jenkins Pipeline for building, testing and publishing `count-files` packages. The pipeline is described in the `Jenkinsfile` in the repository root and runs in the Jenkins environment from Lab7 (job `count-files-pipeline`, *Pipeline script from SCM*, branch `*/main`).

Stages run in Docker containers on the built-in node, so every stage gets a clean environment of the needed distribution:

```
Checkout -> ShellCheck -> Test Script -> Build RPM | Build DEB -> Test RPM | Test DEB -> Publish RPM | Publish DEB -> Tag Release
```

- **Checkout** - clone the repository from GitHub
- **ShellCheck** - static analysis of `count_files.sh`
- **Test Script** - `bash -n` and a test run of the script
- **Build RPM** - `rpmbuild` in `fedora:latest`
- **Build DEB** - `dpkg-buildpackage` in `ubuntu:latest`
- **Test RPM / DEB Installation** - install the package in `oraclelinux:8` / `ubuntu:latest`, run `count_files`, remove the package
- **Publish** - copy packages to YUM and APT repositories
- **Tag Release** - create git tag `jenkins-v<version>` on GitHub
- **post** - archive artifacts, send email, clean workspace

Changes compared to the lab instructions:

- `agent { label 'built-in' }` instead of `agent any` - with `agent any` docker stages ran on `agent-python`, which has no Docker (`docker: not found`, build #1)
- `reuseNode true` in docker stages - all stages share one workspace, so built packages are visible in the test stages
- `group_add` with the GID of `/var/run/docker.sock` added to `jenkins-master` in `lab7/docker-compose.yml` - access to Docker for the `jenkins` user
- `PACKAGE_VERSION = '2.0'` and `count-files.conf`, `count_files.1` are copied - the spec file from Lab4 is version 2.0
- `cleanup { cleanWs() }` instead of `always` - `always` runs before `success`, so `archiveArtifacts` would find an empty workspace
- `devscripts` removed from DEB build dependencies - not needed for `dpkg-buildpackage`, but added ~370 packages (build time 57 min -> 10 min)

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/7b0a5e3d-3c44-4906-931c-1915c6de50e3" />

## Usage

Run the pipeline: **Jenkins -> count-files-pipeline -> Build Now**

View stages: **Open Blue Ocean** or **Stages**

Download packages: **Build -> Build Artifacts**

Install from the repository (Fedora):

```
cat > /etc/yum.repos.d/count-files.repo << EOF
[count-files]
name=count-files
baseurl=https://localhost/repo/rpm
enabled=1
gpgcheck=0
sslverify=0
EOF

dnf --disablerepo="*" --enablerepo=count-files install -y count-files
count_files
```

APT repository: `https://localhost/repo/deb/`

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/cfa4861b-be10-4ac9-844f-450a1eedb974" />

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/06813a49-30ed-4cf8-bb5f-fd1e48531fcf" />


## Completed tasks

### ShellCheck static analysis

- Stage `ShellCheck` runs in the `koalaman/shellcheck-alpine:stable` container before tests
- Full report is saved to `shellcheck-report.txt` and archived with the packages
- `shellcheck -S error` stops the pipeline if the script has errors
- Report is empty (0 B) - no warnings for `count_files.sh`

### Parallel build of RPM and DEB

- `Build RPM` and `Build DEB` run in a `parallel` block, as well as the test and publish stages
- `failFast true` - if one branch fails, the other one is stopped
- Both branches use the same workspace (`reuseNode true`) and create different files

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/ef93268d-1b19-4d64-b915-656c95ff3f86" />


### Email notifications

- Plugin Email Extension, Gmail SMTP (`smtp.gmail.com:465`, SSL, app password stored in Jenkins credentials)
- `post -> success` - email with the package version and links to the build and artifacts
- `post -> failure` - email with the console log attached
- Recipient is taken from Jenkins settings (`$DEFAULT_RECIPIENTS`), not stored in the repository

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/472cf7a6-ce8b-445a-8c9c-cb9e08e0c521" />


### Publishing packages to a repository

- Repositories are stored in `/var/jenkins_home/repo` and served by nginx from Lab7 at `https://localhost/repo/`
- RPM: packages are copied to `repo/rpm`, metadata is created with `createrepo_c`
- DEB: packages are copied to `repo/deb`, `Packages`, `Packages.gz` and `Release` are created with `apt-ftparchive`
- Package installs from the repository with `dnf` in a clean Fedora container

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/8ad80569-d450-4b52-937e-c3d99e97aa70" />

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/d2695ac0-f491-41b6-8cc1-2d84d4150f7d" />

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/af32d801-590e-4b1c-95e6-9144eaf2738f" />


### Tagging and versioning

- Package version is `<version>-<build number>`: `PACKAGE_VERSION` + `BUILD_NUMBER` (e.g. `2.0-4`)
- RPM: `Version` and `Release` in the spec file are set with `sed` -> `count-files-2.0-4.fc45.noarch.rpm`
- DEB: version in `debian/changelog` is set with `sed` -> `count-files_2.0-4_all.deb`
- Build name in Jenkins: `#4 v2.0-4`
- Stage `Tag Release` creates tag `jenkins-v2.0-4` and pushes it to GitHub, the GitHub token is stored in Jenkins credentials (`github-creds`)
- Prefix `jenkins-` does not trigger the release workflow from Lab6 (tags `v*`)

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/577392f0-6dba-4c15-a006-ab4513aed0c4" />

<img width="800" height="auto" alt="image" src="https://github.com/user-attachments/assets/a4d16c1f-944d-41d9-bac7-18e03efb644b" />


## Lab7

## Description

Docker environment for Jenkins CI/CD. Jenkins master and build agents run in separate containers described in `lab7/docker-compose.yml` and connected by the bridge network `jenkins-net`.

- **jenkins-master** - image based on `jenkins/jenkins:lts` with Docker CLI and plugins `git`, `workflow-aggregator`, `docker-workflow`, `blueocean`; ports `8080` (web UI) and `50000` (agents)
- **jenkins-agent** (`agent-1`) - image based on `jenkins/inbound-agent` with `build-essential` and `rpm` for building packages
- **jenkins-agent-python** (`agent-python`) - `python3`, `pip`, `venv`
- **jenkins-agent-node** (`agent-node`) - `nodejs`, `npm`
- **jenkins-nginx** - reverse proxy with SSL in front of Jenkins

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/1399856e-f644-41ed-aa0e-4edd38b82232" />

## Usage

Start the environment:

```
cd lab7
docker compose build
docker compose up -d
docker compose ps
```

Open Jenkins: **https://localhost**

Initial admin password (first start only):

```
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
```

Connect agents: **Manage Jenkins -> Nodes -> New Node** (`agent-1`, `agent-python`, `agent-node`, remote root directory `/home/jenkins/agent`, launch by connecting to the controller), then put the secrets into `.env`:

```
AGENT1_SECRET=...
AGENT_PYTHON_SECRET=...
AGENT_NODE_SECRET=...
```

```
docker compose up -d
```

Stop the environment:

```
docker compose down
```

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/0c161a0e-7833-4e65-9728-b61d224d433a" />

## Completed tasks

### Additional agents with different tools

- Two more agents added: `agent-python` (Python 3.13) and `agent-node` (Node.js 20), besides `agent-1` (RPM, gcc)
- Each agent has its own Dockerfile, its own node in Jenkins and labels (`packaging`, `python`, `node`)
- Agent secrets are stored in `.env`, which is excluded from git

```
docker exec jenkins-agent rpm --version
docker exec jenkins-agent-python python3 --version
docker exec jenkins-agent-node node --version
```

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/5e980ce3-3396-47d6-8b27-7b061897dfbc" />


<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/7caad5c1-0478-4a8f-bb93-688b9a17d82e" />


### Jenkins data on the host

- Named volume `jenkins_home` replaced with bind mount `./jenkins_home:/var/jenkins_home`
- Existing data was copied from the volume to the host directory, owner UID `1000` (user `jenkins` in the container)
- Configuration, users, plugins and nodes stay after `docker compose down` and are available as regular files

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/ad137153-7d59-4652-8cd4-51cd5d899352" />


### Automatic backup

- `backup.sh` archives `jenkins_home` to `backups/jenkins_backup_<date>.tar.gz`
- `workspace`, `caches`, `war` and `logs` are excluded, only the last 3 archives are kept
- The archive is created in a temporary container with read-only access to the data
- Started daily by cron:

```
0 21 * * * /home/leonidhr/projects/linux-lab-scripts/lab7/backup.sh >> /home/leonidhr/projects/linux-lab-scripts/lab7/backups/backup.log 2>&1
```

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/dc18deff-acab-41dd-8cbe-09782d02c540" />

### SSL for Jenkins

- Self-signed certificate created with `openssl` (`CN=localhost`, valid for 1 year)
- `nginx` container works as a reverse proxy: `https://localhost` (443) -> `jenkins-master:8080`
- HTTP requests (80) are redirected to HTTPS with `301 Moved Permanently`
- `X-Forwarded-Proto` header tells Jenkins that it works over HTTPS, Jenkins URL is set to `https://localhost/`
- Private key `nginx/certs/jenkins.key` is excluded from git

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/afd77066-6877-409e-b96e-77b0ef1cda67" />

<img width="600" height="auto" alt="image" src="https://github.com/user-attachments/assets/a0e2fbfa-dc68-4282-83e0-5b94d15ecde1" />

## Lab6

## Description

Automation of building RPM and DEB packages for the `count-files` script with GitHub Actions (CI/CD).

The workflow `.github/workflows/build-packages.yml` starts on every push or pull request to `main`, and can also be started manually (`workflow_dispatch`). It tests the script, builds packages for several distribution versions in parallel, installs each package to check that it works and uploads the packages as artifacts. When a tag `v*` is pushed, a GitHub Release with all packages is created automatically.

Packaging files are stored in the repository:

```
.github/workflows/build-packages.yml   
packaging/rpm/count-files.spec         
packaging/deb/debian/                  
count_files.sh, count-files.conf, count_files.1
```

Workflow structure:

```
test -> build-rpm (Fedora 43, 44, 45) + build-deb (Ubuntu 22.04, 24.04) -> release (only for v* tags)
```

<img width="600" height="auto" alt="Workflow graph" src="https://github.com/user-attachments/assets/3878fad7-5947-4cde-8337-342074bf4833" />

## Usage

Run the workflow manually: **Actions -> Build Packages -> Run workflow**

Download packages: **Actions -> run -> Artifacts** or **Releases -> v2.0.0 -> Assets**

Create a release:

```
git tag v2.0.0
git push origin v2.0.0
```

Install and run:

```
sudo dnf install ./count-files-2.0-1.fc45.noarch.rpm
sudo apt install ./count-files_1.0-1_all_ubuntu24.04.deb
count_files /etc
```

<img width="600" height="auto" alt="Workflow runs" src="https://github.com/user-attachments/assets/6a5199d3-5e2b-457e-abf9-4c32a183dfca" />

## Completed tasks

### Building packages

- **RPM** - built in a `fedora` container: `rpm-build` and `rpmdevtools` are installed, sources (`count_files.sh`, `count-files.conf`, `count_files.1`) are packed into `count-files-2.0.tar.gz`, the package is built with `rpmbuild -ba`
- **DEB** - script, config file and `debian/` directory are copied to the build directory, the package is built with `dpkg-buildpackage -us -uc -b`
- Built packages are uploaded with `actions/upload-artifact`

<img width="600" height="auto" alt="Basic workflow run" src="https://github.com/user-attachments/assets/53381818-1626-4157-a414-79c5b97f27f4" />

<img width="600" height="auto" alt="build-rpm steps" src="https://github.com/user-attachments/assets/c9abd1aa-9726-45d1-b8f3-e7d3d4cad542" />

### Testing job

- Separate job `test` runs first, builds start only after it succeeds (`needs: test`)
- `bash -n` - syntax check, `shellcheck` - static analysis
- Functional test - the script is run on a directory with 3 files and the output is checked
- Each build job installs the built package (`dnf install` / `apt-get install`) and runs `count_files`

### Releases

- Job `release` runs only for tags `v*` and only after all builds succeeded
- All artifacts are downloaded with `actions/download-artifact` and attached to a GitHub Release by `softprops/action-gh-release`
- Release notes are generated automatically

<img width="600" height="auto" alt="Release v2.0.0" src="https://github.com/user-attachments/assets/c80c3e38-d058-4ccd-b63d-d8fdf4a4de43" />

### Build matrix

- `strategy.matrix` builds RPM for Fedora 43, 44, 45 and DEB for Ubuntu 22.04, 24.04 in parallel
- `fail-fast: false` - a failure on one version does not cancel the others
- Artifact names contain the distribution version, DEB files get an `_ubuntuXX.XX` suffix so they do not overwrite each other in the release

### Caching

- `dnf` and `apt` packages are cached with `actions/cache`
- Docker images delete downloaded packages by default, so `keepcache=True` (dnf) and `Keep-Downloaded-Packages` (apt) are enabled first
- Cache key contains the distribution version and the hash of the spec/control file
- On the second run the cache (~115 MB) is restored in less than a second

<img width="600" height="auto" alt="Cache restored" src="https://github.com/user-attachments/assets/c62b3329-dada-412e-a435-18157f46aa29" />

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
