FROM golang:1.23-alpine AS build

ARG VERSION=dev
ARG TARGETARCH

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
COPY pia/ ./pia/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build \
    -ldflags="-w -s -X main.version=${VERSION}" \
    -a -installsuffix cgo \
    -trimpath \
    -o pia-wg-config .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /app/pia-wg-config /pia-wg-config
USER 65532:65532
ENTRYPOINT ["/pia-wg-config"]
