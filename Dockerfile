FROM alpine:3.7
LABEL maintainer="Hui Luo <luoh@vmware.com>"

RUN apk add --no-cache openssh

COPY *.sh /clusterapi/
COPY bin /clusterapi/bin
COPY spec /clusterapi/spec

WORKDIR /clusterapi/
CMD ["shell"]
ENTRYPOINT ["/clusterapi/clusterctl.sh"]
