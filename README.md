# Sk8s Kubelet

A fully self-contained Kubelet that can run in Docker with all the necessary dependencies:

- [`cni`](https://github.com/containernetworking/plugins)
- [`cri-o`](https://github.com/cri-o/cri-o)
- [`conmon`](https://github.com/containers/conmon)
- [`runc`](https://github.com/opencontainers/runc)
- [`kubelet`](https://github.com/kubernetes/kubernetes)
- [`procfiled`](https://github.com/scaffoldly/procfiled)
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

#### Running `kubectl`

Following a `make up` command, a `kubeconfig` is placed in `tests/`:

```bash
export KUBECONFIG=tests/kubeconfig
kubectl get nodes
kubectl run hello-world --image=hello-world --restart=Never --attach --rm
```

> [!NOTE]  
> Don't save the `kubeconfig`. It's regenerated each time the stack is started.

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
