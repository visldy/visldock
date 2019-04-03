# Install Docker-ce
apt-get update
apt-get dist-upgrade -y
apt install -y apt-transport-https ca-certificates curl software-properties-common mc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt install -y docker-ce

# Set docker group id as DOMAIN_USERS
groupmod -g 449800513 docker

# Add administrator to docker group
usermod -aG docker administrator

# Make all new users members of docker group
echo 'EXTRA_GROUPS="dialout docker cdrom audio video plugdev users"' >> /etc/adduser.conf
echo 'ADD_EXTRA_GROUPS=1' >> /etc/adduser.conf

# Install nVidia Driver 418
apt-get purge -y nvidia-*
add-apt-repository -y ppa:graphics-drivers
apt-get update
apt remove -y libnvidia-common-390 libwayland-client0:i386 libwayland-server0:i386
apt install -y nvidia-driver-418 libnvidia-gl-418 nvidia-utils-418 xserver-xorg-video-nvidia-418 libnvidia-cfg1-418 libnvidia-ifr1-418 libnvidia-decode-418 libnvidia-encode-418

# Install nVidia Docker2
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd

# Copy visldock.sh to /usr/bin
./visldock.sh setup -c

echo 'Please restart PC!'
