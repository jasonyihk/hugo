FROM node:8.9.4-alpine
LABEL name="hugo"
LABEL maintainer=<jasonyihk@gmail.com>
LABEL version="1.0"

RUN adduser -h /hubot -s /bin/bash -S hubot

USER hubot
WORKDIR /hubot

COPY hubot.sh /hubot
COPY package.json /hubot
COPY external-scripts.json /hubot
COPY scripts /hubot/scripts

RUN npm install --only=production

EXPOSE 8080

CMD ["/hubot/hubot.sh","--adapter", "slack"]