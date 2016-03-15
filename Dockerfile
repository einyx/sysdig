FROM debian:unstable

MAINTAINER Alessio <alessio.garofalo@style.com>

ENV LOGSTASH_MAJOR 2.2
ENV LOGSTASH_VERSION 1:2.2.2-1

ENV SYSDIG_REPOSITORY stable
ENV SYSDIG_HOST_ROOT /host
ENV HOME /root

LABEL RUN="docker run -i -t --privileged -v /var/run/docker.sock:/host/var/run/docker.sock -v /dev:/host/dev -v /proc:/host/proc:ro -v /boot:/host/boot:ro -v /lib/modules:/host/lib/modules:ro -v /usr:/host/usr:ro --name NAME IMAGE"

RUN cp /etc/skel/.bashrc /root && cp /etc/skel/.profile /root

ADD http://download.draios.com/apt-draios-priority /etc/apt/preferences.d/
ADD logstash.conf /etc/logstash.conf 

RUN apt-get update && apt-get -y install curl
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys EEA14886
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
RUN curl -s https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public | apt-key add - \
 && curl -s -o /etc/apt/sources.list.d/draios.list http://download.draios.com/$SYSDIG_REPOSITORY/deb/draios.list
RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_MAJOR}/debian stable main" > /etc/apt/sources.list.d/logstash.list
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
	&& echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
	&& echo debconf shared/accepted-oracle-license-v1-1 select true | \
		debconf-set-selections \
	&& echo debconf shared/accepted-oracle-license-v1-1 seen true | \
  		debconf-set-selections

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
	bash-completion \
    oracle-java8-installer \
    logstash=$LOGSTASH_VERSION \
    sysdig \
	curl \
	ca-certificates \
	gcc \
	gcc-4.9 \
	gcc-4.8

# revert the default to gcc 4.9
RUN rm -rf /usr/bin/gcc \
 && ln -s /usr/bin/gcc-4.9 /usr/bin/gcc \
 && ln -s /usr/bin/gcc-4.8 /usr/bin/gcc-4.7 \
 && ln -s /usr/bin/gcc-4.8 /usr/bin/gcc-4.6

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN ln -s $SYSDIG_HOST_ROOT/lib/modules /lib/modules

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["bash"]
