#!/bin/sh

# Configure dnf (In order: automatically select fastest mirror, parallel downloads, and disable telemetry)
# fastestmirror=1
printf "%s" "
max_parallel_downloads=10
countme=false
" | sudo tee -a /etc/dnf/dnf.conf

# Prompt Bluetooth
echo "Do you want bluetooth? [y/n]"
read -r bluetooth

# Setup RPMFusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
sudo dnf groupupdate core -y


# echo 'Make sure your system has been fully-updated by running "sudo dnf upgrade -y" and reboot it once.'
sudo dnf upgrade -y

#Setting umask to 077
# No one except wheel user and root get read/write files
umask 077
sudo sed -i 's/umask 022/umask 077/g' /etc/bashrc

# Debloat
sudo dnf remove -y anaconda* \
	# Extra Firmware
	zd1211-firmware atmel-firmware libertas-usb8388-firmware abrt* anthy-unicode avahi bluez-cups brasero-libs trousers alsa-sof-firmware boost-date-time yelp orca fedora-bookmarks fedora-chromium-config mailcap open-vm-tools samba-client unbound-libs podman yajl mediawriter nano nano-default-editor sane* perl* thermald NetworkManager-ssh sos kpartx dos2unix sssd cyrus-sasl-plain geolite2* traceroute gnome-themes-extra ModemManager tcpdump mozilla-filesystem nmap-ncat spice-vdagent eog gnome-text-editorevince cheese gnome-classic-session baobab gnome-calculator gnome-characters gnome-system-monitor gnome-font-viewer gnome-font-viewer simple-scan evince-djvu gnome-tour gnome-shell-extension* gnome-weather gnome-boxes gnome-clocks gnome-contacts gnome-tour gnome-logs gnome-remote-desktop totem gnome-calendar gnome-shell-extension-background-logo gnome-maps gnome-backgrounds gnome-software gnome-connections gnome-user-docs gnome-color-manager perl-IO-Socket-SSL adcli mtr realmd teamd vpnc openconnect openvpn ppp pptp qgnomeplatform rsync xorg-x11-drv-vmware hyperv* virtualbox-guest-additions qemu-guest-agent 

# Run Updates
sudo dnf autoremove -y
sudo fwupdmgr get-devices
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates -y
sudo fwupdmgr update -y

# Configure GNOME
gsettings set org.gnome.desktop.a11y always-show-universal-access-status true
#gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Setup Flathub beta and third party packages
sudo fedora-third-party enable
sudo fedora-third-party refresh
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo

# Install things I need, top is uncategorized
flatpak install -y flathub org.libreoffice.LibreOffice com.github.tchx84.Flatseal com.github.finefindus.eyedropper com.brave.Browser com.github.micahflee.torbrowser-launcher net.davidotek.pupgui2 com.valvesoftware.Steam org.freedesktop.Platform.VulkanLayer.MangoHud org.gnome.Evince org.gnome.Calculator org.gnome.Extensions org.gnome.Characters org.gnome.Loupe org.gnome.Calendar app.drey.Warp org.gnome.Maps org.gnome.World.PikaBackup com.obsproject.Studio com.usebottles.bottles com.obsproject.Studio.Plugin.OBSVkCapture org.gnome.gitlab.YaLTeR.VideoTrimmer org.freedesktop.Platform.VulkanLayer.OBSVkCapture io.mpv.Mpv com.chatterino.chatterino com.discordapp.Discord io.freetubeapp.FreeTube org.qbittorrent.qBittorrent tv.plex.PlexDesktop net.mullvad.MullvadBrowser org.bleachbit.BleachBit net.lutris.Lutris
# Install Beta version of GIMP. It performs better than the stable one, plus better Wayland support.
#flatpak install -y flathub-beta org.gimp.GIMP
sudo dnf install -y steam-devices neovim sqlite3 zsh-autosuggestions zsh-syntax-highlighting setroubleshoot newsboat ffmpeg compat-ffmpeg4 akmod-v4l2loopback yt-dlp @virtualization guestfs-tools ntfs-3g distrobox distrobox hugo neofetch  simple-scan --best --allowerasing
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld

# Initialize virtualization
sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /etc/libvirt/libvirtd.conf
sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/g' /etc/libvirt/libvirtd.conf
sudo systemctl enable libvirtd
sudo usermod -aG libvirt "$(whoami)"

# Cockpit is still missing some core functionality, but will switch when it is added.
#sudo systemctl enable cockpit.socket --now

# Harden the Kernel with Kicksecure's patches
# Disables CD ROMs, FireWire, default writes, various kernel flags.
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/modprobe.d/30_security-misc.conf -o /etc/modprobe.d/30_security-misc.conf
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/sysctl.d/30_security-misc.conf -o /etc/sysctl.d/30_security-misc.conf
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/sysctl.d/30_silent-kernel-printk.conf -o /etc/sysctl.d/30_silent-kernel-printk.conf

# Enable Kicksecure CPU mitigations
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_cpu_mitigations.cfg -o /etc/grub.d/40_cpu_mitigations.cfg
# Kicksecure's CPU distrust script
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_distrust_cpu.cfg -o /etc/grub.d/40_distrust_cpu.cfg
# Enable Kicksecure's IOMMU patch (limits DMA)
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_enable_iommu.cfg -o /etc/grub.d/40_enable_iommu.cfg

# Divested's brace patches
# Sandbox the brace systemd permissions
# If you have VPN issues: https://old.reddit.com/r/DivestOS/comments/12b4fk4/comment/jex4qt2/
sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
sudo curl https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/NetworkManager.service.d/99-brace.conf -o /etc/systemd/system/NetworkManager.service.d/99-brace.conf
sudo mkdir -p /etc/systemd/system/irqbalance.service.d
sudo curl https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/irqbalance.service.d/99-brace.conf -o /etc/systemd/system/irqbalance.service.d/99-brace.conf

# GrapheneOS's ssh limits
# caps the system usage of sshd
sudo mkdir -p /etc/systemd/system/sshd.service.d
sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/sshd.service.d/local.conf -o /etc/systemd/system/sshd.service.d/local.conf
# echo "GSSAPIAuthentication no" | sudo tee /etc/ssh/ssh_config.d/10-custom.conf
# echo "VerifyHostKeyDNS yes" | sudo tee -a /etc/ssh/ssh_config.d/10-custom.conf

# NTS instead of NTP
# NTS is a more secured version of NTP
sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf -o /etc/chrony.conf

# Whonix Machine ID
#echo "b08dfa6083e7567a1921a715000001fb" | sudo tee /etc/machine-id

# Remove Firewalld's Default Rules
sudo firewall-cmd --permanent --remove-port=1025-65535/udp
sudo firewall-cmd --permanent --remove-port=1025-65535/tcp
sudo firewall-cmd --permanent --remove-service=mdns
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --remove-service=samba-client
sudo firewall-cmd --reload

#Randomize MAC address and disable static hostname. This could be used to track general network activity.
sudo bash -c 'cat > /etc/NetworkManager/conf.d/00-macrandomize.conf' <<-'EOF'
[main]
hostname-mode=none

[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

sudo systemctl restart NetworkManager
sudo hostnamectl hostname "localhost"

# Disable Bluetooth
# or renable it!
case "$bluetooth" in
	y|Y)
		sudo sed -i 's,install bluetooth /bin/disabled-bluetooth-by-security-misc,#install bluetooth /bin/disabled-bluetooth-by-security-misc,g' /etc/modprobe.d/30_security-misc.conf
		sudo sed -i 's,install btusb /bin/disabled-bluetooth-by-security-misc,#install btusb /bin/disabled-bluetooth-by-security-misc,g' /etc/modprobe.d/30_security-misc.conf
		;;
	*)
		echo "Disabling Bluetooth..."
		sudo systemctl disable bluetooth
esac
 
# Enable DNSSEC
# causes severe network instability, but working on getting this up and running
# sudo sed -i s/#DNSSEC=no/DNSSEC=yes/g /etc/systemd/resolved.conf
# sudo systemctl restart systemd-resolved

# Make the Home folder private
# Privatizing the home folder creates problems with virt-manager
# accessing ISOs from your home directory. Store images in /var/lib/libvirt/images
chmod 700 /home/"$(whoami)"
# is reset using:
#chmod 755 /home/"$(whoami)"
#
# In Wine, Easy AntiCheat requires Wine to use ptrace as a standard user.
# Kicksecure limits this to root, but the workaround in this file is not comprehensive.
sudo sed -i 's,kernel.yama.ptrace_scope=2,#kernel.yama.ptrace_scope=2,g' /etc/sysctl.d/30_security-misc.conf

echo "The configuration is now complete."
