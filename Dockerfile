FROM mariadb:10.1

RUN	apt-get update -qq && \
	apt-get install -qqy --no-install-recommends curl jq && \
	rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

EXPOSE 3306 4444 4567 4567/udp 4568

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mysqld"]