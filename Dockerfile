FROM golang:1.24-alpine AS gobuild

WORKDIR /build
ADD go.mod go.sum /build/
RUN go mod download -x
ADD cmd /build/cmd
ADD pkg /build/pkg
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver
RUN apk add curl
RUN case `uname -m` in aarch64) ARCH=arm64;; x86_64) ARCH=amd64;; *) echo unknown architecture;exit 1;;esac \
  && curl -L https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-${ARCH} --output geesefs \
  && chmod 755 geesefs

FROM alpine:3.21

RUN apk add --no-cache fuse mailcap rclone
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community s3fs-fuse

COPY --from=gobuild /build/s3driver /s3driver
COPY --from=gobuild /build/geesefs /usr/bin/geesefs
ENTRYPOINT ["/s3driver"]
