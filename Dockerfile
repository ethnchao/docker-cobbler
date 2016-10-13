FROM centos:latest
MAINTAINER ethnchao <maicheng.linyi@gmail.com>

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done);
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

RUN curl http://mirrors.aliyun.com/repo/epel-7.repo -o /etc/yum.repos.d/epel.repo \
    && mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak \
    && curl http://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/CentOS-Base.repo \
    && yum -y install \
        cobbler \
        cobbler-web \
        dhcp bind \
        syslinux \
        pykickstart \
        patch \
        file \
        initscripts \
        xinetd \
    && yum clean all

ADD files/ubuntu-server.seed /var/lib/cobbler/kickstarts/ubuntu-server.seed
ADD files/post_install_network_config_deb /var/lib/cobbler/snippets/post_install_network_config_deb
ADD files/distro_signatures.patch /tmp/distro_signatures.patch
RUN systemctl enable cobblerd httpd dhcpd \
    && patch --binary /var/lib/cobbler/distro_signatures.json < /tmp/distro_signatures.patch \
    && rm -f /tmp/distro_signatures.patch \
    && sed -i -e 's/\(.*disable.*=\) yes/\1 no/' /etc/xinetd.d/tftp \
    && touch /etc/xinetd.d/rsync

RUN ln -sf "/usr/share/zoneinfo/Asia/Shanghai" /etc/localtime

EXPOSE 69
EXPOSE 80
EXPOSE 443
EXPOSE 25151

VOLUME [ "/sys/fs/cgroup" ]

CMD [ "/sbin/init" ]
