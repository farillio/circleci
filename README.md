# circleci

Image building is performed automatically by [DockerHub](https://hub.docker.com/?namespace=farillio) upon commits to the `master` branch.

https://cloud.docker.com/u/farillio/repository/docker/farillio/circleci/general

Commits tagged in the form `v<major>.<minor>.<patch>` give rise to corresponding Docker image tags, allowing us to explicitly denote which image we want to use as the basis for running our CI processes. 

Changes are tracked using [farilliobot](https://github.com/farilliobot) GitHub account.
