FROM alpine:latest

ARG arch=amd64
ARG bin=gobase

COPY bin/${arch}/${bin} /${bin}

USER nobody:nobody
ENTRYPOINT ["/${bin}"]
