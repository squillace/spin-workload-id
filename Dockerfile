FROM rust:latest as builder

WORKDIR /usr/src/spin
COPY --from=spin . .
COPY http-ts-key-value ./examples/http-ts-key-value

RUN rustup target add wasm32-wasi
RUN cargo build --release
RUN cp /usr/src/spin/target/release/spin /usr/bin/spin

SHELL ["/bin/bash", "--login", "-c"]
RUN apt-get install -y curl && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN nvm install 20.9.0
RUN npm install -D webpack-cli
RUN spin plugin update \
    && spin plugin install -y js2wasm \
    && cd ./examples/http-ts-key-value \
    && npm install
RUN spin build -f ./examples/http-ts-key-value/spin.toml

FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt upgrade && apt install -y openssl ca-certificates
COPY --from=builder /usr/src/spin/target/release/spin ./spin
COPY --from=builder /usr/src/spin/examples/http-ts-key-value/target/http-ts-key-value.wasm ./target/http-ts-key-value.wasm
COPY --from=builder /usr/src/spin/examples/http-ts-key-value/azure-runtime-config.toml ./runtime-config.toml
COPY --from=builder /usr/src/spin/examples/http-ts-key-value/spin.toml ./spin.toml

EXPOSE 3000
ENTRYPOINT ["/app/spin"]
CMD ["up", "--runtime-config-file", "runtime-config.toml"]
