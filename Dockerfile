from debian:stable-slim
MAINTAINER Trent Walraven <obsidian-zola@trwbox.com>

LABEL "com.github.actions.name"="Obsidian-Zola build to Github Pages"
LABEL "com.github.actions.description"="Build a obsidian-zola site for GitHub Pages"
LABEL "com.github.actions.icon"="moon"
LABEL "com.github.actions.color"="blue"

# Set default locale for the environment
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update && apt-get install -y wget git python-is-python3 python3-pip rsync
RUN pip3 install python-slugify

RUN wget -q -O - \
"https://github.com/getzola/zola/releases/download/v0.15.2/zola-v0.15.2-x86_64-unknown-linux-gnu.tar.gz" \
| tar xzf - -C /usr/local/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
