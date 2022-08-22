# Using a prebuilt Rust image for the binary compilation
# This is a multi-stage Docker build
# https://hub.docker.com/_/rust
FROM rust:1.56.1 as builder

# This argument needs to be passed at the image creation
# It is used to select the repository release tag
ARG release_tag

# We will use this directory to build the binary
WORKDIR /stafi-node

# Install the required dependencies, sorted alphanumerically
RUN apt-get update && apt-get install -y \
    make \
    clang \
    pkg-config \
    libssl-dev \
    build-essential \
    cmake \
  && rm -rf /var/lib/apt/lists/*

# Install the required toolchain and components to compile Substrate-based node binaries
RUN rustup toolchain install nightly-2022-07-28 --target wasm32-unknown-unknown --profile minimal --component rustfmt clippy rust-src

# Performs a shallow clone of the repository in the specified tag
RUN git clone --depth 1 https://github.com/stafiprotocol/stafi-node --branch $release_tag .

# Compiles the binary, it may take a while
RUN cargo build --release

# Use an extra light image to reduce the image size
# Other lighter distributions like Alpine are not compatible with the compiled binary
FROM debian:stable as final

# We need to install gosu that will be used in the entrypoint
RUN apt-get update && apt-get -y install gosu && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the builder image to the final image
COPY --from=builder /stafi-node/target/release/stafi /usr/local/bin/

# Checks that the binary is working properly
RUN /usr/local/bin/stafi --version

# Copies the entrypoint script and sets execution permissions
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# This script is the first thing executed when the container is deployed
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
