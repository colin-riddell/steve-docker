Hey man. I understand entirely what you're confused about.

> Where I start to get a bit lost is using Dockerfile to create (or more specifically, run) an image of all three parts. They seem to connect to each other internally (inside the container) but I don't how to reach the aforementioned API endpoint provided by my app from the browser.

First thing is first.. you don't use the Dockerfile to run an image of all three parts.. you only use the dockerfile to create an image for
your API (server.js). Remember that `mongo` is a publically available image.. so in compose when you say `image: mongo` that's telling docker to pull down the already built public image for mongo from the public repo. Same for `mongo-express`.

Your app, server.js doesn't have an image though! So you need to create an image using the dockerfile, add it to the docker compose, and then
when you do `docker compose up` all **three** apps start at the same time. 

Either way to get this working as you'd expect you need to:

* rename mongo.yaml to docker-compose.yaml. The `docker compose ` command will look for files called `docker-compose.yaml` by defualt. You can name it whatever you want but you'll need to do like `docker compose up -f somefile.yaml` or something. you're better just calling it docker-compose.yaml which is what it expects. then you'll be able to do `docker compose up` or `docker compose build` with less hassle.
* Add a service to your `docker-compose.yaml` for your app, and add a build directive for it. Remember to expose the port properly eg: 
  ```
  api:
    build: .
    ports:
      - "9000:9000"
  ```
  That basically says, look in this dir for a Dockerfile, so when you do `docker compose build` it will find any services listed that have a build directive and build them.
* If you now to `docker compose build` it will build any services that have a `build:` (which is only this one). This should work good. So now your compose knows about the api app (or whatever you want to call it..) 


* Update server.js to pont to the container `mongo`.
Docker containers have thier own dns names.. thy use the service name you created in the compose to make the name of the container.. So now when connecting to mongodb it's not on localhost, but instead it's on a machine called `mongodb`.
```
MongoClient.connect('mongodb://admin:password@mongodb:27018', { useNewUrlParser: true, useUnifiedTopology: true })
```

Doing docker compose build then `docker compose up` might all work now. Should be able to go to `localhost:9000` to hit your app!! I couldn't try it as I think I'm missing some files?!



As a further optimisation  you should update the dockerfile to build it's own dependencies as it's sometimes a bit dodgy copying the node_modules  eg:
```Dockerfile
FROM node:13-alpine

ENV MONGO_DB_USERNAME=admin \
    MONGO_DB_PWD=password


RUN mkdir -p /home/app
WORKDIR /home/app

COPY server.js /home/app
COPY package.json /home/app
RUN npm install

CMD ["node", "/home/app/server.js"]
```
(or see my modified one in this repo!)

If you do this remember to rebuild wiht `docker compose build`



UPDATE:

>However, now my MongoClient.connect() in the server.js doesn't work. Need to figure out how to connect to a containerised db.

No, that's becuase you've run `mongo` and `mongo-express` in one set of containers with compose, and then `my_app` separately with `docker run` . Docker will create separate virtual networks for these so they won't be able to connect. If you do as above and add a service entry for your app then everything will work out perfectly
