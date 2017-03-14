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

RUN yum -y install epel-release \
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

ADD files/post_install_network_config_deb /var/lib/cobbler/snippets/post_install_network_config_deb
ADD files/post_install_mtenance_publickey /var/lib/cobbler/snippets/post_install_mtenance_publickey
ADD files/post_install_apt_packages /var/lib/cobbler/snippets/post_install_apt_packages
ADD files/preseed_late_default /var/lib/cobbler/scripts/preseed_late_default
ADD files/distro_signatures.patch /tmp/distro_signatures.patch
RUN systemctl enable cobblerd httpd dhcpd \
    && cp /var/lib/cobbler/kickstarts/sample.seed /var/lib/cobbler/kickstarts/sample_oribak.seed \
    && cp /var/lib/cobbler/kickstarts/sample_end.ks /var/lib/cobbler/kickstarts/sample_oribak.ks \
    && cp /var/lib/cobbler/distro_signatures.json /var/lib/cobbler/backup_distro_signatures.json \
    && patch --binary /var/lib/cobbler/distro_signatures.json < /tmp/distro_signatures.patch \
    && rm -f /tmp/distro_signatures.patch \
    && sed -i -e 's/\(.*disable.*=\) yes/\1 no/' /etc/xinetd.d/tftp \
    && touch /etc/xinetd.d/rsync
ADD files/ubuntu-server.seed /var/lib/cobbler/kickstarts/sample.seed
ADD files/sample_end.ks /var/lib/cobbler/kickstarts/sample_end.ks

RUN ln -sf "/usr/share/zoneinfo/Asia/Shanghai" /etc/localtime

EXPOSE 69
EXPOSE 80
EXPOSE 443
EXPOSE 25151

VOLUME [ "/sys/fs/cgroup" ]

CMD [ "/sbin/init" ]
