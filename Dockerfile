FROM golang:alpine as builder

RUN apk add -U --no-cache ca-certificates git build-base make gcc musl-dev linux-headers

RUN go get github.com/TeamEGEM/go-egem
RUN cd /go/src/github.com/TeamEGEM/go-egem && make

FROM alpine:latest
MAINTAINER Zibastian <Discord: @zibastian>

COPY --from=builder /go/src/github.com/TeamEGEM/go-egem/build/bin/egem /usr/bin/

RUN apk add -U --no-cache nodejs npm git curl su-exec
RUN npm install -g pm2

ARG usr=egem
RUN addgroup -g 900 ${usr} && \
    adduser -D -u 900 -G ${usr} -h /opt/${usr} ${usr} \
	&& mkdir -p /opt/${usr} \
	&& chown -R ${usr}:${usr} /opt/${usr}

RUN su-exec ${usr} mkdir -p /opt/${usr}/live-net/egem \
	&& su-exec ${usr} curl -o /opt/${usr}/live-net/egem/static-nodes.json https://raw.githubusercontent.com/TeamEGEM/EGEM-Bootnodes/master/static-nodes.json

RUN su-exec ${usr} git clone https://github.com/TeamEGEM/egem-net-intelligence-api.git /opt/${usr}/egem-net-intelligence-api
RUN cd /opt/${usr}/egem-net-intelligence-api && su-exec ${usr} npm install

COPY ./docker-entrypoint.sh /usr/bin/docker-entrypoint
RUN chmod +x /usr/bin/docker-entrypoint

CMD ["docker-entrypoint"]

USER ${usr}

WORKDIR /opt/${usr}

EXPOSE 30666/tcp

