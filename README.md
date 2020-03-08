# Continuous Integration

[![master](https://github.com/sydnod/ci/workflows/master/badge.svg)](https://github.com/sydnod/ci/actions?query=workflow%3Amaster) [![dev](https://github.com/sydnod/ci/workflows/dev/badge.svg)](https://github.com/sydnod/ci/actions?query=workflow%3Adev)

This is a Continuous Integration (CI) Git module maintained by [Sydnod](https://sydnod.com). It aims to be a drop-in package for projects that want to enable a CI in a simple way.

It's basically a Git Sub-module that contains a set of CI workflow templates, some scripts that provides helper environment variables and merges Kubernetes declarations into one `manifests.yaml` file. Before these files are merged, variables are parsed into the corresponding environment variable.

It currently supports GitHub Actions, meaning that the generated output environment variables are somewhat built around the Github Action's build environments. However, this can and will easily be extended by adding bootstrap providers. Feel free to raise a Feature request.

### Requirements

- **In general**: Code placed in a GitHub repository
- **For Docker build and push**: Login credentials to Container Registry
- **For Kubernetes deployment**: Login credentials to Kubernetes cluster, e.g. `KUBE_CONFIG`.

### Setup

Sounds good? Here's the plan:

1. Add this repository as a submodule into the root directory `ops/ci`

```bash
git submodule add https://github.com/sydnod/ci ops/ci
```

2. Create root directory `.github` with a subfolder `workflows`, resulting in `.github/workflows/`.

3. Copy a relevant [GitHub Actions](https://help.github.com/en/actions) CI pipeline from `ops/ci/templates/ci/github/actions/workflows` into `.github/workflows`. Make sure to call `ops/ci/scripts/bootstrap.sh` early on.

4. Define required environment variables as of below.

5. Push the workflow to GitHub and see some magic.

## Environment variables

The `Default examples` below are based on the following environment variables being true;

```yaml
CI_PACKAGE_NAME: "web"
CI_ENVIRONMENT: "development"
```

### Package

Package environment variables, such as package name and it's path.

| Name              | Type       | Default examples | Description                               |
| ----------------- | ---------- | ---------------- | ----------------------------------------- |
| `CI_PACKAGE_NAME` | `required` | `web`            | Package name, e.g. `web` or `backend`     |
| `CI_PACKAGE_PATH` | `optional` | `web/`           | Default location to the package root path |

### Application

Application environment variables, such as runtime environment.

| Name                       | Type       | Default examples | Description                                                                        |
| -------------------------- | ---------- | ---------------- | ---------------------------------------------------------------------------------- |
| `CI_ENVIRONMENT`           | `required` | `development`    | Environment name (`production`, `stage`, `test`, `development` or `local`)         |
| `CI_APP_ENVIRONMENT`       | `computed` | `development`    | Alias to `CI_APP_ENVIRONMENT`                                                      |
| `CI_APP_ENVIRONMENT_SHORT` | `computed` | `dev`            | A short-handed version of `CI_APP_ENVIRONMENT` (`prod`, `dev`, `stage` or `local`) |
| `CI_APP_HOSTNAME_PREFIX`   | `computed` | `dev.`           | A hostname prefix for the environment (`<null>`,`dev.`,`stage.`or`local.`)         |

### Container Registry

Container Registry variables, if you plan to build and push a Docker image.

| Name                              | Type       | Default examples                            | Description                                          |
| --------------------------------- | ---------- | ------------------------------------------- | ---------------------------------------------------- |
| `CI_REPOSITORY_NAME`              | `optional` | `web`                                       | Name of the Container Registry repository            |
| `CI_REPOSITORY_IMAGE_TAG_PREFIX`  | `optional` | `web`                                       | Prefix of image tag, e.g.`web`                       |
| `CI_REPOSITORY_IMAGE_TAG`         | `computed` | `web-dev-200221-7ccba6e`                    | Generated image tag                                  |
| `CI_REPOSITORY_IMAGE_PATH_FULL`   | `computed` | `cr.sydnod.net/ci:web-dev-20200221-7ccba6e` | Full path to Container Registry image                |
| `CI_REPOSITORY_IMAGE_PATH_NO_TAG` | `computed` | `cr.sydnod.net/ci`                          | Full path to Container Registry image, excluding tag |

### Kubernetes

Kubernetes variables, if you plan to deploy to Kubernetes. See [example templates](templates/config/kubernetes).

| Name                              | Type       | Default examples                           | Description                                  |
| --------------------------------- | ---------- | ------------------------------------------ | -------------------------------------------- |
| `CI_K8S_SERVICE_NAME`             | `optional` | `web-dev`                                  | Kubernetes service name                      |
| `CI_K8S_NAMESPACE_NAME`           | `optional` | `web`                                      | Kubernetes namespace to deploy resources in  |
| `CI_K8S_SOURCE_PATH`              | `optional` | `web/ops/config/kubernetes/`               | Source directory for Kubernetes declarations |
| `CI_K8S_GENERATED_MANIFESTS_FILE` | `computed` | `web/ops/config/kubernetes/manifests.yaml` | Generated Kubernetes manifest                |
| `CI_K8S_REPOSITORY_SECRET_NAME`   | `computed` | `web-container-registry`                   | Generated secret name for Container Registry |

### Helpers

Helper variables, such as Git SHA and current date.

| Name                       | Type       | Default examples          | Description                          |
| -------------------------- | ---------- | ------------------------- | ------------------------------------ |
| `CI_VERSION`               | `computed` | `0.0.4`                   | Sydnod CI version                    |
| `CI_BOOTSTRAP_SCRIPT_PATH` | `computed` | `ops/ci/scripts`          | Path to Sydnod CI's script path      |
| `CI_DATE_YYYYMMDD`         | `computed` | `20200221`                | Today's date                         |
| `CI_COMMIT_SHA`            | `computed` | `7ccba6e88d2fc15399[...]` | Git SHA that trigged the CI workflow |
| `CI_COMMIT_SHA_SHORT`      | `computed` | `7ccba6e`                 | Short version of the Git SHA         |

## Kubernetes Deployments

All `*.yaml` and `*.yml` files that reside in the Kubernetes source directory (`$CI_K8S_SOURCE_PATH`) will be parsed and merged into one `manifests.yaml` file. Before these files are merged, variables are parsed into the corresponding environment variable.

### Example

Considering the following environment variables being defined during build:

```yaml
# Sydnod CI specific
CI_ENVIRONMENT: "development"
CI_PACKAGE_NAME: "web"
CI_K8S_NAMESPACE_NAME: "sydnod-ci-example"

# Application example
DOMAIN: "example.com"
```

**Source file**

`web/ops/config/kubernetes/Ingress.yaml` having the following:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ${CI_K8S_SERVICE_NAME}
  namespace: ${CI_K8S_NAMESPACE_NAME}
spec:
  tls:
    - hosts:
        - ${CI_APP_HOSTNAME_PREFIX}${DOMAIN}
      secretName: ${DOMAIN}-tls-${CI_APP_ENVIRONMENT_SHORT}
  rules:
    - host: ${CI_APP_HOSTNAME_PREFIX}${DOMAIN}
      http:
        paths:
          - path: /
            backend:
              serviceName: ${CI_K8S_SERVICE_NAME}
              servicePort: http
```

**Destination manifest**

`web/ops/config/kubernetes/manifests.yaml` would contain:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-dev
  namespace: sydnod-ci-example
spec:
  tls:
    - hosts:
        - dev.example.com
      secretName: example.com-tls-dev
  rules:
    - host: dev.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: web-dev
              servicePort: http
---
# Remaining Kubernetes files found in web/ops/config/kubernetes
# ...
```

As you probably noticed, we were using some variables that was `computed` by this sub-module. Bottom line: You can use any environment variable you want.

### Templates

See example [Kubernetes templates](templates/config/kubernetes).

## Build status

We strive to keep the `master` stable with backwards compatibility. You can see the build status below, along with deployment tests.

| Branch   | Build status                                                                                                                       | Deployment test                                        |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `master` | [![master](https://github.com/sydnod/ci/workflows/master/badge.svg)](https://github.com/sydnod/ci/actions?query=workflow%3Amaster) | [https://ci.sydnod.net](https://ci.sydnod.net)         |
| `dev`    | [![dev](https://github.com/sydnod/ci/workflows/dev/badge.svg)](https://github.com/sydnod/ci/actions?query=workflow%3Adev)          | [https://dev.ci.sydnod.net](https://dev.ci.sydnod.net) |

## Contribution

Feel free to send Pull Requests with code that makes things better ❤️

## Feature roadmap

- ~~Make test suits~~
  - Make more test suits
- Make compatible with TravisCI, Azure Pipelines etc
- Add CI provider templates

## License

MIT
