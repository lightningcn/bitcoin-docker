FROM resin/rpi-raspbian:stretch as builder

#ADD sources-aliyun.com.list /etc/apt/sources.list
#RUN sh -c 'curl -fsSL "https://mirrors.aliyun.com/docker-ce/linux/raspbian/gpg" | apt-key add -qq - >/dev/null'
#RUN sh -c 'echo "deb [arch=armhf] https://mirrors.aliyun.com/docker-ce/linux/raspbian stretch edge" > /etc/apt/sources.list.d/docker.list'
RUN apt-get update
RUN apt-get install apt-transport-https ca-certificates
#RUN apt-get -qq update
RUN apt-get install -qq --no-install-recommends --allow-unauthenticated -yy \ 
	apt-transport-https ca-certificates dirmngr wget \
    build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 \
    libminiupnpc-dev libzmq3-dev libdb-dev libdb++-dev
  
ENV BITCOIN_VERSION=0.18.0
ENV BITCOIN_PREFIX=/opt/bitcoin-${BITCOIN_VERSION}

RUN set -ex \
  && for key in \
    90C8019E36C2E964 \
  ; do \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done
 
RUN wget https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc
RUN wget https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}.tar.gz
RUN gpg --verify SHA256SUMS.asc
RUN grep " bitcoin-${BITCOIN_VERSION}.tar.gz\$" SHA256SUMS.asc | sha256sum -c -
RUN tar -xzf *.tar.gz

WORKDIR /bitcoin-${BITCOIN_VERSION}

ADD sources-aliyun.com.list /etc/apt/sources.list
RUN apt-get -qq update
RUN apt-get install -qq libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev
 
RUN ./autogen.sh
RUN ./configure \
    --prefix=${BITCOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
	--with-incompatible-bdb \
	--enable-glibc-back-compat \
	--enable-reduce-exports \
	--disable-maintainer-mode \
	--disable-dependency-tracking \
    --with-daemon \
	LDFLAGS="-static-libstdc++" 
RUN make -j4
RUN make install
RUN strip ${BITCOIN_PREFIX}/bin/bitcoin-cli
RUN strip ${BITCOIN_PREFIX}/bin/bitcoin-tx
RUN strip ${BITCOIN_PREFIX}/bin/bitcoind
RUN strip ${BITCOIN_PREFIX}/lib/libbitcoinconsensus.a
#RUN strip ${BITCOIN_PREFIX}/lib/libbitcoinconsensus.so.0.0.0
 

#FROM resin/rpi-raspbian:stretch
#COPY --from=builder "/tmp/bin" /usr/local/bin
#
#RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin
#
## create data directory
#ENV BITCOIN_DATA /data
#RUN mkdir "$BITCOIN_DATA" \
#	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
#	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin \
#	&& chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin
#
#VOLUME /data
#
#COPY docker-entrypoint.sh /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]
#
#EXPOSE 8332 8333 18332 18333 18443 18444
#CMD ["bitcoind"]
