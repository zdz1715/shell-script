FROM zdzserver/docker-openvpn

ADD . /shells

RUN chmod a+x /shells/*; \
    apt-get install -y curl

WORKDIR /shells

CMD ["tail", "-f"]
