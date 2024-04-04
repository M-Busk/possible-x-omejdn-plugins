FROM ghcr.io/fraunhofer-aisec/omejdn-server:1.7.1

WORKDIR /opt

COPY . .

EXPOSE 4567

CMD [ "ruby", "omejdn.rb" ]