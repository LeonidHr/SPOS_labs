Name:           count-files
Version:        2.0
Release:        1%{?dist}
Summary:        Script to count regular files in specified directory

License:        MIT
URL:            https://github.com/LeonidHr/SPOS_labs
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       bash
Requires:       coreutils
Requires:       findutils

%description
A Bash script that analyzes a directory and displays statistics about its contents.
It counts files, directories, symbolic links, files with a specified extension, and total size.

%prep
%setup -q

%pre
if [ ! -d /etc/count-files ]; then
    mkdir -p /etc/count-files
fi

if [ -f /etc/count-files.conf ] && [ ! -f /etc/count-files.conf.backup ]; then
    cp /etc/count-files.conf /etc/count-files.conf.backup
fi

exit 0

%install
mkdir -p %{buildroot}%{_bindir}
install -m 755 count_files.sh %{buildroot}%{_bindir}/count_files

mkdir -p %{buildroot}%{_sysconfdir}
install -m 644 count-files.conf %{buildroot}%{_sysconfdir}/count-files.conf

mkdir -p %{buildroot}%{_mandir}/man1
install -m 644 count_files.1 %{buildroot}%{_mandir}/man1/count_files.1

%post
if command -v mandb >/dev/null 2>&1; then
    mandb -q
fi

echo "count-files 2.0 has been installed."
echo "Use 'count_files --help' for usage information."

exit 0

%files
%{_bindir}/count_files
%config(noreplace) %{_sysconfdir}/count-files.conf
%{_mandir}/man1/count_files.1*

%changelog
* Wed Oct 07 2026 Leonid Khrystenok <hristenokleonid@gmail.com> - 2.0-1
- Added man page
- Added configuration file
- Added pre-install and post-install scripts
- Added configurable directory and file extension
