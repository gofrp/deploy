#!/bin/bash

#Check if git is installed.
type git
if [ $? != 0 ]; then 
echo "git is required for installation, exit."
exit 1
fi
#Set flags for hot update.

frps_FLAG=`ps -ef |grep -w frps|grep -v grep|wc -l`
frpc_FLAG=`ps -ef |grep -w frpc|grep -v grep|wc -l`

#Force stop services before upgrade.

systemctl stop frps

systemctl stop frpc

#Detect the arch.

case $(uname -m) in
    "x86_64")
        ARCH="amd64"
        ;;
    "i*86")
        ARCH="386"
        ;;
    "arm64")
        ARCH="arm64"
        ;;
    "armhf")
        ARCH="arm"
        ;;
    "mips64")
        ARCH="mips64"
        ;;
    "mips64le")
        ARCH="mips64le"
        ;;
    "mips")
        ARCH="mips"
        ;;
    *)
        echo "Unsupport architecture." && exit 0
esac
echo "Detected ${ARCH} architecture."
#Get latest release tag
RELEASETAG=$(git ls-remote --tags https://github.com/fatedier/frp | sort -t '/' -k 2 -V | sed -e '/\^/d')
export FRP_VERSION=${RELEASETAG:0-6}
echo "The latest frp release is ${FRP_VERSION}"
mkdir -p /etc/frp

rm -rf /tmp/frp_${FRP_VERSION}_linux_${ARCH}*
cd /tmp
 echo "Downloading tar package from Github......"
 wget -q "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz"
 echo "Download complete."
 echo "Unpacking......"
 tar xzf frp_${FRP_VERSION}_linux_${ARCH}.tar.gz
 echo "Installing binary files......"
 cp ./frp_${FRP_VERSION}_linux_${ARCH}/frps /usr/local/bin && chmod +x /usr/local/bin/frps
 cp ./frp_${FRP_VERSION}_linux_${ARCH}/frpc /usr/local/bin && chmod +x /usr/local/bin/frpc
 setcap cap_net_bind_service=ep /usr/local/bin/frps #Give frps binary access to well-known ports(smbd,NetBIOS,etc).
 echo "Installing configuration files......"
 test -e /etc/frp/frpc.ini && echo "Configuration files exist. Do not copy templetes." || (echo "Configuration files do not exist. Copy templetes." && cp ./frp_${FRP_VERSION}_linux_${ARCH}/frp*.ini /etc/frp)
 echo "Configuration file is installed to /etc/frp ."

 #Fix systemctl warning.
 cp ./frp_${FRP_VERSION}_linux_${ARCH}/systemd/* /lib/systemd/system
 systemctl daemon-reload

 echo "Install complete."
 echo "See https://github.com/fatedier/frp/blob/master/README.md for configuration."
 echo "Use \"systemctl start frps\" or \"systemctl start frpc\" to start frpc\frps service."

 #Auto restart services.

 if [ $frps_FLAG ]
 then
   systemctl start frps
 elif [ $frpc_FLAG ]
 then
   systemctl start frpc
 fi 

 #systemctl enable frps
 #systemctl enable frpc

 rm -rf /tmp/frp_${FRP_VERSION}_linux_${ARCH}*