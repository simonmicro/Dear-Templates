[Reference_0](https://docs.gitlab.com/runner/install/docker.html) and [Reference_1](https://docs.gitlab.com/runner/register/index.html#docker)

# Setup #
...a runner in our docker env
`docker run -d --name gitlab-runner-[RUNNER_NAME] --restart always -v /srv/gitlab-runner-[RUNNER_NAME]/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest`

# Config #
..the runner with RUNNER_NAME
`docker run --rm -t -i -v /srv/gitlab-runner-[RUNNER_NAME]/config:/etc/gitlab-runner gitlab/gitlab-runner register`
