# Our Gitlab pipelines are based on alpine so this is a must
FROM alpine:latest

# Dependencies for the driver
RUN apk update && \
    apk add python3 py3-pip curl

# SSH Config
RUN curl -Lo /usr/local/bin/tini https://github.com/krallin/tini/releases/download/v0.19.0/tini-i386 && \
    chmod +x /usr/local/bin/tini
RUN apk add --no-cache openssh \
    && sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ no/ /etc/ssh/sshd_config \
    && ssh-keygen -A
EXPOSE 22

# Dependencies for the runner
RUN apk add jq wget unzip
RUN pip install awscli --upgrade

ARG GITLAB_RUNNER_VERSION=v12.9.0

# Installing the runner
RUN curl -Lo /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-386 && \
    chmod +x /usr/local/bin/gitlab-runner && \
    gitlab-runner --version

# Git tools for the pipelines
RUN apk add bash ca-certificates git git-lfs && \
    git lfs install --skip-repo

# Entrypoint to start the ssh server
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
