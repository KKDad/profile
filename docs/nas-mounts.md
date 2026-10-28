## Mount folders from Vault

### Install required software
~~~
sudo apt update && sudo apt upgrade
sudo apt install cifs-utils smbclient
~~~

### Create the credential files:

~~~
sudo vi /home/agilbert/.examplecredentials
~~~
Add the contents:
~~~
username=example_username
password=example_password
~~~

### List available shares

Use smbclient
~~~
agilbert@vdi-ubuntu-budgie:~$ smbclient -L vault.stapledon.ca -U Adrian
Password for [WORKGROUP\Adrian]:

	Sharename       Type      Comment
	---------       ----      -------
	Documents       Disk      
	homes           Disk      user home
	music           Disk      System default shared folder
	photo           Disk      System default shared folder
	PlexMediaServer Disk      
	PodGeneral      Disk      General Storage for k8s Pods
	Software        Disk      
	TimeMachine     Disk      
	usbshare1       Disk      Seagate RSS LLC
	Vault           Disk      
	video           Disk      System default shared folder
	Virtual_Backups Disk      Virtual Machine Backups
	home            Disk      Home directory of Adrian
~~~

### Trial Mount

sudo mount -t cifs -o rw,vers=3.0,credentials=/home/agilbert/.examplecredentials //vault.stapledon.ca/PodGeneral /pod_general

### Permenant Mounts

Add entrys to /etc/fstab to persist mounts across vm reboots
~~~
sudo vi /etc/fstab
~~~
Append the following contents
~~~
//vault.stapledon.ca/Virtual_Backups /backups cifs vers=3,uid=1000,gid=1000,credentials=/home/agilbert/.vault
//vault.stapledon.ca/home /home/agilbert/vault cifs vers=3,uid=1000,gid=1000,credentials=/home/agilbert/.vault 
//vault.stapledon.ca/video /video cifs vers=3,uid=1000,gid=1000,credentials=/home/agilbert/.vault 
//vault.stapledon.ca/PodGeneral /pod_general cifs vers=3,uid=1000,gid=1000,credentials=/home/agilbert/.vault 
//vault.stapledon.ca/Vault /vault cifs vers=3,uid=1000,gid=1000,scredentials=/home/agilbert/.vault 
~~~

Entries in fstab won't mount automatically, to apply them without a reboot, run the following to apply
~~~
sudo systemctl daemon-reload
sudo mount -av
~~~