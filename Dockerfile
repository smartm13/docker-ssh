#FROM gliderlabs/alpine
FROM mhart/alpine-node:6.2.0

WORKDIR /src
ADD . .

RUN apk --update add python make g++ nodejs py-pip musl-dev python-dev openldap-dev \
  && npm install \
  && pip install python-ldap==2.5.2 \
  && apk del make gcc g++ \
  && rm -rf /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp


# make coffee executable
RUN chmod +x ./node_modules/coffee-script/bin/coffee

# Connect to container with name/id
ENV CONTAINER=

# Shell to use inside the container
ENV CONTAINER_SHELL=bash

# Server key
ENV KEYPATH=./id_rsa

# Server port
ENV PORT=22

# Enable web terminal
ENV HTTP_ENABLED=true

# HTTP Port
ENV HTTP_PORT=8022

EXPOSE 22 8022

CMD ["npm", "start"]
