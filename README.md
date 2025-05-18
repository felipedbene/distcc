# distcc Kubernetes Setup

This repository provides a Docker image and Kubernetes manifests for running
[`distcc`](https://distcc.github.io/) distributed compilation daemon (`distccd`)
on a Kubernetes cluster.

It includes:

- A multi-architecture Docker image based on Gentoo for cross-compiling to
  PowerPC (`powerpc-unknown-linux-gnu`).
- Kubernetes `DaemonSet` and `Service` manifests to deploy the `distcc` agent on
  all nodes and expose it via LoadBalancer or NodePort.
- Sample C programs (`foo.c`, `bar.c`, `main.c`) to demonstrate distributed
  compilation.
- Example manifests for deploying the agent
  (`distcc-ds.yaml`, `distcc-lb.yaml`, `distcc-nodeport.yaml`,
  `distcc-deploy-nodePort.yml`).
- GitHub Actions workflow for building and pushing the multi-arch Docker image
  to GitHub Container Registry
  (`.github/workflows/build-multiarch.yml`).

## Documentation

- [Agent](./AGENT.md): Details on the `distcc` agent container and Kubernetes
  manifests.

## Prerequisites

- A Kubernetes cluster (v1.12+).
- `kubectl` configured to access your cluster.
- `distcc` client installed on your development machine.
- A GitHub Container Registry secret (`ghcr-creds`) in your cluster for pulling
  the `distcc` image.

### Create the `ghcr-creds` secret

```sh
kubectl create secret docker-registry ghcr-creds \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_PERSONAL_ACCESS_TOKEN \
  --docker-email=YOUR_EMAIL@example.com
```

## Building & Pushing the Docker Image

This repository includes a GitHub Actions workflow that builds and pushes a
multi-arch image to `ghcr.io/felipedbene/distccd-gentoo-ppc:latest`. To run it
manually:

```sh
# Build and push multi-arch image (amd64 & arm64)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t ghcr.io/felipedbene/distccd-gentoo-ppc:latest .
```

## Deploying the distcc agent

Apply the Kubernetes manifests to deploy the `distcc` agent:

```sh
# Deploy DaemonSet
kubectl apply -f distcc-ds.yaml

# Expose via NodePort
kubectl apply -f distcc-nodeport.yaml

# (Optional) Expose via LoadBalancer
kubectl apply -f distcc-lb.yaml
```

Or deploy via the combined NodePort manifest:

```sh
kubectl apply -f distcc-deploy-nodePort.yml
```

## Client Usage

Once the `distcc` agent is running, configure the `distcc` client on your
development machine:

```sh
# Point to your cluster IP (or LoadBalancer/NodePort)
export DISTCC_HOSTS="CLUSTER_IP:PORT/$(nproc)"

# Or unlimited jobs:
# export DISTCC_HOSTS="CLUSTER_IP:PORT/"

# Compile with distcc as usual:
distcc gcc -c foo.c
distcc gcc -c bar.c
distcc gcc -o hello main.o foo.o bar.o

# Run the result:
./hello
```

You can substitute `gcc` with any whitelisted cross-compiler (e.g.,
`powerpc-unknown-linux-gnu-gcc`).

## Sample files

- `foo.c`, `bar.c`, `main.c`: sample C sources.
- `*.o`, `hello`: pre-built object files and binary for ARM64; remove them to
  force recompilation.