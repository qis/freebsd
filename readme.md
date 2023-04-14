# FreeBSD
Installation template for FreeBSD `STABLE`.

<!--
**Distribution Select**

```
[ ] base-dbg
[ ] kernel-dbg
[ ] lib32-dbg
[ ] lib32
[*] src
[ ] tests
```

**System Configuration**

```
[ ] local_unbound
[*] sshd
[ ] moused
[*] ntpd
[*] powerd
[ ] dumpdev
```

**System Hardening**

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
printf "fdesc\t\t/dev/fd\t\tfdescfs\trw\t0\t0\n" >> /etc/fstab
printf "proc\t\t/proc\t\tprocfs\trw\t0\t0\n" >> /etc/fstab
ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key
chmod 600 /etc/ssh/ssh_host_rsa_key
pkg install curl git wget

set backup=https://raw.githubusercontent.com/qis/freebsd/master
wget ${backup}/root/.cshrc -O /root/.cshrc
wget ${backup}/root/.tmux.conf -O /root/.tmux.conf
wget ${backup}/boot/loader.conf -O /boot/loader.conf
```

```sh
tee /etc/rc.conf >/dev/null <<'EOF'
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
```

## System Backup
Create backup.

```sh
tar cvzf /home/qis/root.tar.gz /boot/loader.conf \
  /etc/{ssh/sshd_config,devfs.conf,make.conf,mergemaster.rc,ntp.conf,src.conf,sysctl.conf} \
  /home/qis/{.config/nvim,.cshrc,.gitconfig,.tmux.conf,.ssh/authorized_keys,.ssh/config} \
  /root/{.config/nvim,.cshrc,.tmux.conf,.ssh/authorized_keys,.ssh/config}
```

Restore backup.

```sh
tar xvf /home/qis/root.tar.gz -C /
rm -f /home/qis/{.login,.login_conf,.mail_aliases,.mailrc,.profile,.rhosts,.shrc}
rm -f /root/{.k5login,.login,.profile}
reboot
```

## System Update
Update `RELEASE`.

```sh
freebsd-update fetch
freebsd-update install
```

Update `STABLE`.

```sh
# svn checkout https://svn.freebsd.org/base/stable/11 /usr/src
cd /usr/src && svn update
make -j7 buildworld kernel KERNCONF=GENERIC && reboot
make installworld
```

Update `CURRENT`.

```sh
# svn checkout https://svn.freebsd.org/base/head /usr/src
cd /usr/src && svn update
make -j7 buildworld kernel KERNCONF=GENERIC-NODEBUG && reboot
make installworld
```

Merge configuration files.

```sh
mergemaster -Ui
make check-old       # yes | make delete-old
make check-old-libs  # yes | make delete-old-libs
```

<!--
Create system image.

```sh
cd /usr/src && svn update
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

`visudo`

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
#includedir /usr/local/etc/sudoers.d
```

## Development
Install development packages or ports.

```sh
# pkg install cmake git-lite nasm ninja
# portmaster -D devel/{cmake,git-lite,nasm,ninja}
# portmaster --clean-distfiles
```

<!--
Test the compiler.

```sh
clang++ -std=c++1z -O3 -flto=thin -fuse-ld=lld main.cpp -pthread -lc++experimental
```
-->
