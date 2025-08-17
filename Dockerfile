ARG GO_VERSION_KUBE=1.24
ARG KUBE_VERSION=v1.33.4

ARG GO_VERSION_CNI=1.23
ARG CNI_VERSION=v1.7.1

ARG GO_VERSION_CRIO=1.24
ARG CRIO_VERSION=v1.33.3

ARG GO_VERSION_CONMON=1.23
ARG CONMON_VERSION=v2.1.13

ARG GO_VERSION_RUNC=1.23
ARG RUNC_VERSION=v1.3.0

ARG FOREGO_VERSION=0.18
FROM nginxproxy/forego:${FOREGO_VERSION} AS forego
FROM registry.k8s.io/kubectl:${KUBE_VERSION} AS kubectl

FROM golang:${GO_VERSION_CNI}-alpine AS builder-cni

ARG CNI_VERSION
ARG GO_VERSION_CNI
RUN apk add --no-cache git make
RUN --mount=type=cache,target=/go-${GO_VERSION_CNI} \
    git clone https://github.com/containernetworking/plugins.git -b ${CNI_VERSION} --depth=1 /cni && \
    cd /cni && \
    CGO_ENABLED=0 ./build_linux.sh -ldflags '-extldflags -static -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=${CNI_VERSION}'

FROM golang:${GO_VERSION_CRIO}-alpine AS builder-crio

ARG CRIO_VERSION
ARG GO_VERSION_CRIO
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    gpgme-dev \
    pkgconfig \
    bash \
    btrfs-progs-dev
RUN --mount=type=cache,target=/go-${GO_VERSION_CRIO} \
    git clone https://github.com/cri-o/cri-o.git -b ${CRIO_VERSION} --depth=1 /cri-o && \
    cd /cri-o && \
    CGO_ENABLED=0 make binaries

FROM golang:${GO_VERSION_CONMON}-alpine AS builder-conmon

ARG CONMON_VERSION
ARG GO_VERSION_CONMON

RUN --mount=type=cache,target=/go-${GO_VERSION_CONMON} \
    apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    glib-dev \
    glib-static \
    libseccomp-dev \
    libseccomp-static \
    gettext-dev \
    gettext-static \
    pkgconfig \
    bash && \
    git clone https://github.com/containers/conmon.git -b ${CONMON_VERSION} --depth=1 /conmon && \
    cd /conmon && \
    CGO_ENABLED=0 CFLAGS="-static -pthread" LDFLAGS="-static -pthread -lm" make all VERSION=${CONMON_VERSION#v}

# Smoke test
RUN /conmon/bin/conmon --version

FROM golang:${GO_VERSION_RUNC}-alpine AS builder-runc

ARG RUNC_VERSION
ARG GO_VERSION_RUNC

RUN --mount=type=cache,target=/go-${GO_VERSION_RUNC} \
    apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libseccomp-dev \
    libseccomp-static \
    linux-headers \
    bash && \
    git clone https://github.com/opencontainers/runc.git -b ${RUNC_VERSION} --depth=1 /runc && \
    cd /runc && \
    CGO_ENABLED=0 make static

FROM golang:${GO_VERSION_KUBE}-alpine AS builder-kubelet

ARG KUBE_VERSION
ARG GO_VERSION_KUBE
RUN apk add --no-cache git make bash
RUN --mount=type=cache,target=/go-${GO_VERSION_KUBE} \
    git clone https://github.com/kubernetes/kubernetes.git -b ${KUBE_VERSION} --depth=1 /kubernetes && \
    cd /kubernetes && \
    CGO_ENABLED=0 make all WHAT=cmd/kubelet KUBE_STATIC_OVERRIDES=kubelet && \
    mv /kubernetes/_output/local/go/bin/kubelet /usr/bin/kubelet

FROM alpine:latest

RUN apk add --no-cache iptables curl jq
COPY --from=builder-cni /cni/bin/ /opt/cni/bin/
COPY --from=builder-crio /cri-o/bin/crio /usr/bin/crio
COPY --from=builder-crio /cri-o/bin/pinns /usr/bin/pinns
COPY --from=builder-conmon /conmon/bin/conmon /usr/bin/conmon
COPY --from=builder-runc /runc/runc /usr/bin/runc
COPY --from=builder-kubelet /usr/bin/kubelet /usr/bin/kubelet
COPY --from=kubectl /bin/kubectl /usr/bin/kubectl
COPY --from=forego /usr/local/bin/forego /usr/bin/forego

WORKDIR /var/task

COPY etc /etc
COPY var /var
COPY Procfile /var/task/Procfile

ENTRYPOINT [ "/usr/bin/forego" ]
CMD [ "start", "-r", "-f", "/var/task/Procfile" ]
