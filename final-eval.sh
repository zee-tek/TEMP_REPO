#!/bin/bash

echo -e "\n\e[36mLINOOP TEK RHCSA EVALUATION TOOL STARTING\nKEEP CALM AND SIT TIGHT\e[0m"
echo -e "\n\e[37m***********************RUNNING NOW******************************\n\e[0m"

: ' This Script evaluate students tasks
   - Check static 	--DONE
   - Check repos  	--DONE
   - Create autofs 	--DONE
   - check root pw 	--DONE
   - check chrony  	--DONE
   - check group   	--DONE
   - check Users   	--DONE
   - check groupinstall	--DONE
   - check bzip2        --DONE
   - check selinux      --DONE
   - check journal      --DONE
   - tuned_profile      --DONE
   - cron               --DONE
   - swap	        --DONE
   - LVM		--DONE
  '


if [ `id -u` != 0 ];then
        echo ""
        echo -e "\e[31mFailed: Please Run this Script as root\e[0m\n"
        exit 1
fi
###############################################################################
dnf install sshpass -q -y &>/dev/null
pkg_ecode=$?

check_pw() {
   echo "Checking Root PW".......... 
   sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
   sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
   systemctl restart sshd &>/dev/null
   if [ $pkg_ecode -eq 0 ];then
      sshpass -p 'redhat' ssh -o StrictHostKeyChecking=no root@localhost 'pwd>/dev/null' &>/dev/null
      if [ $? -eq 0 ];then
        echo -e "\e[32mRoot_PW_Check: Pass\e[0m\n"
      else
        echo -e "\e[31mRoot_PW_Check: Fail\e[0m\n"
      fi
   else
     echo -e '"\e[31msshpass" package not installed, Please install it first\e[0m\n'
     echo -e "\e[31mexit 1\e[0m\n"
   fi
}

###############################################################################
check_interface() {
    if ip link show "$1" > /dev/null 2>&1; then
       echo -e "\nNetwork interface $1 exists.\n"
       #echo -e "          Running Validation"
       #echo -e "------------------------------------------\n"
       return 0
    else
       echo -e "\e[31mNetwork interface $1 does not exist. Please try again.\e[0m\n"
       return 1
    fi
}

# Prompt the user for the network interface name
#while true; do
#    read -p "Please Enter your network card name (e.g., enp0s3, ens): " n_card
#    check_interface "$n_card" && break
#done
################################################################################
user_name="user1"
validate_autofs() {
	echo "Checking Autofs".................
        su - $user_name -c "touch /rhome/$user_name/uniq1" &>/dev/null
        file_st=$?
        df -h|grep $user_name &>/dev/null
        mn_st=$?

        if [ $file_st -eq 0 ]&&[ $mn_st -eq 0 ];then
                echo -e "\e[32mAutoFS_Check: Pass\e[0m\n"
        else
                echo -e "\e[31mAutoFS_Check: Fail\e[0m\n"
        fi
}
	
################################################################################
grp="admins"
check_grp(){
      echo "Check Group Exists"..................
      if [ `getent group admins` ];then
        echo -e "\e[32mGroup: Pass\e[0m\n"
      else
        echo -e "\e[31mGroup: Fail\e[0m\n"
      fi
}

check_users(){
    echo "Check Users Accounts"................
    users=("harry" "natasha" "sarah")

    all_users_exist=true

    for user in "${users[@]}"; do
      if ! id "$user" &>/dev/null; then
        #echo "User $user does not exist."
        all_users_exist=false
      fi
    done

    if [ "$all_users_exist" = true ]; then
        echo -e "\e[32mUSERS: Pass\e[0m\n"
    else
        echo -e "\e[31mUSERS: Fail\e[0m\n"
    fi
}


check_grp_membership(){
    echo "Check Group MemberShip"...................
    grp="admins"
    users=("harry" "natasha")

    grp_members=true

    for user in "${users[@]}"; do
      if ! id -nG "$user" | grep -qw "$grp" &>/dev/null; then
        grp_members=false
      fi
    done

    if [ "$grp_members" = true ]; then
        echo -e "\e[32mGroup_membership: Pass\e[0m\n"
    else
        echo -e "\e[31mGroup_membership: Fail\e[0m\n"
    fi
}



check_usr_shell(){
    echo "Check sarah shell"................
    lg_shell=`grep sarah /etc/passwd|awk -F : '{ print $7 }'|awk -F / '{ print $NF }'`
    des_shell="nologin"
    if [ $lg_shell == $des_shell ];then
	echo -e "\e[32msarah_shell: PASS\e[0m\n"
    else
	echo -e "\e[31msarah_shell: Fail\e[0m\n"
    fi
}

chk_sudo(){
    echo "Check SUDO"...................
    grep "^%admins" /etc/sudoers &>/dev/null
    sudo_st=$?
    grep "^%admins" /etc/sudoers|grep "NOPASSWD" &>/dev/null
    sudo_st1=$?

    if [ $sudo_st -eq 0 ] && [ $sudo_st1 -eq 0 ];then
        echo -e "\e[32mSudo_Group: Pass\e[0m\n"
    else
        echo -e "\e[31mSudo_Group: Fail\e[0m\n"
    fi
}


check_umask(){
   echo "Check UMASK".................
   des_umask="0002"
   current_umask=`su - natasha -c 'umask'`

   if [ $des_umask == $current_umask ];then
           echo -e "\e[32mUMASK: Pass\e[0m\n"
   else
           echo -e "\e[31mUMASK: Fail\e[0m\n"
   fi
}

check_special_perm(){
   echo "Check SetGuid"...................
   dir="/tmp/admins"

    if [ -d "$dir" ]; then
    perm=$(stat -c "%A" "$dir")
    if [[ $perm == *"s"* ]]; then
        echo -e "\e[32mCollebration_DIR: Pass\e[0m\n"
    else
        echo -e "\e[31mCollebration_DIR: Fail\e[0m\n"
    fi
else
    echo -e "\e[31madmins_dir_exists: Fail\e[0m\n"
fi

}

check_special_perm2(){
   echo "Check StickyBit".....................
   dir="/tmp/admins"

    if [ -d "$dir" ]; then
    perm=$(stat -c "%A" "$dir")
    #if [[ $perm == *"t"* ]] || [[ $perm == *"T"* ]]; then
     if [[ $perm == *"t"* ]] || [[ $perm == *"T"* ]];then
        echo -e "\e[32mstick_bit: Pass\e[0m\n"
    else
        echo -e "\e[31msticky_bit: Fail\e[0m\n"
    fi
else
    echo -e "\e[31madmins_dir_exists: Fail\e[0m\n"
fi

}

chk_max_days(){
   echo "Check Max Days"...............
   max_d=`grep '^PASS_MAX_DAYS' /etc/login.defs|awk '{print $2}'`

   if [ $max_d == "90" ];then
        echo -e "\e[32mmax_days: Pass\e[0m\n"
   else
        echo -e "\e[31mmax_days: Fail\e[0m\n"
   fi
}


chk_enforce_pw(){
    echo "Check password change enforce"............
    user_n="harry"
    chage -l "$user_n" |head -n1|grep -w 'password must be changed'&>/dev/null
    st=$?
    if [ $st -eq 0 ]; then
        echo -e "\e[32menforce_pw_change: Pass\e[0m\n"
    else
        echo -e "\e[31menforce_pw_change: Fail\e[0m\n"
    fi
}

chk_acc_exp(){
   echo "Check account expiration"...............
   des_exp_d=45
   chg_d=`chage -l "harry" | grep "Account expires" | awk -F ':' '{print $NF}'|sed 's/^ *//;s/ *$//'`
   chage -l "harry" | grep "Account expires"|grep -q never
   chg_never=$?
 if [ $chg_never -ne 0 ];then

   if [ `date -d +${des_exp_d}days +%Y-%m-%d` == `date -d "$chg_d" +"%Y-%m-%d"` ];then
           echo -e "\e[32macc_exp: Pass\e[0m\n"
   else
           echo -e "\e[31macc_exp: Fail\e[0m\n"
   fi

 else

           echo -e "\e[31macc_exp_set: Fail\e[0m\n"
 fi

}
################################################################################
chk_grp_pkg(){
   echo "Check Group Software Install"..........
   dnf grouplist --installed|grep -w "RPM Development Tools" &>/dev/null
   pk_e=$?
   
   if [ $pk_e -eq 0 ];then
	   echo -e "\e[32mgrp_pkg_install: Pass\e[0m\n"
   else
	   echo -e "\e[31mgrp_pkg_install: Fail\e[0m\n"
   fi


}
################################################################################
check_bzip2_compression(){
  echo "Check bzip2 Compressions"..........
  file_n="/tmp/archive.tar"

  if file "$file_n" | grep -q "bzip2 compressed data"; then
    echo -e "\e[32mstick_bit: Pass\e[0m\n"
  else
    echo -e "\e[31mstick_bit: Fail\e[0m\n"
  fi
}
################################################################################
check_selinux(){
   echo "check website is accessible"..........
   selinux_chk=`curl localhost:82 2>/dev/null`
   firewall-cmd --list-ports |grep '82' &>/dev/null
   selinux_port=$?
   if [ "$selinux_chk" == "Practicing RHCSA9" ];then
	 echo -e "\e[32mSelinux_Web_Running: Pass \e[0m\n"
   else
	 echo -e "\e[31mSelinux_Web_Running: Fail \e[0m\n"
   fi

   if [ $selinux_port -eq 0 ];then
	 echo -e "\e[32mSelinux_Web_Firewall_Port: Pass \e[0m\n"
   else
	 echo -e "\e[31mSelinux_Web_Firewall_Port: Fail \e[0m\n"
   fi
}
################################################################################
check_journal(){
  echo "check persistent journal"..........
  journal_dir="/var/log/journal"
  if [ -d "$journal_dir" ] && [ "$(ls -A "$journal_dir")" ]; then
    echo -e "\e[32mpersistent_journal: Pass\e[0m\n"
  else
    echo -e "\e[31mpersistent_journal: Fail\e[0m\n"
  fi
}
################################################################################
check_tuned_profile(){
   echo "check tuned profile"..........
   systemctl restart tuned
   recommended_profile=$(tuned-adm recommend)
   current_profile=$(tuned-adm active | awk -F': ' '{print $2}')

   if [ "$current_profile" == "$recommended_profile" ]; then
     echo -e "\e[32mtuned_profile: PASS\e[0m\n"
   else
     echo -e "\e[31mtuned_profile: FAIL\e[0m\n"
   fi
}
################################################################################
check_cron(){
   echo "check cron job"..........
   grep -q "RHCSA9" /var/log/messages
   cron_st=$?
   if [ $cron_st -eq 0 ];then
	   echo -e "\e[32mcron: PASS\e[0m\n"
   else
	   echo -e "\e[31mcron: FAIL\e[0m\n"
   fi
   #crontab -l -u harry |grep -q '\*/1 \* \* \* \* /bin/echo hi >>/tmp/cron-test'
   #cron_st=$?
   #if [ $cron_st -eq 0 ];then
   #    echo -e "\e[32mcron: PASS\e[0m\n"
   #else
   #     echo -e "\e[31mcron: FAIL\e[0m\n"

   #fi
   
}
################################################################################
swap_check(){
   echo "check swap"..........
   swapon -s |egrep -q 'sdb1|vdb1'
   swp_st=$?
   #swp_disk=$(swapon -s |egrep 'sdb1|vdb1' 2>/dev/null|awk -F '/' '{print $3}'|awk '{print $1}')
   #add_size="512"


   if [ $swp_st -eq 0 ];then
      echo -e "\e[32mswp_disk_chk: Pass\e[0m\n"
      #sw_sdb1=$(swapon -s|grep ${swp_disk}|awk '{printf $3/1023}'|awk -F "." '{print $1}')
      sw_sdb1=$(lsblk|grep SWAP|egrep 'sdb1|vdb1'|awk '{print $4}'|tr -d M)
      if [ "$sw_sdb1" == "511" ]||[ "$sw_sdb1" == "512" ]; then
          echo -e "\e[32mswap_size_chk: Pass\e[0m\n"
      else
          echo -e "\e[31mswap_size_chk: Fail\e[0m\n"
      fi
   else
          echo -e "\e[31mswp_disk_chk: Fail\e[0m\n"
   fi
}
################################################################################
ip_test=`nmcli con show $n_card|grep ipv4.method|awk '{print $2}'`
dnf repolist --enabled -q|egrep -v '^rhel|^repo'|grep -i app&>/dev/null
app_chk=$?
dnf repolist --enabled -q|egrep -v '^rhel|^repo'|grep -i base&>/dev/null
base_chk=$?
sed -i "/^pool.*/s/^/# /" /etc/chrony.conf &>/dev/null
chronyc sources -v |grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' >/dev/null
chrony_chk=$?

##################################################################################
check_IP(){
   while true; do
    read -p "Please Enter your network card name (e.g., enp0s3, ens): " n_card
    check_interface "$n_card" && break
   done
   ip_test=`nmcli con show $n_card|grep ipv4.method|awk '{print $2}'`

   echo "Checking Ip"....................
   if [ $ip_test == "manual" ];then
        echo -e "\e[32mIP_Check: PASS\e[0m\n"
   else
	echo -e "\e[31mIP_Check: FAIL\e[0m\n"
   fi

}
###################################################################################
check_repos(){
   echo "Checking Repositories"..........

   if [ $app_chk -eq 0 ];then

     echo -e "\e[32mAPPSTRAM_Check: Pass\e[0m\n"

   else

     echo -e "\e[31mAPPSTREAM_Check: Fail\e[0m\n"

   fi

   if [ $base_chk -eq 0 ];then

     echo -e "\e[32mBASEOS_Check: Pass\e[0m\n"

   else

     echo -e "\e[31mBASEOS_Check: Fail\e[0m\n"

   fi

}
#####################################################################################

check_chrony(){
  echo "Check Chrony"....................
  systemctl restart chronyd &>/dev/null

  if [ $chrony_chk -eq 0 ];then

     echo -e "\e[32mChrony_Check: Pass\e[0m\n"

  else

     echo -e "\e[31mChrony_Check: Fail\e[0m\n"

  fi

}
#####################################################################################

#check_users(){
#   echo "Check USERS and GROUP".................
#check_grp
#check_users
#check_grp_membership
#check_usr_shell
#chk_sudo
#check_umask
#check_special_perm
#check_special_perm2
#chk_max_days
#chk_enforce_pw
#chk_acc_exp

#}
######################################################################################
check_lvm1(){
   
   filesystem="/app1"
   df -h|grep -q app1
   fs_st=$?
   echo "Checking LVM Question 17".................
   if [ $fs_st -eq 0 ];then
	   
	  filesystem="/app1"
	  filesystem_size=$(df -m | grep "$filesystem" | awk '{print $2}')
	  if [ $filesystem_size -ge 250 ] && [ $filesystem_size -le 300 ]; then
	      echo -e "\e[32mQ17: Pass\e[0m\n"
	  else
	      echo -e "\e[31mQ17: Fail\e[0m\n"
	  fi
   else
	   echo -e "\e[31mCheck $filesystem exists: Fail\e[0m\n"
   fi
 }

check_lvm2(){
   filesystem="/app2"
   df -h|grep -q app2
   fs_st=$?
   echo "Checking LVM Question 18".................
   if [ $fs_st -eq 0 ];then
	  echo "check fs shrink question 18"................
	  filesystem="/app2"
	  filesystem_size=$(df -m | grep "$filesystem" | awk '{print $2}')
	  if [ $filesystem_size -ge 260 ] && [ $filesystem_size -le 300 ]; then
	      echo -e "\e[32m Q18: Pass\e[0m\n"
	  else
	      echo -e "\e[31m Q18: Fail\e[0m\n"
	  fi
   else
	   echo -e "\e[31mCheck $filesystem exists: Fail\e[0m\n"
   fi
}

check_lvm3(){
   filesystem="/app3"
   df -h|grep -q app3
   fs_st=$?
   echo "Checking LVM Question 19".................
   if [ $fs_st -eq 0 ];then
	  echo "check fs extend question 19"................
	  filesystem="/app3"
	  filesystem_size=$(df -m | grep "$filesystem" | awk '{print $2}')
	  if [ $filesystem_size -ge 450 ] && [ $filesystem_size -le 500 ]; then
	       echo -e "\e[32m Q19: Pass\e[0m\n"
	  else
	       echo -e "\e[31m Q19: Fail\e[0m\n"
	  fi
   else
	   echo -e "\e[31mCheck $filesystem exists: Fail\e[0m\n"
   fi
}

check_lvm4(){
   vg_n="vg4"
   lv_n="lv4"
   vgs 2>/dev/null|grep ${vg_n} &>/dev/null
   vg_st=$?
   lvs 2>/dev/null|grep ${lv_n} &>/dev/null
   lv_st=$?
   echo "Checking LVM Question 20".................

   if [ $vg_st -eq 0 ] && [ $lv_st -eq 0 ];then

	  echo "check vg PE and lv LE question 20"..............
	  pe_req_size=8
	  pe_size=$(vgdisplay vg4 2>/dev/null|grep "PE Size"|awk '{print $(NF-1)}'|awk -F '.' '{print $1}')
	  req_le=50
	  aloc_le=$(lvdisplay /dev/vg4/lv4 2>/dev/null|grep 'Current LE'|awk '{print $(NF)}')

	  if [ $pe_size == $pe_req_size ];then
	         echo -e "\e[32m Q20 Task1: Pass\e[0m\n"
	  else
		 echo -e "\e[31m Q20 Task1: Fail\e[0m\n"
	  fi
	  if [ $aloc_le == $req_le ];then
		   echo -e "\e[32m Q20 Task2: Pass\e[0m\n"
	  else
		   echo -e "\e[31m Q20 Task2: Fail\e[0m\n"
	  fi
   else
	   echo -e "\e[31mcheck $vg_n and $lv_n exists: Fail\e[0m\n"
   fi

}

######################################################################################
check_container(){

   su - linda -c "podman images|grep -w webimage" &>/dev/null
   img_st=$?

   if [ $img_st -eq 0 ];then
	   echo -e "\e[32mcheck_Image: Pass\e[0m\n"
   else
	    echo -e "\e[31mcheck_Image: Fail\e[0m\n"
   fi

}

check_container2(){

     ps -ef|grep -w myweb1|grep -v grep &>/dev/null
     con_st=$?

     if [ $con_st -eq 0 ];then
           echo -e "\e[32mcheck_container: Pass\e[0m\n"
     else
            echo -e "\e[31mcheck_container: Fail\e[0m\n"
     fi



}
######################################################################################
#check_pw
#check_IP
#check_repos
#check_chrony
#validate_autofs
#check_grp
#check_users
#check_grp_membership
#check_usr_shell
#chk_sudo
#check_umask
#check_special_perm
#check_special_perm2
#chk_max_days
#chk_enforce_pw
#chk_acc_exp
#chk_grp_pkg
#check_selinux
#check_bzip2_compression
#check_cron
#check_tuned_profile
#check_journal
#swap_check
#check_lvm


#while true; do

#	read -p "Please select question (all or 1-19 or q to quit): " question
#	echo ""
#	case $question in
#		1)
#			check_pw
#			;;
#		2)
#			check_IP
#			;;
#		3)
#			check_repos
#			;;
#		4)
#			check_chrony
#			;;
#		5)
#			validate_autofs
#			;;
#		6)
#			check_grp
#			check_users
#			check_grp_membership
#			check_usr_shell
#			chk_sudo
#			check_umask
#			;;
#		7)
#			check_special_perm
#			check_special_perm2
#			;;
#		8)
#			chk_max_days
#			;;
#		9)
#			chk_enforce_pw
#			chk_acc_exp
#			;;
#		10)
#			chk_grp_pkg
#			;;
#		11)
#			check_selinux
#			;;
#		12)
#			check_bzip2_compression
#			;;
#		13)
#			check_cron
#			;;
#		14)
#			check_tuned_profile
#			;;
#		15)
#			check_journal
#			;;
#		16)
#			swap_check
#			;;
#		17)
#			
#			check_lvm1
#			;;
#		18)
#			check_lvm2
#			;;
#		19)
#			
#			check_lvm3
#			;;
#		20)
#			check_lvm4
#			;;

#		all)
#			check_pw
#			check_IP
#			check_repos
#			check_chrony
#			validate_autofs
#			check_grp
#			check_users
#			check_grp_membership
#			check_usr_shell
#			chk_sudo
#			check_umask
#			check_special_perm
#			check_special_perm2
#			chk_max_days
#			chk_enforce_pw
#			chk_acc_exp
#			chk_grp_pkg
#			check_selinux
#			check_bzip2_compression
#			check_cron
#			check_tuned_profile
#			check_journal
#			swap_check
#			check_lvm
#			;;
#		q)
#			break
#
#
#	    *)
#		    echo "You Did not Select valid Question number"
#		    ;;
#	esac

 #done

#AUTHOR: ZEESHAN ALI (MOON)
