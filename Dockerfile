FROM centos:7

MAINTAINER Alex Laverty <alex@laverty.ws>

LABEL version=1.0.0

ADD files /

ADD app /opt/app

RUN yum clean all && \
    rm -rf /var/cache/yum && \
    yum update -y && \
    yum --enablerepo=extras install -y epel-release && \
    yum install -y \
    gcc \
    epel-release \
    python-devel \
    python-pip \
    python-setuptools \
    nginx

RUN pip install --upgrade pip && \
    pip install -r /requirements.txt

WORKDIR /opt/app

CMD ["gunicorn","--bind","0.0.0.0:8080","wsgi"]

EXPOSE 8080
