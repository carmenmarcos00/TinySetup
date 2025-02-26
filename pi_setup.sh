#!/usr/bin/env bash

#The MIT License (MIT)

#Copyright (c) 2014 Oak Ridge National Laboratory

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.


sudo cp /etc/network/interfaces /etc/network/interfaces_backup

echo "Enter the node number of this pi followed by [ENTER]: "
read pi_number
re='^[0-9]+$'
if ! [[ $pi_number =~ $re ]] ; then
    echo "Error: Please enter integer" >&2; exit 1
fi
pi_name="pi$pi_number"

echo "Installing system software and updates"
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install vim xboxdrv libglew-dev sshpass

echo "Installing openMPI instead of MPICH"
sudo apt update
sudo apt install openmpi-bin
sudo apt install libopenmpi-dev

echo "installing new libav-tools"
sudo apt-get install ffmpeg

echo ""

echo "Symbolic link to libraries that cause problems when launching mpirun"
echo "Linking against //opt/vc/lib/libbrcm"
sudo ln -s //opt/vc/lib/libbrcmEGL.so /usr/lib/libEGL.so
sudo ln -s //opt/vc/lib/libbrcmGLESv2.so /usr/lib/libGLESv2.so

ls /usr/lib/libEGL.so -la
ls /usr/lib/libGLESv2.so -la

echo ""

echo"Making git clone of my SPH repository"
#Mine, as I have made some changes on src code and makefile
https://github.com/carmenmarcos00/SPH

echo "Configuring SSH service to start automatically"
sudo systemctl enable ssh

echo ""

echo "Setting computer name"
for file in \
  /etc/hosts \
  /etc/hostname \
  /etc/ssh/ssh_host_rsa_key.pub \
  /etc/ssh/ssh_host_dsa_key.pub
do
  [ -f $file ] && sudo sed -i -E "s/pi[0-9]+/$pi_name/" $file > /dev/null 2>&1
  [ -f $file ] && sudo sed -i "s/raspberrypi/$pi_name/" $file > /dev/null 2>&1
done
sudo /etc/init.d/hostname.sh start > /dev/null 2>&1
sudo hostname $pi_name

echo "Setting network interface" 
sudo tee /etc/network/interfaces <<-EOF
auto lo
 
iface lo inet loopback
# iface eth0 inet dhcp
 
auto eth0
iface eth0 inet static
address 192.168.3.$(($pi_number+100))
gateway 192.168.3.1
netmask 255.255.255.0
network 192.168.3.0
broadcast 192.168.3.255
 
# allow-hotplug wlan0
# iface wlan0 inet manual
# wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
# iface default inet dhcp
EOF
 
echo "Generating key-pairs"
ssh-keygen -N '' -f /home/pi/.ssh/id_rsa

#SOLO HACER DESDE EL SCRIPT QUE LANZA EL MASTER AL FINAL (PASO E, F) NO VA AQUÍ, MEJOR EN EL OTRO SCRIPT
#TODO: Cambiar de scrpt y automatizar número de ip e imputs

echo "Rebooting"
sudo reboot
