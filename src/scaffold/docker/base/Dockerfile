FROM debian:bookworm-slim AS builder

ARG ZIG_VERSION=0.16.0-dev.2535+b5bd49460

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates xz-utils git && \
    rm -rf /var/lib/apt/lists/*

RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in amd64) ZIG_ARCH=x86_64;; arm64) ZIG_ARCH=aarch64;; esac && \
    curl -L "https://ziglang.org/builds/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz && \
    mkdir -p /opt/zig && \
    tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 && \
    rm /tmp/zig.tar.xz

ENV PATH="/opt/zig:${PATH}"

WORKDIR /build

# Clone pidgn framework
RUN git clone --depth 1 https://github.com/seemsindie/pidgn.git ../pidgn.zig

COPY . .
RUN zig build -Doptimize=ReleaseSafe -Denv=prod

FROM debian:bookworm-slim

COPY --from=builder /build/zig-out/bin/$NAME$ /usr/local/bin/
COPY --from=builder /build/public /app/public

WORKDIR /app
EXPOSE 4000
CMD ["$NAME$"]
