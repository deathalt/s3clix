FROM rust:1-bookworm AS rust-builder
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      build-essential \
      perl \
      automake \
      curl \
      pkg-config \
      libssl-dev \
      protobuf-compiler \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /src
ADD Cargo.lock Cargo.toml /src/
COPY src/ /src/src\
WORKDIR /src
RUN cargo build --release


FROM node:20-alpine3.20 AS js-builder
RUN apk update && apk upgrade && \
  apk add --no-cache git  && \
  rm -rf /var/cache/apk/* \
  RUN mkdir /src
WORKDIR /src
COPY ./ui/ ./
RUN  mkdir -p /build && \
  npm install -g @angular/cli && \
  npm install &&  \
  ng build --output-path /build\


FROM ubuntu:24.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        perl \
        openssl \
        ca-certificates \
        curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --from=js-builder /build /web
COPY --from=rust-builder /src/target/release/s3clix /usr/local/bin/
COPY /s3clix.yaml /etc/s3clix.yaml
RUN chmod 644 /etc/s3clix.yaml && \
    chmod +x /usr/local/bin/s3clix
USER 1000
ENV RUST_LOG="info,s3clix=debug"
WORKDIR /
ENTRYPOINT ["/usr/local/bin/s3clix", "-c", "/etc/s3clix.yaml"]
