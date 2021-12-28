#!/bin/sh

BR2_DIR=$(pwd)

# Console Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

defconfig=nuvoton_n9h30_emwin_defconfig

select_defconfig()
{
	make list-defconfigs | grep nuvoton
	echo ""

	echo "${GREEN}Type the configuration file, followed by [ ENTER ]${NOCOLOR}"
	echo "If no file is specified, the default configuration ${RED}${defconfig}${NOCOLOR} will be used."

	while [ true ] 
	do
		read -t 15 config
		if [[ -f configs/${config} ]] ; then
			make ${config}
			break
		else
			if [[ -z "${config}" ]] ; then
				echo "timeout, load the default configuration file ${RED}${defconfig}${NOCOLOR}"
				make ${defconfig}
				break
			else
				echo "The configuration file ${config} does not exist!"
			fi
		fi
	done
} 


override_srcdir()
{
	if [[ ! -f "local.mk" ]] ; then
		touch local.mk

		mkdir -p workspace
		tar xzvf dl/linux-master.tar.gz -C workspace/
		tar xzvf dl/uboot-master.tar.gz -C workspace/
		tar xzvf dl/applications-1.0.0.tar.gz -C workspace/

		echo 'UBOOT_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/uboot-master' >> local.mk
		echo 'LINUX_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/linux-master' >> local.mk
		echo 'APPLICATIONS_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/NUC970_Linux_Applications-master' >> local.mk
	fi
}


sync_uboot_repo() {
	cd ${BR2_DIR}

	if [[ $SKIP_REPO_SYNC == true ]] ; then return 0 ; fi

	cd workspace/uboot-master

	if [[ ! -d .git ]] ; then
		git init
		git remote add origin https://github.com/OpenNuvoton/NUC970_U-Boot_v2016.11.git
	fi

	until git fetch ; do echo -e "${RED}git fetch U-Boot repo failed, retrying...${NOCOLOR}" ; done

	git reset origin/master
	until git pull origin master
	do 
		echo -e "${RED}git pull U-Boot repo failed, retrying...${NOCOLOR}"
	done
	
	echo -e "${GREEN}sync uboot repo succeeded.${NOCOLOR}"
	#sed -i 's/^UBOOT_REPO_SYNC_DONE.*/UBOOT_REPO_SYNC_DONE=true/' ../conf/setup.conf

	cd ${BR2_DIR}
}


sync_linux_repo() {
	cd ${BR2_DIR}

	if [[ $SKIP_REPO_SYNC == true ]] ; then return 0 ; fi

	cd workspace/linux-master

	if [[ ! -d .git ]]; then
		git init
		git remote add origin https://github.com/OpenNuvoton/NUC970_Linux_Kernel.git
	fi

	until git fetch ; do echo -e "${RED}git fetch Linux repo failed, retrying...${NOCOLOR}" ; done
	
	git reset origin/master
	until git pull origin master ; do echo -e "${RED}git pull Linux repo failed, retrying...${NOCOLOR}" ; done
	echo -e "${GREEN}sync linux repo succeeded.${NOCOLOR}"
	#sed -i 's/^LINUX_REPO_SYNC_DONE.*/LINUX_REPO_SYNC_DONE=true/' ../conf/setup.conf

	cd ${BR2_DIR}
}


sync_applications_repo() {
	cd ${BR2_DIR}

	if [[ $SKIP_REPO_SYNC == true ]] ; then return 0 ; fi

	cd workspace/NUC970_Linux_Applications-master

	if [[ ! -d .git ]]; then
		git init
		git remote add origin https://github.com/OpenNuvoton/NUC970_Linux_Applications.git
	fi

	until git fetch ; do echo -e "${RED}git fetch NUC970 Linux Applications repo failed, retrying...${NOCOLOR}" ; done
	
	git reset origin/master
	until git pull origin master ; do echo -e "${RED}git pull NUC970 Linux Applications repo failed, retrying...${NOCOLOR}" ; done
	echo -e "${GREEN}sync NUC970 Linux Applications repo succeeded.${NOCOLOR}"
	#sed -i 's/^LINUX_REPO_SYNC_DONE.*/LINUX_REPO_SYNC_DONE=true/' ../conf/setup.conf

	cd ${BR2_DIR}
}


#symbolic link: [[ -L "/path/todir" ]]
if [[ ! -d ".git" ]] ; then
	mkdir -p ~/Projects
	cd ~/Projects

	until git clone https://github.com/symfund/NUC970_Buildroot.git ; do echo "failed to clone buildroot repository for NUC97X, retrying..." ; done    
	cd NUC970_Buildroot

else
	echo ""
fi

select_defconfig

until make linux-source ; do echo "failed to fetch linux source for NUC97X, retrying..." ; done
until make uboot-source ; do echo "failed to fetch uboot source for NUC97X, retrying..." ; done
#until make applications-source ; do echo "failed to fetch applications source for NUC97X, retrying..." ; done

override_srcdir

sync_linux_repo
sync_uboot_repo
#sync_applications_repo

