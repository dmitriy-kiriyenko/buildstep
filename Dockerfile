FROM progrium/buildstep
MAINTAINER dmitriy-kiriyenko "dmitriy.kiriyenko@gmail.com"

RUN mkdir -p /build
ADD ./stack/ /build
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive /build/prepare
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get clean

ADD run.sh /run.sh
RUN chmod +x /run.sh

ONBUILD RUN mkdir -p /app
ONBUILD ADD . /app
ONBUILD RUN /build/builder

ENTRYPOINT ["/run.sh"]
