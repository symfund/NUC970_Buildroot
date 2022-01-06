#!/bin/sh

BR2_DIR=$(pwd)

# PLATFORM [ NUC970 | NUC980 ]
PLATFORM=NUC970

# Console Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

defconfig=nuvoton_n9h30_emwin_defconfig

trap ctrl_c INT

function ctrl_c()
{
	echo -e "${YELLOW}** Trapped CTRL-C${NOCOLOR}"
	cd ${BR2_DIR}
}


platform_determinate()
{
	case $1 in
		nuvoton_nuc97*_defconfig ) echo "NUC970 matched"
			PLATFORM=NUC970;;
		nuvoton_nuc98*_defconfig ) echo "NUC980 matched"
			PLATFORM=NUC980;;
		nuvoton_n9h30*_defconfig ) echo "N9H30 matched"
			PLATFORM=NUC970;;
		* )	echo "UNKNOWN PLATFORM"
			PLATFORM=UNKNOWN;;
	esac

	echo "PLATFORM = ${PLATFORM}"
	sed -i "s/^BR2_DEFCONFIG=.*/BR2_DEFCONFIG=$1/" workspace/configs/build.conf
}


select_defconfig()
{
	make list-defconfigs | grep nuvoton
	echo ""

	echo -e "${GREEN}Type the configuration file, followed by [ ENTER ]${NOCOLOR}"

	while [ true ] 
	do
		read -t 15 config
		if [[ -f configs/${config} ]]; then
			make ${config}

			# platform
			platform_determinate ${config}

			break
		else
			if [[ -z "${config}" ]] ; then
				# buildroot configuration saved?
				if [[ "${BR2_SAVECONFIG}" = true ]]; then
					echo -e "${YELLOW}load previous saved configuration${NOCOLOR}"
					make defconfig BR2_DEFCONFIG=workspace/configs/buildroot.conf
					platform_determinate ${BR2_DEFCONFIG}
				else
					if [[ -f configs/${BR2_DEFCONFIG} ]]; then
						echo -e "${YELLOW}use previous configuration ${BR2_DEFCONFIG}${NOCOLOR}"
						make ${BR2_DEFCONFIG}
						platform_determinate ${BR2_DEFCONFIG}
					else
						echo -e "${YELLOW}use preset configuration ${defconfig}${NOCOLOR}"
						make ${defconfig}
						platform_determinate ${defconfig}
					fi
				fi

				break
			else
				echo -e "The configuration file ${RED}${config}${NOCOLOR} does not exist!"
			fi
		fi
	done
} 


override_srcdir()
{
	touch local.mk

	mkdir -p workspace
	
	if [[ ! -d workspace/linux-master ]]; then
		tar xzvf dl/linux-master.tar.gz -C workspace/
	fi
	
	if [[ ! -d workspace/uboot-master ]]; then
		tar xzvf dl/uboot-master.tar.gz -C workspace/
	fi

	#if [[ ! -d workspace ]]; then
	#	tar xzvf dl/applications-1.0.0.tar.gz -C workspace/
	#fi

	echo 'UBOOT_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/uboot-master' >> local.mk
	echo 'LINUX_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/linux-master' >> local.mk
	#echo 'APPLICATIONS_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/NUC970_Linux_Applications-master' >> local.mk
}


sync_uboot_repo() {
	FETCH_ABORTED=false
	PULL_ABORTED=false

	cd ${BR2_DIR}

	if [[ $SYNC_REPO_DISABLED = true ]] ; then return 0 ; fi

	cd workspace/uboot-master

	if [[ ! -d .git ]] ; then
		git init
		git remote add origin https://github.com/OpenNuvoton/NUC970_U-Boot_v2016.11.git
	fi

	until  echo -e "${GREEN}fetching uboot...${NOCOLOR}"; git fetch
	do 
		echo -e "${RED}fetching uboot failed, retrying...${NOCOLOR}" 
		read -p "Press Y or y to abort fetching. Are you sure? " -n 1 -r -t 5 REPLY
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			FETCH_ABORTED=true
			echo
                        echo -e "${YELLOW}fetching uboot aborted.${NOCOLOR}"
                        break
                fi
		echo
	done

	if [[ "${FETCH_ABORTED}" = false ]]; then 
		echo -e "${GREEN}fetching uboot succeeded.${NOCOLOR}"
	fi

	git reset origin/master 

	until echo -e "${GREEN}pulling uboot...${NOCOLOR}"; git pull origin master
	do 
		echo -e "${RED}git pull uboot repo failed, retrying...${NOCOLOR}"
		read -p "$Press Y or y to abort pulling. Are you sure? " -n 1 -r -t 5 REPLY
                if [[ $REPLY =~ ^[Yy]$ ]]; then
			PULL_ABORTED=true
			
			echo
                        echo -e "${YELLOW}pulling uboot aborted.${NOCOLOR}"
                        break
                fi
		echo
	done

	if [[ "${PULL_ABORTED}" = false ]]; then
		echo -e "${GREEN}pulling uboot succeeded.${NOCOLOR}"
	fi
	
	echo -e "${GREEN}sync uboot repo succeeded.${NOCOLOR}"
	#sed -i 's/^UBOOT_REPO_SYNC_DONE.*/UBOOT_REPO_SYNC_DONE=true/' ../conf/setup.conf

	cd ${BR2_DIR}
}


sync_linux_repo() {
	FETCH_ABORTED=false
	PULL_ABORTED=false

	cd ${BR2_DIR}

	if [[ $SYNC_REPO_DISABLED = true ]] ; then return 0 ; fi

	cd workspace/linux-master

	if [[ ! -d .git ]]; then
		git init

		if [[ "${PLATFORM}" == "NUC970" ]]; then
			git remote add origin https://github.com/OpenNuvoton/NUC970_Linux_Kernel.git
		fi

		if [[ "${PLATFORM}" == "NUC980" ]]; then
			git remote add origin https://github.com/OpenNuvoton/NUC980-linux-4.4.y.git
		fi
	fi

	until echo -e "${GREEN}fetching linux...${NOCOLOR}"; git fetch; 
	do 
		echo -e "${RED}fetching linux failed, retrying...${NOCOLOR}"
		read -p "Press Y or y to abort fetching linux. Are you sure? " -n 1 -r -t 5 REPLY
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			FETCH_ABORTED=true
			echo
			echo -e "${YELLOW}fetching linux aborted.${NOCOLOR}"
			break
		fi 
		echo
	done

	if [[ "${FETCH_ABORTED}" = false ]]; then
		echo -e "${GREEN}fetching linux succeeded.${NOCOLOR}"
	fi
	
	git reset origin/master

	until echo -e "${GREEN} pulling linux...${NOCOLOR}"; git pull origin master; 
	do 
		echo -e "${RED}pulling linux failed, retrying...${NOCOLOR}" 
		read -p "Press Y or y to abort pulling linux. Are you sure? " -n 1 -r -t 5 REPLY
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			PULL_ABORTED=true
			echo
			echo -e "${YELLOW}pulling linux aborted.${NOCOLOR}"
			break;
		fi
		echo
	done

	if [[ "${PULL_ABORTED}" = false ]]; then
		echo -e "${GREEN}pulling linux succeeded.${NOCOLOR}"
	fi

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

		if [[ "${PLATFORM}" == "NUC970" ]]; then
			git remote add origin https://github.com/OpenNuvoton/NUC970_Linux_Applications.git
		fi

		if [[ "${PLATFORM}" == "NUC980" ]]; then
			git remote add origin https://github.com/OpenNuvoton/NUC980_Linux_Applications.git
		fi
	fi

	until git fetch ; do echo -e "${RED}git fetch NUC970 Linux Applications repo failed, retrying...${NOCOLOR}" ; done
	
	git reset origin/master
	until git pull origin master ; do echo -e "${RED}git pull NUC970 Linux Applications repo failed, retrying...${NOCOLOR}" ; done
	echo -e "${GREEN}sync NUC970 Linux Applications repo succeeded.${NOCOLOR}"
	#sed -i 's/^LINUX_REPO_SYNC_DONE.*/LINUX_REPO_SYNC_DONE=true/' ../conf/setup.conf

	cd ${BR2_DIR}
}


save_configs()
{
	cd ${BR2_DIR}

	mkdir -p workspace/configs

	if [[ ! -f workspace/configs/build.conf ]]; then
		touch workspace/configs/build.conf

		echo "SYNC_REPO_DISABLED=false" >> workspace/configs/build.conf
	fi

	source workspace/configs/build.conf
 
	#make savedefconfig BR2_DEFCONFIG=workspace/configs/buildroot.config
}


#sudo apt install python

#symbolic link: [[ -L "/path/todir" ]]
if [[ ! -d ".git" ]] ; then
	mkdir -p ~/Projects
	cd ~/Projects

	until git clone https://github.com/symfund/NUC970_Buildroot.git ; do echo "${RED}failed to clone buildroot repository, retrying...${NOCOLOR}" ; done    
	cd NUC970_Buildroot

else
	echo ""
fi

mkdir -p workspace/configs

if [[ ! -f workspace/configs/build.conf ]]; then
	touch workspace/configs/build.conf

	echo "SYNC_REPO_DISABLED=false" >> workspace/configs/build.conf
	echo "BR2_SAVECONFIG=false" >> workspace/configs/build.conf
	echo "BR2_DEFCONFIG=UNKNOWN" >> workspace/configs/build.conf
fi

source workspace/configs/build.conf

rm -rf local.mk
select_defconfig

until make linux-source ; do echo "failed to fetch linux source for NUC97X, retrying..." ; done
until make uboot-source ; do echo "failed to fetch uboot source for NUC97X, retrying..." ; done
#until make applications-source ; do echo "failed to fetch applications source for NUC97X, retrying..." ; done

override_srcdir

sync_linux_repo
sync_uboot_repo
#sync_applications_repo

save_configs
