FROM centos:7

ENV container=docker

RUN yum -y --setopt=tsflags=nodocs upgrade \
    && yum -y --setopt=tsflags=nodocs install pcs which \
    && yum -y clean all

RUN mkdir -p /etc/systemd/system-preset/
RUN echo 'enable pcsd.service' > /etc/systemd/system-preset/00-pcsd.preset
RUN systemctl enable pcsd

EXPOSE 2224

CMD ["/usr/lib/systemd/systemd", "--system"]
