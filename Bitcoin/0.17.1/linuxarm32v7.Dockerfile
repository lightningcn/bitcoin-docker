# Use manifest image which support all architecture
FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu wget qemu qemu-user-static qemu-user binfmt-support

ENV BITCOIN_VERSION 0.17.1
ENV BITCOIN_URL https://bitcoincore.org/bin/bitcoin-core-0.17.1/bitcoin-0.17.1-arm-linux-gnueabihf.tar.gz
ENV BITCOIN_SHA256 aab3c1fb92e47734fadded1d3f9ccf0ac5a59e3cdc28c43a52fcab9f0cb395bc

# install bitcoin binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.tar.gz" | sha256sum -c - \
	&& mkdir bin \
	&& tar -xzvf bitcoin.tar.gz -C /tmp/bin --strip-components=2 "bitcoin-$BITCOIN_VERSION/bin/bitcoin-cli" "bitcoin-$BITCOIN_VERSION/bin/bitcoind" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-armhf" \
	&& echo "171b4a2decc920de0dd4f49278d3e14712da5fa48de57c556f99bcdabe03552e gosu" | sha256sum -c -

# Making sure the builder build an arm image despite being x64
FROM arm32v7/debian:stretch-slim

COPY --from=builder "/tmp/bin" /usr/local/bin
#EnableQEMU COPY qemu-arm-static /usr/bin
COPY --from=builder /usr/bin/qemu-arm-static /usr/bin/qemu-arm-static

RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8332 8333 18332 18333 18443 18444
CMD ["bitcoind"]
