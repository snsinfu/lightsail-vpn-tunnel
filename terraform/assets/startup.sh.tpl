# This is injected into Lightsail-provided startup shell script.

# Remove lightsail-provided admin user.
userdel -rf admin

# Add our own admin user.
groupadd ${admin_user}
useradd ${admin_user} -g ${admin_user} -G users,sudo -s /bin/bash -m

chpasswd -e << 'END'
${admin_user}:${admin_password_hash}
END

umask 077
mkdir /home/${admin_user}/.ssh
cat > /home/${admin_user}/.ssh/authorized_keys << 'END'
${admin_authorized_keys}
END
umask 022
chown -R ${admin_user}:${admin_user} /home/${admin_user}/.ssh

# Lightsail's Debian uses a stale kernel. Update.
export DEBIAN_FRONTEND=noninteractive
apt-get update -qy
apt-get install -qy --no-install-recommends linux-image-amd64

# Wait 1 minute before rebooting to allow cloud-init to finish.
shutdown -r +1
