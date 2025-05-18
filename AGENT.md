# distcc Agent (distccd)

This document describes the `distcc` agent container and how to deploy it on
a Kubernetes cluster.

## Container image

The `distcc` agent runs `distccd` inside a Gentoo-based container with a
cross-compilation toolchain for PowerPC. The Dockerfile is located at
[`./Dockerfile`](./Dockerfile).

### Whitelisted compilers

The image whitelists the following compiler wrappers for remote compilation:

```console
/usr/lib/distcc/powerpc-unknown-linux-gnu-gcc
/usr/lib/distcc/powerpc-unknown-linux-gnu-g++
```

Configured via the `/usr/lib/distcc/whitelist` file.

## distccd invocation

The container's entrypoint runs `distccd` in daemon mode. The default arguments
are:

```console
distccd --daemon --no-fork --allow 0.0.0.0/0 --log-stderr
```

Additional flags:

- `--no-fork`: Run in the foreground (containerized use).
- `--no-detach`: Do not detach from the controlling terminal.
- `--allow`: Specify a CIDR range of allowed client IPs.
- `--log-stderr`: Log to `stderr`.
- `--verbose`: Enable verbose logging.

## Kubernetes Deployment

### DaemonSet

Deploy one `distcc` agent per node using the DaemonSet manifest:

```sh
kubectl apply -f distcc-ds.yaml
```

Key points:

- Runs on each node, including masters (due to tolerations).
- Uses the `ghcr-creds` image pull secret to fetch the `distcc` image.
- Requests minimal resources (`cpu: 100m`, `memory: 128Mi`).
- Listens on TCP port 3632.

### Services

#### NodePort

```sh
kubectl apply -f distcc-nodeport.yaml
```

- Exposes port `3632` via a NodePort (default `30362`).

#### LoadBalancer

```sh
kubectl apply -f distcc-lb.yaml
```

- Exposes port `3632` via a LoadBalancer service.

#### Combined manifest

Use the combined manifest (`distcc-deploy-nodePort.yml`) to deploy the DaemonSet
and NodePort service in one step:

```sh
kubectl apply -f distcc-deploy-nodePort.yml
```

### Customization

- Adjust the `--allow` CIDR range in the DaemonSet to restrict client IPs.
- Modify `nodeAffinity` in the DaemonSet to schedule agents only on select
  nodes.
- Change the `nodePort` or use `LoadBalancer` depending on your networking
  environment.