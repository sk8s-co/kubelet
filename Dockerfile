ARG GO_VERSION_KUBE=1.21
ARG KUBE_VERSION=v1.29.0

ARG GO_VERSION_CNI=1.23
ARG CNI_VERSION=v1.7.1

FROM golang:${GO_VERSION_CNI} AS builder-cni

ARG CNI_VERSION
ARG GO_VERSION_CNI
# Ref: https://github.com/containernetworking/plugins/blob/b0466813c32105b2402e760b9ad2f9eb25e66d5e/build_linux.sh
RUN --mount=type=cache,target=/go-${GO_VERSION_CNI} \
    git clone https://github.com/containernetworking/plugins.git -b ${CNI_VERSION} --depth=1 /opt/cni && \
    cd /opt/cni && \
    CGO_ENABLED=0 ./build_linux.sh -ldflags '-extldflags -static -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=${CNI_VERSION}'

FROM golang:${GO_VERSION_KUBE} AS builder-kubelet

ARG KUBE_VERSION
ARG GO_VERSION_KUBE
RUN --mount=type=cache,target=/go-${GO_VERSION_KUBE} \
    git clone https://github.com/kubernetes/kubernetes.git -b ${KUBE_VERSION} --depth=1 /kubernetes && \
    cd /kubernetes && \
    CGO_ENABLED=0 make all WHAT=cmd/kubelet && \
    mv /kubernetes/_output/local/go/bin/kubelet /usr/bin/kubelet

FROM scratch
COPY --from=builder-cni /opt/cni/bin/ /opt/cni/bin/
COPY --from=builder-kubelet /usr/bin/kubelet /usr/bin/kubelet
ENTRYPOINT [ "/usr/bin/kubelet" ]
