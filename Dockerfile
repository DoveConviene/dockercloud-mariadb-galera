FROM mariadb:10.1

Run apt-get update -v && apt-get install -vy \
    apt-transport-https \
    ca-certificates \
	curl \
	jq \
	&& \
	rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

EXPOSE 3306 4444 4567 4567/udp 4568

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mysqld"]