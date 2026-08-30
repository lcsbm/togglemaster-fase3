FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod ./
COPY *.go ./
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o /auth-service .

FROM alpine:3.19
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /auth-service .
USER app
EXPOSE 8001
CMD ["./auth-service"]
