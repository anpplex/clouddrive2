# 一键安装 Clouddrive2 脚本
脚本非官方出品。指在帮助纯新手用户快速使用 clouddrive2 挂载网盘。  
脚本中使用的docker镜像与二进制文件均从官方 hub 及 github 仓库下载，请放心使用。

## 目录
- [一键安装 Clouddrive2 脚本](#一键安装-clouddrive2-脚本)
  - [目录](#目录)
  - [安装](#安装)
    - [安装命令](#安装命令)
    - [卸载命令](#卸载命令)
  - [安卓](#安卓)
    - [安装 (未ROOT设备)](#安装-未root设备)
    - [安装 (已ROOT设备)](#安装-已root设备)
    - [卸载](#卸载)
  - [一键开启 SMB 与 NFS 共享](#一键开启-smb-与-nfs-共享)
    - [共享](#共享)
    - [还原共享](#还原共享)
  - [如何更新?](#如何更新)
  - [在哪运行？](#在哪运行)
    - [OpenWRT](#openwrt)
    - [Mac](#mac)
    - [Linux](#linux)
    - [安卓](#安卓-1)
  - [问与答](#问与答)
    - [通规问题](#通规问题)
    - [安装问题](#安装问题)
    - [安装后问题](#安装后问题)
    - [安卓问题](#安卓问题)
  - [聊天反馈吹水群](#聊天反馈吹水群)

支持
- [X] Linux
- [X] MacOS
- [X] OpenWRT(iStore)
- [X] Android-Termux

## 安装
### 安装命令
- Mac、Linux、OpenWRT等 在「终端」运行下面的「命令」  
- 不知道在哪里运行这些命令？[点击查看](#在哪运行)  
- 镜像加速和代理的区别? [点击查看](#通规问题)  
- 由于镜像站经常被墙或其它原因经常变动导致无法使用请用下面的「代理」命令,前提是你有开了代理  
- 优先使用 docker 的安装方式.如果没有docker会使用其它方式安装  
- 以下命令2选1  

```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2.sh" | bash -s install mirror
# 代理
curl -fsSL "https://raw.githubusercontent.com/lonelylose/clouddrive2/main/cd2.sh" | bash -s install
```

### 卸载命令
```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2.sh" | bash -s uninstall mirror
# 代理
curl -fsSL "https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2.sh" | bash -s uninstall
```

## 安卓
安卓在termux里运行下面的「命令」  

### 安装 (未ROOT设备)
- 以下命令2选1  
```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2-termux.sh" | bash -s install mirror
# 代理
curl -fsSL "https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2-termux.sh" | bash -s install
```

### 安装 (已ROOT设备)
- 以下命令2选1  
```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2-termux.sh" | bash -s install root mirror
# 代理
curl -fsSL "https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2-termux.sh" | bash -s install root
```

### 卸载
- 以下命令2选1  
```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2-termux.sh" | bash -s uninstall
# 代理
curl -fsSL "https://raw.githubusercontent.com/sublaim/clouddrive2/main/cd2-termux.sh" | bash -s uninstall
```

## 一键开启 SMB 与 NFS 共享
- **前提是使用一键安装脚本安装的 cd2 且网盘挂载目录为/CloudNAS**  
- 官方自带了 webdav 的方式 [点击查看](#安装后问题)  
- 只支持 Openwrt 系列及其衍生版, 大部分设备可以开启 SMB, NFS能不能开启看固件  
- GL.iNET 设备需要提前在主路由界面 -> 应用程序 -> 网络共享或文件共享 -> 开启 samba  

### 共享
- 以下命令2选1  
```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/shares.sh" | bash -s shares
# 代理
curl -fsSL "https://raw.githubusercontent.com/sublaim/clouddrive2/main/shares.sh" | bash -s shares
```

### 还原共享
- 以下命令2选1  
```shell
# 国内加速(推荐)
curl -fsSL "https://mirror.ghproxy.com/https://raw.githubusercontent.com/sublaim/clouddrive2/main/shares.sh" | bash -s unshares
# 代理
curl -fsSL "https://raw.githubusercontent.com/sublaim/clouddrive2/main/shares.sh" | bash -s unshares
```


## 如何更新?
请使用官方内置的更新方式: 点击右上角的`!`号

<img src="./images/update1.png" width="20%">

<img src="./images/update2.png" width="30%">

## 在哪运行？
### OpenWRT
在左侧菜单里一般有「终端」或「TTYD 终端」，登录用户名一般为root，密码为你的OP密码。  
如果没有, 请使用 ssh 连接.

<img src="./images/op1.png" width="50%">

<img src="./images/op2.png" width="50%">

### Mac
打开「启动器」在上面的「搜索框」搜索「终端」或「terminal」  

第1步  

<img src="./images/mac1.png" width="30%">   
第2步  

<img src="./images/mac2.png" width="70%">   

### Linux
Linux 桌面环境下的「终端」名称不同, 可自行查找

### 安卓
打开「Termux」输入命令并回车

<img src="./images/termux.png" width="20%">


## 问与答
这里解决的问题主要来源于群友的反馈

### 通规问题
**国内镜像加速和代理有什么区别？**  
> *镜像加速优点是不使用代理工具可以运行. 缺点是镜像加速地址经常失效导致命令经常变动.*  
> *代理优点是命令不会变动. 代理缺点是国内无法直接使用需要改hosts或其它代理的方式才能运行.*  

**cd2安装和挂载到哪里?**  
> *安卓默认安装在/data/data/com.termux/files/home/clouddrive/*  
> *其它平台默认安装在 /opt/clouddrive/*  

> *docker推荐挂载点在 /CloudNAS*  
> *Mac推荐挂载点: /Users/你的用户名/Documents*  
> *安卓推荐挂载点: /mnt/runtime/default/emulated/0/你的目录 (注:此目录更容易被新手找到,可读不可写,若想读写可把挂载时权限的`0755`改`0777`)*  
> *安卓推荐挂载点: /mnt/runtime (注:可读写)*  

**Mac无法挂载到指定目录?**
> *「系统偏好设置」->「隐私与安全性」->「完全磁盘访问」->「勾选clouddrive」*

**怎么修改默认的SMB密码?**  
> *smbpasswd -a root*  

### 安装问题  
**-ash: bash: not found or curl: not found**  
**curl: (23) Failure writing output to destination**  
> *多出现在 GL.iNet 品牌下的 MTxxxx设备上.*  
> *使用 opkg install bash curl安装bash即可*  

**curl: (6) Could not resolve host: mirror.ghproxy.com**  
> *DNS设置问题*  

**curl: (7) Failed to connect to mirror.ghproxy.com port 443 after 10 ms: Couldn't connect to server**  
> *网关设置问题*  

**curl: (35) Recv failure: Connection reset by peer**  
> *重启「终端」*  

**一直卡在 正在下载 clouddrive 镜像，请稍候...**  
尝试以下方式解决:  
> *1. 关闭代理包括手机上*  
> *2. 重启dns服务: /etc/init.d/dnsmasq restart*  
> *3. 更换docker配置中的镜像地址由百度换成网易*  

### 安装后问题
**IO Error find fusermount binary failed CannotFindBinaryPath**  
> *FUSE3缺失*  
> *OP使用opkg update && opkg install fuse3-utils libfuse3-3 安装.*  
> *Linux因各发行版不同自行安装*  

**出错了, 请先把cd2中的网盘挂载到本地/CloudNAS目录**  
> *在cd2后台挂载你的网盘到本地*  

**IO error fusemount run failed**  
> *ls /dev/fuse | grep fuse 如果没有没输出则是缺少fuse模块*  

**Mac为什么只能读不能写入文件?**
> *挂载到本地时把默认的0755改成0777*

**重启后 docker 上的 cd2 容器没有自动运行**  
> *把 mount --make-shared / 插入到「启动项」->「本地启动脚本」中的 'exit 0' 之前*  

**登录一直提示连接超时**  
> *用「卸载命令」再重装*

**挂载后 Emby/Jellyfin/Plex 等服务中看不到这个挂载目录**  
> *在 Emby/Jellyfin/Plex 等服务的 docker run 命令中加入 -v /CloudNAS:/CloudNAS 即可将目录挂载到 Emby/Jellyfin 容器*   

**怎么修改为只有指定设备才能访问 NFS 分享的文件(默认不限制)**  
> *在`/etc/config/nfs`文件中把`*`替换为指定设备的IP*  

**怎么卸载macFUSE**  
> *官方的`.dmg`里自带卸载工具*  

**怎么开启SMB V1版本兼容**  
> *默认支持兼容v1等低版本协议*  

**官方自带的 webdav 服务**  
> *服务器：http://<ip>:19798/dav*  
> *用户名：登录CloudDrive的用户Email，或者只填用户Email的用户名部分，不含@及以后的部分*  
> *密码：登录CloudDrive的用户密码*  


### 安卓问题
**为什么 termux 无法挂载网盘到本地？**  
> *非Root用户无法挂载。*  

**已root设备 termux 挂载目录为空**  
> *尝试将 termux 在 SuperUser 类的权限管理工具中来允许获得root权限*  
> *调整 termux 电池省电策略*  
> *检查 termux 进程是否被杀*  

**非 root 设备可以用 root 命令吗？**  
> *不可以，用了会无法启动。*  

## 聊天反馈吹水群
- QQ讨论群: 943950333 ，加群链接：[点击加入](https://qm.qq.com/q/EroEmk0kkq "交流反馈")  

<img src="./images/QRcode.png" width="20%">
