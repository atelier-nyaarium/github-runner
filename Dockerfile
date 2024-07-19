FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y \
	curl \
	iputils-ping \
	git \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Env override must be supplied during docker build
ARG DOCKER_USER=docker
ENV DOCKER_USER=$DOCKER_USER

ARG DOCKER_UID=1000
ENV DOCKER_UID=$DOCKER_UID

ARG DOCKER_GID=1000
ENV DOCKER_GID=$DOCKER_GID

# Configure user account "docker" (user only, no sudo)
RUN groupadd -r -g $DOCKER_GID $DOCKER_USER \
	&& useradd -rs /bin/bash -m -g $DOCKER_USER -u $DOCKER_UID $DOCKER_USER

COPY home/* /home/$DOCKER_USER/
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER/.bashrc \
	&& chmod 644 /home/$DOCKER_USER/.bashrc


WORKDIR /home/$DOCKER_USER/runner

RUN curl -sL https://github.com/actions/runner/releases/latest | grep -o -m 1 "https://github.com/actions/runner/releases/download/[^/]*/actions-runner-linux-x64-[^\"]*.tar.gz" > runner.url \
	&& curl -sL $(cat runner.url) -o runner.tar.gz \
	&& tar xzf runner.tar.gz \
	&& rm runner.url runner.tar.gz \
	&& chown -R $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER

RUN ./bin/installdependencies.sh \
	&& chown -R $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER


USER $DOCKER_USER

CMD ./config.sh --unattended --url $GITHUB_ORG_URL --pat $GITHUB_TOKEN && ./run.sh
