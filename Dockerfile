FROM gitea/gitea:1.20

# make log dir
USER ${USER_UID}:${USER_GID}
RUN mkdir -p /var/log/gitea