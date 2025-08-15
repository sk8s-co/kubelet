# Sk8s Kubelet

A fully self-contained Kubelet that can run in Docker with all the necessary dependencies:

- [`cni` plugins](https://github.com/containernetworking/plugins)
- [`cri-o`](https://github.com/cri-o/cri-o)
- [`conmon`](https://github.com/containers/conmon)
- [`runc`](https://github.com/opencontainers/runc)
- [`kubelet`](https://github.com/kubernetes/kubernetes)
- [`forego`](https://github.com/ddollar/forego)
  - Launches the [Procfile](./Procfile)

## Running

> [!WARNING]  
> Each bootup is ephemeral, no data is saved.

There is a [`docker-compose.yml`](./tests/docker-compose.yml) that will start up the full stack:

- `etcd` (single instance)
- `kube-apiserver` (single instance)
- `kube-controller-manager` (single instance, leasing disabled)
- `kube-scheduler` (single instance, leasing disabled)
- `kubelet` + `cri-o` (this repository, single instance)

### Starting

```bash
make up
```

### Stopping

```bash
make down
```

### Testing

```bash
make test
```

This will run the following [test suites](./tests/):

- `hello-world`: Runs a `busybox` container and ensures the `status.phase` is `Succeeded`.

### Selecting a Kubernetes Version

```bash
make [up|test] KUBE_VERSION=v1.34.0-beta.0
```

You can use any tag from [Kubernetes](https://github.com/kubernetes/kubernetes/tags).

## Maintainers

- [Scaffoldly](https://github.com/scaffoldly)
- [cnuss](https://github.com/cnuss)

## License

[FSL-1.1-ALv2](LICENSE.md)
