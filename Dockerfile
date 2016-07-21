FROM mariadb:10.1

RUN set -x \
	&& apt-get update && \
	apt-get install -y --no-install-recommends ca-certificates curl jq && \
	rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

EXPOSE 3306 4444 4567 4567/udp 4568

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mysqld"]