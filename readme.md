# FreeBSD
Installation template for FreeBSD 13.

<!--
## Distribution Select

```
[ ] base-dbg
[ ] kernel-dbg
[ ] lib32-dbg
[ ] lib32
[ ] ports
[ ] src
[ ] tests
```

## Partitioning

```
Auto (ZFS)
Pool Type/Disks: stripe: 1 disks
Partition Scheme: GPT (UEFI)
>>> Install
```

## System Configuration

```
[ ] local_unbound
[*] sshd
[ ] moused
[ ] ntpdate
[*] ntpd
[*] powerd
[ ] dumpdev
```

## System Hardening

```
[*] 0 hide_uids
[*] 1 hide_gids
[*] 2 hide_jail
[*] 3 read_msgbuf
[ ] 4 proc_debug
[ ] 5 random_pid
[*] 6 clear_tmp
[*] 7 disable_syslogd
[*] 8 disable_sendmail
[*] 9 secure_console
[ ] 10 disable_ddtrace
```

**Manual Configuration**

```sh
zfs create zroot/usr/obj
zfs rename zroot/usr/home zroot/home
zfs set mountpoint=/home zroot/home
rm -f /home
exit
```
-->

## System Setup
Configure system.

```sh
printf "fdesc\t\t\t/dev/fd\t\tfdescfs\trw\t\t0\t0\n" >> /etc/fstab
printf "proc\t\t\t/proc\t\tprocfs\trw\t\t0\t0\n" >> /etc/fstab

pkg install curl

set backup=https://raw.githubusercontent.com/qis/freebsd/master

curl ${backup}/root/.cshrc -o /root/.cshrc
curl ${backup}/root/.tmux.conf -o /root/.tmux.conf
curl ${backup}/root/.gitconfig -o /root/.gitconfig

curl ${backup}/boot/loader.conf -o /boot/loader.conf

curl ${backup}/etc/ssh/sshd_config -o /etc/ssh/sshd_config
curl ${backup}/etc/devfs.conf -o /etc/devfs.conf
curl ${backup}/etc/sysctl.conf -o /etc/sysctl.conf
curl ${backup}/etc/ntp.conf -o /etc/ntp.conf

curl ${backup}/etc/mergemaster.rc -o /etc/mergemaster.rc
curl ${backup}/etc/make.conf -o /etc/make.conf
curl ${backup}/etc/src.conf -o /etc/src.conf

curl ${backup}/home/qis/.cshrc -o /home/qis/.cshrc
curl ${backup}/home/qis/.tmux.conf -o /home/qis/.tmux.conf
curl ${backup}/home/qis/.gitconfig -o /home/qis/.gitconfig

chown qis:qis /home/qis/{.cshrc,.tmux.conf,.gitconfig}
rm -f /home/qis/{.login,.login_conf,.mail_aliases,.mailrc,.profile,.rhosts,.shrc}
rm -f /root/{.k5login,.login,.profile}

tee /etc/rc.conf >/dev/null <<EOF
# System
dumpdev="NO"
keyrate="fast"
syslogd_flags="-ssC"
clear_tmp_enable="YES"
hostname="build.xiphos.de"
powerd_enable="YES"
zfs_enable="YES"

# Sendmail
sendmail_enable="NONE"
sendmail_submit_enable="NO"
sendmail_outbound_enable="NO"
sendmail_msp_queue_enable="NO"

# Network
ifconfig_hn0="DHCP"
#ifconfig_hn0="inet 10.0.0.11 netmask 255.255.255.0"
#defaultrouter="10.0.0.1"

# Services
sshd_enable="YES"
ntpd_enable="YES"
EOF

# Edit CPUTYPE.
vi /etc/make.conf

reboot
```

## System Update
Update `RELEASE`.

```sh
freebsd-update fetch
freebsd-update install
```

Update `STABLE` and `CURRENT`.

```sh
pkg install git

# For FreeBSD STABLE.
git clone https://git.freebsd.org/src.git --branch stable/`freebsd-version -k | cut -d. -f1` /usr/src

# For FreeBSD CURRENT.
git clone https://git.freebsd.org/src.git /usr/src

cd /usr/src
make -j7 buildworld kernel KERNCONF=GENERIC-NODEBUG && reboot

cd /usr/src
make installworld
```

Merge configuration files.

```sh
mergemaster -Ui
make check-old       # yes | make delete-old
make check-old-libs  # yes | make delete-old-libs
make check-old-dirs  # yes | make delete-old-dirs
reboot
```

<!--
Create system image.

```sh
cd /usr/src
make -j7 buildworld buildkernel KERNCONF=GENERIC-NODEBUG \
  MAKE_CONF=/etc/make.conf SRC_CONF=/etc/src.conf
cd release
make cdrom KERNCONF=GENERIC-NODEBUG \
  MAKE_CONF=/etc/make.conf SRC_CONF=/etc/src.conf \
  NODOC=yes NOPORTS=yes NOSRC=yes
xz disc1.iso
```
-->

## Packages
Install packages.

```sh
pkg install htop tmux tree ca_root_nss sudo wget neovim
```

Update packages.

```sh
pkg update
pkg upgrade
```

## Ports
Install ports.

```sh
portsnap fetch
portsnap extract
cd /usr/ports/ports-mgmt/portmaster && make install clean distclean
portmaster -D sysutils/{htop,tmux,tree} security/{ca_root_nss,sudo} ftp/wget editors/neovim
portmaster --clean-distfiles
```

Update ports.

```sh
portsnap fetch update
portmaster -L
portmaster -aD
```

## `neovim`
Create [nvim(1)](https://www.freebsd.org/cgi/man.cgi?query=nvim) symlink.

```sh
ln -s /usr/local/bin/nvim /usr/local/bin/vim
```

## `sudo`
Configure [sudo(1)](https://www.freebsd.org/cgi/man.cgi?query=sudo).

`EDITOR=vim visudo`

```sudo
# FreeBSD pkg and fetch.
Defaults env_keep += "PKG_CACHEDIR PKG_DBDIR FTP_PASSIVE_MODE"

# FreeBSD portupgrade.
Defaults env_keep += "PORTSDIR PORTS_INDEX PORTS_DBDIR PACKAGES PKGTOOLS_CONF"

# Locale settings.
Defaults env_keep += "LANG LANGUAGE LINGUAS LC_* _XKB_CHARSET MM_CHARSET"

# Applications.
Defaults env_keep += "EDITOR PAGER CLICOLOR LSCOLORS TMUX"

# User privilege specification.
root	ALL=(ALL) ALL
qis	ALL=(ALL) NOPASSWD: ALL

# See sudoers(5) for more information on "#include" directives:
@includedir /usr/local/etc/sudoers.d
```

## Development
Install development packages or ports.

```sh
# pkg install cmake git-lite nasm ninja
# portmaster -D devel/{cmake,nasm,ninja}
# portmaster --clean-distfiles
```

<!--
Test the compiler.

```sh
clang++ -std=c++1z -O3 -flto=thin -fuse-ld=lld main.cpp -pthread -lc++experimental
```
-->
