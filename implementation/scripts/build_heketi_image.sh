#!/bin/bash
# This script builds a Heketi dockerfile for Arm, because the one in 
# gluster-kubernetes is for x86-64 :( also the go code hardcodes the centos image 
# We're using alpine, so it's a bit leaner, also glide is broken, so we 
# build it... :: sigh ::

cd ~
cat > Dockerfile-Heketi <<-EOF
FROM alpine
MAINTAINER Heketi Developers <heketi-devel@gluster.org>

LABEL version="1.3.1"
LABEL description="Development build"

# let's setup all the necessary environment variables
ENV BUILD_HOME=/build
ENV GOPATH=\$BUILD_HOME/golang
ENV PATH=\$GOPATH/bin:\$PATH
# where to clone from
ENV HEKETI_REPO="https://github.com/heketi/heketi.git"
ENV HEKETI_BRANCH="master"
ENV GOARCH="arm"
ENV GOARM="7"
# install dependencies, build and cleanup
RUN mkdir \$BUILD_HOME \$GOPATH && \
apk add curl wget bash go git make mercurial musl musl-dev gcc openssl libc6-compat libcurl nghttp2-libs libssh2 python2 expat pcre2 libbz2 sqlite-libs gdbm libffi ca-certificates libcurl &&\
mkdir -p \$GOPATH/src/github.com/heketi && \
cd \$GOPATH/src/github.com/heketi && \
git clone -b \$HEKETI_BRANCH \$HEKETI_REPO && \
cd \$GOPATH/src/github.com/heketi/heketi && \
grep -lr 'heketi/heketi:dev' . | xargs sed -i -e 's/heketi\/heketi:dev/localhost:5000\/heketi/g' && \
go get github.com/Masterminds/glide && \
cd \$GOPATH/src/github.com/Masterminds/glide && \
make && make install && \
export PATH=$PATH:/usr/local/bin:\$GOPATH/bin && \
cd \$GOPATH/src/github.com/heketi/heketi && \
glide install -v && \
make && \
mkdir -p /etc/heketi /var/lib/heketi && \
make install prefix=/usr && \
cp /usr/share/heketi/container/heketi-start.sh /usr/bin/heketi-start.sh && \
cp /usr/share/heketi/container/heketi.json /etc/heketi/heketi.json && \
glide cc && \
cd && rm -rf \$BUILD_HOME && \
apk del git make mercurial gcc 

VOLUME /etc/heketi /var/lib/heketi

# expose port, set user and set entrypoint with config option
ENTRYPOINT ["/usr/bin/heketi-start.sh"]
EXPOSE 8080
EOF

docker build -f Dockerfile-Heketi -t heketi:latest .
docker image tag heketi:latest localhost:5000/heketi
docker push localhost:5000/heketi
