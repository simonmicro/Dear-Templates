---
title: GitLab - Source Code Mirror
summary: GitLab runner setup, docker & more
type: blog
banner: "/img/dear-templates/default.jpg"
---

* [Reference_0](https://docs.gitlab.com/runner/install/docker.html)
* [Reference_1](https://docs.gitlab.com/runner/register/index.html#docker)

# Setup #
...a runner in our docker env
`docker run -d --name gitlab-runner-[RUNNER_NAME] --restart always -v /srv/gitlab-runner-[RUNNER_NAME]/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest`

# Config #
..the runner with RUNNER_NAME
`docker run --rm -t -i -v /srv/gitlab-runner-[RUNNER_NAME]/config:/etc/gitlab-runner gitlab/gitlab-runner register`

# Build docker images with the GitLab CI #
## Inside the Dockerfile ##
...to use the `docker` command integrate the code from below (you can use for `$CI_REGISTRY_IMAGE` `$CI_REGISTRY` instead to reference just the docker registry url)...
```
    services:
        - docker:stable-dind
    image: docker:stable
    before_script:
        - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    script:
        - docker build --compress -t $CI_REGISTRY_IMAGE ./
        - docker push $CI_REGISTRY_IMAGE
```

## Configure a runner to allow dind ##
...add the following into the `[runners.docker]`-section...
```
    privileged = true
    volumes = ["/certs", "/cache"]
```
