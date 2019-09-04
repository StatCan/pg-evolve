FROM alpine

RUN apk --update --no-cache add docker

RUN apk --update --no-cache add \
    bash \
    git \
  && git clone https://github.com/sstephenson/bats.git \
  && cd bats \
  && ./install.sh /usr/local \
  && cd - \
  && rm -r bats \
  && apk del \
    git
