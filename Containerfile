FROM golang:alpine as build
ARG VERSION

WORKDIR /go/src
RUN set -x \
  \
  && apk add --no-cache \
    git \
    make \
    bash \
    rsync \
  \
  # && VERSION=$(wget -O - https://api.github.com/repos/kubernetes/kubernetes/releases/latest | grep tag_name | cut -d '"' -f 4 | tr -d 'v') \
  && git clone --depth 1 -b $VERSION https://github.com/kubernetes/kubernetes.git \
  && cd kubernetes \
  && make \
    kube-apiserver \
    kube-controller-manager \
    kube-scheduler \
    kube-proxy

FROM scratch as control-plane

COPY --from=build /go/src/kubernetes/_output/bin/kube-apiserver /usr/local/bin/
COPY --from=build /go/src/kubernetes/_output/bin/kube-controller-manager /usr/local/bin/
COPY --from=build /go/src/kubernetes/_output/bin/kube-scheduler /usr/local/bin/

FROM alpine:3.21 as kube-proxy

COPY --from=build /go/src/kubernetes/_output/bin/kube-proxy /usr/local/bin/
RUN set -x \
  \
  && apk add --no-cache \
    conntrack-tools \
    nftables \
    iptables \
    ipset \
    kmod