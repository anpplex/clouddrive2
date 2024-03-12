#!/usr/bin/env bash
# 本脚本必须配合一键安装 clouddrive 脚本才有效
# https://github.com/sublaim/clouddrive2
chmod +x "$0"

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'

if command -v opkg >/dev/null 2>&1; then
  if command -v docker >/dev/null 2>&1; then
    check_docker="exist"
  else
    if [ -e "/sbin/procd" ]; then
      check_procd="exist"
    else
      echo -e "\r\n${RED_COLOR}出错了，无法确定你当前的 Openwrt 发行版。${RES}\r\n"
      exit 1
    fi
  fi
else
  echo -e "\r\n${RED_COLOR}出错了，无法确定你当前的 Openwrt 发行版。${RES}\r\n"
  exit 1
fi
# 获取挂载路径
if [ "$check_docker" = "exist" ]; then
  mount_root_path=$(grep -A1 "source_path\s*=\s*\"/\"" /Config/config.toml | grep "mount_point" | awk -F'["]' '{print $2}')
  if [ -z "$mount_root_path" ]; then
    echo -e "${RED_COLOR}出错了, 请先把cd2中的网盘挂载到本地/CloudNAS目录${RES}"
    echo -e "${RED_COLOR}如果只挂载 webdav 则至少需要在cd2中挂载一个网盘(不挂载webdav可忽略)${RES}"
    exit 1
  else
    if [[ $mount_root_path != /CloudNAS/* ]]; then
      echo -e "${RED_COLOR}出错了,网盘挂载目录非/CloudNAS${RES}"
      exit 1
    fi
  fi
elif [ "$check_procd" = "exist" ]; then
  mount_root_path=$(grep -A1 "source_path\s*=\s*\"/\"" /Waytech/CloudDrive2/config.toml | grep "mount_point" | awk -F'["]' '{print $2}')
  if [ -z "$mount_root_path" ]; then
    echo -e "${RED_COLOR}出错了, 请先把cd2中的网盘挂载到本地/CloudNAS目录${RES}"
    exit 1
  else
    if [[ $mount_root_path != /CloudNAS/* ]]; then
      echo -e "${RED_COLOR}出错了, 网盘挂载目录非/CloudNAS ${RES}"
      exit 1
    fi
  fi
fi

get-local-ipv4-using-hostname() {
  hostname -I 2>&- | awk '{print $1}'
}

# iproute2
get-local-ipv4-using-iproute2() {
  # OR ip route get 1.2.3.4 | awk '{print $7}'
  ip -4 route 2>&- | awk '{print $NF}' | grep -Eo --color=never '[0-9]+(\.[0-9]+){3}'
}

# net-tools
get-local-ipv4-using-ifconfig() {
  ( ifconfig 2>&- || ip addr show 2>&- ) | grep -Eo '^\s+inet\s+\S+' | grep -Eo '[0-9]+(\.[0-9]+){3}' | grep -Ev '127\.0\.0\.1|0\.0\.0\.0'
}

# 获取本机 IPv4 地址
get-local-ipv4() {
  set -o pipefail
  get-local-ipv4-using-hostname || get-local-ipv4-using-iproute2 || get-local-ipv4-using-ifconfig
}
get-local-ipv4-select() {
  local ips=$(get-local-ipv4)
  local retcode=$?
  if [ $retcode -ne 0 ]; then
      return $retcode
  fi
  grep -m 1 "^192\." <<<"$ips" || \
  grep -m 1 "^172\." <<<"$ips" || \
  grep -m 1 "^10\." <<<"$ips" || \
  head -n 1 <<<"$ips"
}

# 检测
if [[ ! -e /etc/init.d/samba && ! -e /etc/init.d/samba4 && ! -e /etc/init.d/ksmbd ]]; then
  echo -e "${RED_COLOR}出错了, 没有找到 SMB 服务!${RES}"
  SMB_EXIST="no"
fi

if [[ ! -f "/etc/init.d/nfsd" || ! -f "/etc/init.d/nfs" ]]; then
  echo -e "${RED_COLOR}出错了, 没有找到 NFS 服务!${RES}"
  NFS_EXIST="no"
fi

#------------- SMB --------------
SET_SMBS() {
# KSMBD
if [[ -f "/etc/init.d/ksmbd" ]]; then
  echo -e "${GREEN_COLOR}正在更新软件源...${RES}"
  opkg update && opkg install ksmbd-utils > /dev/null
  if ! [ $? -eq 0 ]; then
    echo -e "${RED_COLOR}安装 ksmbd-utils 失败!${RES}"
  fi
  if [ -f /etc/ksmbd/ksmbdpwd.db ]; then
    rm -rf /etc/ksmbd/ksmbdpwd.db
  fi
  # 设置 SMB 密码
  echo -e "${GREEN_COLOR}设置 SMB 默认密码${RES}"
  # 默认密码
  password="123456"
  {
    echo "$password"
    echo "$password"
  } | ksmbd.adduser -a smb
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN_COLOR}设置密码成功${RES}"
    guest="no"
  else
    echo -e "${RED_COLOR}设置密码失败, 将采用匿名的方式${RES}"
    guest="yes"
  fi

  # 兼容低版本
  if ! grep -qE "^\s*option allow_legacy_protocols '1'" /etc/config/ksmbd; then
      sed -i '/config globals/a \ \ \ \ \ \ \ \ option allow_legacy_protocols '\''1'\''' /etc/config/ksmbd
  fi

  if [[ -f "/etc/config/ksmbd" ]]; then
    # 空行分隔
    last_line=$(tail -n 1 "/etc/config/ksmbd")
    if [ ! -z "$last_line" ]; then
        echo >> "/etc/config/ksmbd"
    fi
    if ! grep -qE "option name 'cd2'" /etc/config/ksmbd && ! grep -qE "option path '/CloudNAS'" /etc/config/ksmbd; then
      cat << EOF >> /etc/config/ksmbd
config share
	option path '/CloudNAS'
	option read_only 'no'
	option force_root '1'
	option create_mask '0777'
	option dir_mask '0777'
	option name 'cd2'
	option inherit_owner 'yes'
	option hide_dot_files 'no'
	option guest_ok '${guest}'
	option users 'smb'
EOF
    fi
  /etc/init.d/ksmbd restart
  KSMBD="yes"
  else
    echo -e "${RED_COLOR}没有找到 ksmbd 的配置文件!${RES}"
  fi
fi

# SAMBA AND SAMBA4
if [[ -f "/etc/init.d/samba" || -f "/etc/init.d/samba4" ]]; then
  if [[ -f "/etc/init.d/samba" ]]; then
    SMB_VERSION="samba"
  elif [[ -f "/etc/init.d/samba4" ]]; then
    SMB_VERSION="samba4"
  fi
  # 设置 SMB 密码
  echo -e "${GREEN_COLOR}设置 SMB 默认密码${RES}"
  # 默认密码
  password="123456"
  {
    echo "$password"
    echo "$password"
  } | smbpasswd -a root
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN_COLOR}设置密码成功${RES}"
  else
    echo -e "${RED_COLOR}设置密码失败,请重新尝试运行${RES}"
  fi
  # 设置 root 用户
  if ! grep -q "#invalid users = root" /etc/samba/smb.conf.template; then
      if grep -q "invalid users = root" /etc/samba/smb.conf.template; then
          sed -i 's/invalid users = root/#invalid users = root/g' /etc/samba/smb.conf.template
      else
          echo -e "\t#invalid users = root" >> /etc/samba/smb.conf.template
      fi
  fi
  
  # 兼容低版本协议
  if ! grep -q "server min protocol = NT1" /etc/samba/smb.conf.template; then
      echo -e "\tserver min protocol = NT1" >> /etc/samba/smb.conf.template
  fi
  if ! grep -qE "^\s*option allow_legacy_protocols '1'" /etc/config/${SMB_VERSION}; then
      sed -i '/config samba/a \ \ \ \ \ \ \ \ option allow_legacy_protocols '\''1'\''' /etc/config/${SMB_VERSION}
  fi
  # 空行分隔
  last_line=$(tail -n 1 "/etc/config/${SMB_VERSION}")
  if [ ! -z "$last_line" ]; then
      echo >> "/etc/config/${SMB_VERSION}"
  fi
  if ! grep -qE "option name 'cd2'" /etc/config/${SMB_VERSION} && ! grep -qE "option path '/CloudNAS'" /etc/config/${SMB_VERSION}; then
    cat << EOF >> /etc/config/${SMB_VERSION}
config sambashare
  option name 'cd2'
  option path '/CloudNAS'
  option read_only 'no'
  option dir_mask '0777'
  option force_root '1'
  option inherit_owner 'yes'
  option create_mask '0777'
  option guest_ok 'no'
  option users 'root'
EOF
  fi
  
  /etc/init.d/${SMB_VERSION} restart
  SAMBA="yes"
  if ! [ $? -eq 0 ]; then
    echo -e "${RED_COLOR}重启服务失败!${RES}\r\n"
    echo -e "${RED_COLOR}如果是GL.iNET 设备需要提前在主路由界面 -> 应用程序 -> 网络共享或文件共享 -> 开启 samba${RES}"
  fi
  echo -e "${GREEN_COLOR}SMB 设置完毕${RES}"
fi
}



# 备份 SMB 默认配置
BACKUP_SMB_CONFIGS() {
# ksmbd
if [ -f "/etc/config/ksmbd" ]; then
  if ! [ -f "/etc/config/ksmbd.bak" ]; then
    cp /etc/config/ksmbd /etc/config/ksmbd.bak
  fi
fi

# samba and samb4
if [[ -f "/etc/init.d/samba" ]]; then
    SMB_VERSION="samba"
elif [[ -f "/etc/init.d/samba4" ]]; then
  SMB_VERSION="samba4"
fi

if [ -f "/etc/config/${SMB_VERSION}" ]; then
  if ! [ -f "/etc/config/${SMB_VERSION}.bak" ]; then
    cp /etc/config/${SMB_VERSION} /etc/config/${SMB_VERSION}.bak
  fi
fi

if [ -f "/etc/samba/smb.conf.template" ]; then
  if ! [ -f "/etc/samba/smb.conf.template.bak" ]; then
    cp /etc/samba/smb.conf.template /etc/samba/smb.conf.template.bak
  fi
fi

if [ -f "/etc/samba/smb.conf" ]; then
  if ! [ -f "/etc/samba/smb.conf.bak" ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
    ln -sf /var/etc/smb.conf /etc/samba/smb.conf
  fi
fi
}


# 还原 SMB 默认配置
RESTORE_SMB_CONFIGS() {
# ksmbd
if [ -f "/etc/config/ksmbd.bak" ]; then
  if ! [ -f "/etc/config/ksmbd" ]; then
    mv /etc/config/ksmbd.bak /etc/config/ksmbd
  else
    rm -rf /etc/config/ksmbd
    mv /etc/config/ksmbd.bak /etc/config/ksmbd
  fi
fi

# sabma and samba4
if [[ -f "/etc/init.d/samba" ]]; then
  SMB_VERSION="samba"
elif [[ -f "/etc/init.d/samba4" ]]; then
  SMB_VERSION="samba4"
fi

if [ -f "/etc/config/${SMB_VERSION}.bak" ]; then
  if ! [ -f "/etc/config/${SMB_VERSION}" ]; then
    mv /etc/config/${SMB_VERSION}.bak /etc/config/${SMB_VERSION}
  else
    rm -rf /etc/config/${SMB_VERSION}
    mv /etc/config/${SMB_VERSION}.bak /etc/config/${SMB_VERSION}
  fi
fi

if [ -f "/etc/samba/smb.conf.template.bak" ]; then
  if ! [ -f "/etc/samba/smb.conf.template" ]; then
    mv /etc/samba/smb.conf.template.bak /etc/samba/smb.conf.template
  else
    rm -rf /etc/samba/smb.conf.template
    mv /etc/samba/smb.conf.template.bak /etc/samba/smb.conf.template
  fi
fi

if [ -f "/etc/samba/smb.conf.bak" ]; then
  if ! [ -f "/etc/samba/smb.conf" ]; then
    mv /etc/samba/smb.conf.bak /etc/samba/smb.conf
    ln -sf /var/etc/smb.conf /etc/samba/smb.conf
  else
    rm -rf /etc/samba/smb.conf
    mv /etc/samba/smb.conf.bak /etc/samba/smb.conf
    ln -sf /var/etc/smb.conf /etc/samba/smb.conf
  fi
fi

}

#------------- NFS --------------
# 备份默认 NFS 配置
BACKUP_NFS_CONFIGS(){
if [ -f "/etc/config/nfs" ]; then
  if ! [ -f "/etc/config/nfs.bak" ]; then
    cp /etc/config/nfs /etc/config/nfs.bak
  fi
fi

if [ -f "/etc/exports" ]; then
  if ! [ -f "/etc/exports.bak" ]; then
    cp /etc/exports /etc/exports.bak
  fi
fi
}

# 还原默认 NFS 配置
RESTORE_NFS_CONFIGS() {
if [ -f "/etc/config/nfs.bak" ]; then
  if ! [ -f "/etc/config/nfs" ]; then
    mv /etc/config/nfs.bak /etc/config/nfs
  else
    rm -rf /etc/config/nfs
    mv /etc/config/nfs.bak /etc/config/nfs
  fi
fi

if [ -f "/etc/exports.bak" ]; then
  if ! [ -f "/etc/exports" ]; then
    mv /etc/exports.bak /etc/exports
  else
    rm -rf /etc/exports
    mv /etc/exports.bak /etc/exports
  fi
fi
}

SET_NFS() {
if [[ -f "/etc/init.d/nfsd" || -f "/etc/init.d/nfs" ]]; then
  if [[ -f "/etc/config/nfs" ]]; then
  # 空行分隔
    last_line=$(tail -n 1 "/etc/config/nfs")
    if [ ! -z "$last_line" ]; then
      echo >> "/etc/config/nfs"
    fi
    if ! grep -qE "option path '$mount_root_path'" /etc/config/nfs; then
      cat << EOF >> "/etc/config/nfs"
config share
	option clients '*'
	option options 'rw,fsid=1,sync,nohide,no_subtree_check,insecure,no_root_squash'
	option path '$mount_root_path'
	option enabled '1'
EOF
    fi
  fi
  if [[ -f "/etc/init.d/nfsd" ]]; then
    /etc/init.d/nfsd restart
  fi
  if [[ -f "/etc/init.d/nfs" ]]; then
    /etc/init.d/nfs restart
  fi
  if ! [ $? -eq 0 ]; then
    echo -e "${RED_COLOR}重启服务失败!${RES}"
  else
    echo -e "${GREEN_COLOR}NFS 设置完毕${RES}"
    if ! grep -qE "^\(sleep 10; exportfs -r\) &$" "/etc/rc.local"; then
      sed -i '/exit 0/i\(sleep 10; exportfs -r) &' "/etc/rc.local"
    fi
  fi
else
  echo -e "${RED_COLOR}找不到 NFS 服务${RES}"
  eixt 1
fi
}


UNSHARE() {
if [[ -f "/etc/init.d/ksmbd" ]]; then
  /etc/init.d/ksmbd restart
fi
if [[ -f "/etc/init.d/samba" ]]; then
  /etc/init.d/samba restart
fi
if [[ -f "/etc/init.d/samba4" ]]; then
  /etc/init.d/samba4 restart
fi

if [[ -f "/etc/init.d/nfsd" ]]; then
  /etc/init.d/nfsd restart
fi
if [[ -f "/etc/init.d/nfs" ]]; then
  /etc/init.d/nfs restart
fi
echo -e "\r\n${GREEN_COLOR}SMB/NFS共享已在系统中还原！${RES}\r\n"
}


SUCCESS() {
clear
# SMB
echo -e "${GREEN_COLOR}请用您的设备连接以下可用的共享服务(请以实际IP为准)${RES}\r\n"
if [ "$SMB_EXIST" = "no" ]; then
  echo -e "${GREEN_COLOR}SMB 设置失败:${RES}"
  echo -e "${RED_COLOR}失败原因: 没有找到 SMB 服务${RES}"
else
  if [ "$KSMBD" = "yes" ] && [ "$SAMBA" = "yes" ]; then
    echo -e "${GREEN_COLOR}系统有多种 SMB 协议, 建议停用一种:${RES}"
  fi
  if [ "$KSMBD" = "yes" ]; then
    echo -e "${GREEN_COLOR}SMB 设置成功:${RES}"
    echo -e "SMB主机IP：${GREEN_COLOR}$(get-local-ipv4-select)${RES}"
    echo -e "SMB用户名：${GREEN_COLOR}smb${RES}"
    echo -e "SMB默认密码：${GREEN_COLOR}$password${RES}"
    echo -e "SMB端口：${GREEN_COLOR}445 (可选)${RES}"
    echo -e "SMB路径：${GREEN_COLOR}/ (可选)${RES}\r\n"
  fi
  if [ "$SAMBA" = "yes" ]; then
    echo -e "${GREEN_COLOR}SMB 设置成功:${RES}"
    echo -e "SMB主机IP：${GREEN_COLOR}$(get-local-ipv4-select)${RES}"
    echo -e "SMB用户名：${GREEN_COLOR}root${RES}"
    echo -e "SMB默认密码：${GREEN_COLOR}$password${RES}"
    echo -e "SMB端口：${GREEN_COLOR}445 (可选)${RES}"
    echo -e "SMB路径：${GREEN_COLOR}/ (可选)${RES}\r\n"
  fi
fi

# NFS
if [ "$NFS_EXIST" = "no" ]; then
  echo -e "${GREEN_COLOR}NFS 设置失败:${RES}"
  echo -e "${RED_COLOR}失败原因: 没有找到 NFS 服务${RES}"
else
  echo -e "${GREEN_COLOR}NFS 设置成功:${RES}"
  echo -e "NFS主机IP：${GREEN_COLOR}$(get-local-ipv4-select)${RES}"
  echo -e "NFS端口：${GREEN_COLOR}2049 (可选)${RES}"
  echo -e "NFS路径：${GREEN_COLOR}/ (可选)${RES}\r\n"
fi
}

if [ "$1" = "unshares" ]; then
  RESTORE_SMB_CONFIGS
  RESTORE_NFS_CONFIGS
  UNSHARE
elif [ "$1" = "shares" ]; then
  if ! [ "$SMB_EXIST" = "no" ]; then
    BACKUP_SMB_CONFIGS
    SET_SMBS
  fi
  if ! [ "$NFS_EXIST" = "no" ]; then
    BACKUP_NFS_CONFIGS
    SET_NFS
  fi
  SUCCESS
else
  echo -e "${RED_COLOR} 错误的命令${RES}"
fi
