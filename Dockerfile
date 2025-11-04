# LibyaChain Blockchain Docker Image

FROM golang:1.21-alpine AS builder

# Install dependencies
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    linux-headers

WORKDIR /libyachain

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN make build

# Runtime image
FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    jq

# Copy binary from builder
COPY --from=builder /libyachain/build/libyachaind /usr/local/bin/

# Create libyachain user
RUN addgroup -g 1000 libyachain && \
    adduser -D -u 1000 -G libyachain libyachain

# Set working directory
WORKDIR /home/libyachain

# Change ownership
RUN chown -R libyachain:libyachain /home/libyachain

USER libyachain

# Expose ports
# 26656: P2P
# 26657: RPC
# 1317: API
# 9090: gRPC
# 26660: Prometheus
EXPOSE 26656 26657 1317 9090 26660

# Default command
CMD ["libyachaind", "start"]
