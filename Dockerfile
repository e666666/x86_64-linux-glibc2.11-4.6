# This dockerfile is meant to be dynamic in that it downloads packages (other than via apt-get) via the internet
FROM ubuntu:10.04

# This Ubuntu doesn't have its packages on the normal server anymore
RUN sed -i -e "s/archive.ubuntu.com/old-releases.ubuntu.com/g" /etc/apt/sources.list

# Get some starter things
RUN apt-get update
RUN apt-get install tar wget gcc g++ make nano libc6-dev-i386 python-pip python-dev -y
RUN apt-get install python-argparse build-essential ia32-libs gcc-multilib g++-multilib -y
RUN apt-get install git-core python libcurl4-openssl-dev libz-dev gettext zlib1g-dev -y
RUN apt-get install checkinstall libgnutls-dev curl autoconf libtool -y
# Upgrade everything
RUN apt-get dist-upgrade -y

# Build new OpenSSL (needed for newer git and https to work)
WORKDIR /usr/local
ARG opensslVer=1.1.1i
RUN wget https://www.openssl.org/source/openssl-${opensslVer}.tar.gz
RUN wget https://www.openssl.org/source/openssl-${opensslVer}.tar.gz.sha1 -O openssl.sha1
RUN sha1sum openssl-${opensslVer}.tar.gz > openssl.tar.gz.calc.sha1
# verify SHA1
RUN python -c "assert open('openssl.sha1').read().strip() in open('openssl.tar.gz.calc.sha1').read().strip()"
# Continue with OpenSSL
RUN tar -xvzf openssl-${opensslVer}.tar.gz
WORKDIR /usr/local/openssl-${opensslVer}
RUN ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
RUN make -j4
RUN make install
RUN echo "/usr/local/openssl/lib" >> /etc/ld.so.conf.d/openssl.conf
RUN ldconfig -v
RUN /usr/local/openssl/bin/openssl version
RUN rm -rf /usr/local/openssl-${opensslVer}.tar.gz /usr/local/openssl-${opensslVer}

# Build new Git
ARG gitVer=2.30.0
WORKDIR /usr/local
RUN wget --no-check-certificate https://mirrors.edge.kernel.org/pub/software/scm/git/git-${gitVer}.tar.gz
RUN tar -xvzf git-${gitVer}.tar.gz
WORKDIR /usr/local/git-${gitVer}
RUN ./configure --with-openssl=/usr/local/openssl
RUN make -j4
RUN make install
RUN git --version
RUN echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /etc/ssh/ssh_config
RUN rm -rf /usr/local/git-${gitVer}.tar.gz /usr/local/git-${gitVer}

# Build new curl with new OpenSSL for Git
WORKDIR /usr/local
# Is the commit id below safe enough to say SSL_NO_VERIFY is ok?
RUN GIT_SSL_NO_VERIFY=true git clone https://github.com/curl/curl.git
WORKDIR /usr/local/curl
RUN git checkout 432eb5f5c254ee8383b2522ce597c9219877923e
RUN ./buildconf
RUN LIBS="-ldl" ./configure --with-ssl=/usr/local/openssl --disable-shared
RUN make -j4
RUN make install
RUN curl --version
RUN rm -rf /usr/local/curl

# Download the latest .pem file for https connections via curl
RUN /usr/local/curl/src/curl https://curl.haxx.se/ca/cacert.pem -o /cacert.pem
# Tell git to use the new certs
RUN echo "[http]" >> ~/.gitconfig
RUN echo "sslCAinfo = /cacert.pem" >> ~/.gitconfig

# Spawn shell
WORKDIR /
CMD "/bin/bash"
