FROM node:13-alpine

ENV MONGO_DB_USERNAME=admin \
    MONGO_DB_PWD=password


RUN mkdir -p /home/app
WORKDIR /home/app

COPY server.js /home/app
COPY package.json /home/app
RUN npm install

CMD ["node", "/home/app/server.js"]
