FROM golang:1.24.4 as awg
COPY . /awg
WORKDIR /awg
RUN go mod download && \
    go mod verify && \
    go build -ldflags '-linkmode external -extldflags "-fno-PIC -static"' -v -o /usr/bin

# Build amneziawg-tools
FROM alpine as build
WORKDIR /app
RUN apk --no-cache add linux-headers build-base git && \
    git clone https://github.com/amnezia-vpn/amneziawg-tools.git && \
    cd amneziawg-tools/src && \
    make

FROM alpine
ARG AWGTOOLS_RELEASE="1.0.20251025"

# Copy amneziawg-tools instead of using vAWGTOOLS_RELEASE blob
COPY --from=build /app/amneziawg-tools/src/wg /usr/bin/awg
COPY --from=build /app/amneziawg-tools/src/wg-quick/linux.bash /usr/bin/awg-quick

RUN apk --no-cache add iproute2 iptables bash && \
    chmod +x /usr/bin/awg /usr/bin/awg-quick && \
    ln -s /usr/bin/awg /usr/bin/wg && \
    ln -s /usr/bin/awg-quick /usr/bin/wg-quick
COPY --from=awg /usr/bin/amneziawg-go /usr/bin/amneziawg-go
