# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.231.6/containers/ubuntu/.devcontainer/base.Dockerfile
# [Choice] Ubuntu version (use hirsuite or bionic on local arm64/Apple Silicon): hirsute, focal, bionic
ARG VARIANT="jammy"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}
SHELL ["/bin/bash", "-c"]
COPY --from=golang:1.18.3-bullseye /usr/local/go/ /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"
COPY install.sh .
RUN ./install.sh && \
    go install -v golang.org/x/tools/gopls@latest
