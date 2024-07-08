FROM --platform=${BUILDPLATFORM} alpine:latest AS builder

ARG VERSION=v1.68.2

LABEL org.opencontainers.image.source https://github.com/Erisa/Tailscale-DERP-Docker

#Install git
RUN apk add git bash curl --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

ARG TARGETOS
ARG TARGETARCH

WORKDIR /build

RUN git clone https://github.com/tailscale/tailscale --branch ${VERSION} .

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} ./tool/go build -o . tailscale.com/cmd/tailscale tailscale.com/cmd/tailscaled tailscale.com/cmd/derper

FROM alpine:latest

#Install Tailscale requirements
RUN apk add curl iptables

RUN mkdir -p /root/go/bin
COPY --from=builder /build/derper /root/go/bin/derper
COPY --from=builder /build/tailscale /usr/bin/tailscale
COPY --from=builder /build/tailscaled /usr/sbin/tailscaled

#Copy init script
COPY init.sh /init.sh
RUN chmod +x /init.sh

#Derper Web Ports
EXPOSE 80
EXPOSE 443/tcp
#STUN
EXPOSE 3478/udp

ENTRYPOINT ["/init.sh"]
