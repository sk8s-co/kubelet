ARG GO_VERSION=1.21
ARG KUBE_VERSION=v1.29.0
FROM golang:${GO_VERSION} AS builder

ARG KUBE_VERSION
RUN --mount=type=cache,target=/go \
    git clone https://github.com/kubernetes/kubernetes.git -b ${KUBE_VERSION} --depth=1 /kubernetes && \
    cd /kubernetes && \
    CGO_ENABLED=0 make all WHAT=cmd/kubelet && \
    mv /kubernetes/_output/local/go/bin/kubelet /usr/bin/kubelet

FROM scratch
COPY --from=builder /usr/bin/kubelet /usr/bin/kubelet
ENTRYPOINT [ "/usr/bin/kubelet" ]
