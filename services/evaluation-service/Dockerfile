FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
COPY *.go ./
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o /evaluation-service .

FROM alpine:3.19
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /evaluation-service .
USER app
EXPOSE 8004
CMD ["./evaluation-service"]
