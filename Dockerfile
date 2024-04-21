#syntax=docker/dockerfile:1.4
FROM scratch AS builder 
ARG VERSION
ADD alpine-minirootfs-3.19.1-x86_64.tar /

WORKDIR /usr/app

RUN apk update \
    && apk add nodejs npm \
    && apk add git \
    && apk add openssh-client \
    && rm -rf /var/cache/apk/*


RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts \
    && eval $(ssh-agent)

RUN --mount=type=ssh git clone git@github.com:rafals123/Laboratorium-5.git
WORKDIR /usr/app/Laboratorium-5    
RUN npm install && rm -f ReadMe.pdf Dockerfile ReadMe.txt alpine-minirootfs-3.19.1-x86_64.tar

EXPOSE 3000

FROM nginx:alpine

ARG VERSION
ENV APP_VERSION=${VERSION:-v1}

WORKDIR /usr/share/nginx/html

COPY --from=builder /usr/app/Laboratorium-5 /usr/share/nginx/html

COPY --from=builder /usr/app/Laboratorium-5/default.conf /etc/nginx/conf.d

RUN apk update && apk add nodejs && rm -rf /var/cache/apk/*

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=1s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80 || exit 1

CMD nginx -g "daemon off;" & node app.js  