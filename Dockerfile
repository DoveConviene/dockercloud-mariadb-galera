FROM mariadb:10.1

RUN mv /etc/apt/sources.list.d/percona.list /tmp/percona.list && \
	mv /etc/apt/preferences.d/percona /tmp/percona && \
	mv /etc/apt/sources.list.d/mariadb.list /tmp/mariadb.list && \
	apt-get update -qq && \
	apt-get install -qqy --no-install-recommends apt-transport-https curl jq && \
	rm -rf /var/lib/apt/lists/*	&& \
	mv /tmp/percona.list /etc/apt/sources.list.d/percona.list && \
	mv /tmp/percona /etc/apt/preferences.d/percona && \
	mv /tmp/mariadb.list /etc/apt/sources.list.d/mariadb.list

COPY entrypoint.sh /

EXPOSE 3306 4444 4567 4567/udp 4568

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mysqld"]