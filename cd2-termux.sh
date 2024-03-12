#!/data/data/com.termux/files/usr/bin/bash
#set -x
chmod +x "$0"

if [ ! -n "$2" ]; then
  echo -e "\r\n${YELLOW_COLOR}非 Root 方式${RES}\r\n" 1>&2
  CHECK_ROOT="notroot"
  mirror=""
else
  if [[ $2 == "root" && ! -n "$3" ]]; then
    echo -e "\r\n${YELLOW_COLOR}Root 方式${RES}\r\n" 1>&2
    CHECK_ROOT="root"
    mirror=""
    pkg install tsu -y
  elif [[ $2 == "mirror" && ! -n "$3" ]]; then
    echo -e "\r\n${YELLOW_COLOR}使用镜像 ${3}${RES}\r\n" 1>&2
    mirror="https://mirror.ghproxy.com/"
    CHECK_ROOT="notroot"
  elif [[ "$2" != "root" && "$2" != "mirror" ]]; then
    echo -e "${RED_COLOR}命令错误${RES}"
    exit 1
  else
    if [[ $2 == "root" && $3 == "mirror" ]]; then
      echo -e "\r\n${YELLOW_COLOR}Root 方式${RES}\r\n" 1>&2
      CHECK_ROOT="root"
      pkg install tsu -y
      echo -e "\r\n${YELLOW_COLOR}使用镜像 ${3}${RES}\r\n" 1>&2
      mirror="https://mirror.ghproxy.com/"
    elif [[ $2 == "mirror" && $3 == "root" ]]; then
      echo -e "\r\n${YELLOW_COLOR}Root 方式${RES}\r\n" 1>&2
      CHECK_ROOT="root"
      pkg install tsu -y
      echo -e "\r\n${YELLOW_COLOR}使用镜像 ${3}${RES}\r\n" 1>&2
      mirror="https://mirror.ghproxy.com/"
    else
      echo -e "${RED_COLOR}命令错误${RES}"
      exit 1
    fi
  fi
fi


RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'

# Get platform
if command -v uname >/dev/null 2>&1; then
  platform=$(uname -m)
else
  platform=$(arch)
fi

ARCH="UNKNOWN"

if [ "$platform" = "x86_64" ]; then
  ARCH="x86_64"
elif [ "$platform" = "arm64" ]; then
  ARCH="aarch64"
elif [ "$platform" = "aarch64" ]; then
  ARCH="aarch64"
elif [ "$platform" = "armv7l" ]; then
  ARCH="armv7"
else
  echo -e "${RED_COLOR}不支持的架构${RES}"
  exit 1
fi

pkg install termux-services -y
if [ $? -eq 0 ]; then
  echo -e "下载完成"
else
  echo -e "${RED_COLOR}网络中断，请检查网络${RES}"
  exit 1
fi
INSTALL() {
  # Download FUSE
  if [[ "$CHECK_ROOT" == "root" ]]; then
    echo -e "\r\n${GREEN_COLOR}下载 FUSE $VERSION ...${RES}"
    if [[ "$ARCH" == "aarch64" ]]; then
      curl -L https://xdaforums.com/attachments/fusermount_arm64-v8a-zip.4641672/ -o $HOME/fuse.zip $CURL_BAR
    elif [[ "$ARCH" == "armv7" ]]; then
      curl -L https://xdaforums.com/attachments/fusermount_armeabi-v7a-zip.4641674/ -o $HOME/fuse.zip $CURL_BAR
    else
      echo -e "${RED_COLOR}不支持的架构${RES}"
    fi
    
    if [ $? -eq 0 ]; then
      echo -e "FUSE 下载完成"
    else
      echo -e "${RED_COLOR}网络中断，请检查网络${RES}"
      exit 1
    fi
    unzip $HOME/fuse.zip -d $PREFIX/bin
    mv $PREFIX/bin/fusermount $PREFIX/bin/fusermount3
    chmod 700 $PREFIX/bin/fusermount3
    rm -rf $HOME/fuse.zip
  fi
  # Download clouddrive2
  mkdir -p $HOME/clouddrive
  INSTALL_PATH=$HOME/clouddrive
  clouddrive_version=$(curl -s https://api.github.com/repos/cloud-fs/cloud-fs.github.io/releases/latest | grep -Eo "\s\"name\": \"clouddrive-2-android-$ARCH-.+?\.tgz\"" | awk -F'"' '{print $4}')
  echo -e "\r\n${GREEN_COLOR}下载 clouddrive2 $VERSION ...${RES}"
  curl -L ${mirror}https://github.com/cloud-fs/cloud-fs.github.io/releases/latest/download/$clouddrive_version -o $HOME/clouddrive.tgz $CURL_BAR
  if [ $? -eq 0 ]; then
    echo -e "clouddrive 下载完成"
  else
    echo -e "${RED_COLOR}网络中断，请检查网络${RES}"
    exit 1
  fi
  tar zxf $HOME/clouddrive.tgz -C $INSTALL_PATH/
  mv $INSTALL_PATH/clouddrive-2*/* $INSTALL_PATH/ && rm -rf $INSTALL_PATH/clouddrive-2*
  if [ -f $INSTALL_PATH/clouddrive ]; then
    echo -e "${GREEN_COLOR}校验文件成功\r\n${RES}"
  else
    echo -e "${RED_COLOR}校验 clouddrive-2-android-$platform.tgz 文件失败！${RES}"
    exit 1
  fi
  # remove temp
  rm -rf $HOME/clouddrive.tgz
}

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

DAEMON() {
  if [[ "$CHECK_ROOT" == "root" ]]; then
    cd_start="sudo nsenter -t 1 -m -- /bin/bash -c \"cd /data/data/com.termux/files/home/clouddrive/ && sudo ./clouddrive\""
  else
    cd_start="cd /data/data/com.termux/files/home/clouddrive/ && ./clouddrive"
  fi
  mkdir -p $PREFIX/var/service/clouddrive && touch $PREFIX/var/service/clouddrive/run
  cat >$PREFIX/var/service/clouddrive/run <<EOF 
#!/data/data/com.termux/files/usr/bin/sh
$cd_start
EOF
  chmod +x $PREFIX/var/service/clouddrive/run
  sv up clouddrive && sv-enable clouddrive
}

SUCCESS() {
  clear
  echo -e "${GREEN_COLOR}clouddrive2 安装成功！${RES}"
  echo -e "${YELLOW_COLOR}重启 termux 后生效, 使用时需要保持 termux 运行${RES}"
  echo -e "访问地址：${GREEN_COLOR}http://$(get-local-ipv4-select):19798/${RES}\r\n"
}

UNINSTALL() {
  clear
  echo -e "\r\n${GREEN_COLOR}卸载 clouddrive2 ...${RES}\r\n"
  echo -e "${GREEN_COLOR}停止进程${RES}"
  if [[ "$CHECK_ROOT" == "root" ]]; then
    echo -e "${GREEN_COLOR}清除残留文件${RES}"
    rm -rf $PREFIX/bin/fusermount3
  fi
  rm -rf $PREFIX/var/service/clouddrive && rm -rf $HOME/clouddrive
  echo -e "\r\n${GREEN_COLOR}clouddrive2 已在系统中移除！${RES}\r\n"
}

# CURL 进度显示
if curl --help | grep progress-bar >/dev/null 2>&1; then # $CURL_BAR
  CURL_BAR="--progress-bar"
fi

if [ "$1" = "uninstall" ]; then
  UNINSTALL
elif [ "$1" = "install" ]; then
    INSTALL
    DAEMON
    if [ -f "$INSTALL_PATH/clouddrive" ]; then
      SUCCESS
    else
      echo -e "${RED_COLOR} 安装失败${RES}"
    fi
else
  echo -e "${RED_COLOR} 错误的命令${RES}"
fi
