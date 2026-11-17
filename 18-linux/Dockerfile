# A practice Linux server for module 18. You are root inside it; it is safe to break.
FROM debian:12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends sudo procps psmisc cron iproute2 curl openssh-client util-linux findutils passwd systemd logrotate nano less ca-certificates \
 && rm -rf /var/lib/apt/lists/*
CMD ["sleep", "infinity"]
