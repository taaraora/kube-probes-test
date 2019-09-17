FROM golang:1.13 as back_builder

ARG ARCH=amd64
ARG GOOS=linux
ARG GO111MODULE=on

WORKDIR $GOPATH/src/github.com/taaraora/kube-probes-test/

COPY go.mod go.sum vendor $GOPATH/src/github.com/taaraora/kube-probes-test/
COPY . $GOPATH/src/github.com/taaraora/kube-probes-test/

RUN CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${ARCH} go build \
		-mod=vendor \
		-o $GOPATH/bin/prober -a ./cmd/prober

FROM scratch
COPY --from=back_builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=back_builder /go/bin/prober /bin/prober

ENTRYPOINT ["/bin/prober"]
