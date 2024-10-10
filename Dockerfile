# Build backend with go
FROM golang:1.16 AS be-builder

# Install tools and libraries
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -qq \
	git \
	pkg-config \
	libpcap-dev \
	libhyperscan-dev

WORKDIR /caronte

COPY . ./

RUN export VERSION=$(git describe --tags --abbrev=0) && \
	go mod download && \
	go build -ldflags "-X main.Version=$VERSION" && \
	mkdir -p build && \
	cp -r caronte pcaps/ scripts/ shared/ test_data/ build/


# Build frontend via yarn
FROM node:20 AS fe-builder

WORKDIR /caronte-frontend

COPY ./frontend ./

ENV NODE_OPTIONS=--openssl-legacy-provider

RUN yarn install && yarn build --production=true


# LAST STAGE
FROM alpine:3.14

COPY --from=be-builder /caronte/build /opt/caronte

COPY --from=fe-builder /caronte-frontend/build /opt/caronte/frontend/build

RUN apk add --no-cache \
	libpcap-dev \
	libhyperscan-de

ENV GIN_MODE release

ENV MONGO_HOST mongo

ENV MONGO_PORT 27017

WORKDIR /opt/caronte
ENTRYPOINT ./caronte -mongo-host ${MONGO_HOST} -mongo-port ${MONGO_PORT} -assembly_memuse_log
