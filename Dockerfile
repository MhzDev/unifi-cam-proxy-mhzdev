ARG version=3.9
ARG tag=${version}-alpine3.17

FROM python:${tag} as builder
WORKDIR /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apk add --update \
        cargo \
        git \
        gcc \
        g++ \
        jpeg-dev \
        libc-dev \
        linux-headers \
        musl-dev \
        patchelf \
        rust \
        zlib-dev

RUN pip install -U pip wheel setuptools maturin
COPY requirements.txt .
RUN pip wheel --no-deps -w /wheels -r requirements.txt

FROM python:${tag}
WORKDIR /app

ARG version

COPY --from=builder \
        /usr/local/lib/python${version}/site-packages \
        /usr/local/lib/python${version}/site-packages

RUN apk add --update ffmpeg netcat-openbsd libusb-dev

COPY . .
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*.whl

COPY ./docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
