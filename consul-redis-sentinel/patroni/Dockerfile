ARG PG_MAJOR=10
ARG LC_ALL=C.UTF-8
ARG LANG=C.UTF-8

FROM postgres:$PG_MAJOR

RUN export DEBIAN_FRONTEND=noninteractive && \
    echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend && \
    apt-get update -y && \
    apt-get install -y gcc python3-dev python3-pip libpq-dev
RUN pip3 install --upgrade pip setuptools

COPY ./requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

COPY ./patroni.yml /config/patroni.yml
ENTRYPOINT ["patroni", "/config/patroni.yml"]