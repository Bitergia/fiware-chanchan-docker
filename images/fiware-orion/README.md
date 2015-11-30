# Warning: This image has been deprecated and is no longer maintained. #
Please use the official image available at https://hub.docker.com/r/fiware/orion/

## Orion Context Broker Docker image ##

The [Orion Context Broker](http://catalogue.fiware.org/enablers/publishsubscribe-context-broker-orion-context-broker) is an implementation of the Publish/Subscribe Context Broker GE, providing the NGSI9 and NGSI10 interfaces.

## Supported tags and respective `Dockerfile` links ##

* [`develop`   (develop/Dockerfile](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/fiware-orion/develop/Dockerfile))
* [`0.23.0`   (0.23.0/Dockerfile](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/fiware-orion/0.23.0/Dockerfile))
* [`0.22.0`   (0.22.0/Dockerfile](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/fiware-orion/0.22.0/Dockerfile))

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/publishsubscribe-context-broker-orion-context-broker).

## Orion develop image ##

This image has orion compiled from HEAD of develop branch.

### Requirements ###

- MongoDB.  You can use the official images available at [Docker Hub](https://registry.hub.docker.com/_/mongo/).  This image has been tested with mongo:2.6 image.

### Image Contents ###

- [x] `centos:centos6` baseimage available [here](https://registry.hub.docker.com/_/centos/)
- [x] Orion Context Broker (built from source)
- [x] Running on port `1026`

### Usage ###

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MongoDB database
   * Data-only container for the MongoDB database
   * Orion Context Broker

The file `orion.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/orion.yml).

Once you get it, you just have to:

```
docker-compose -f orion.yml up -d
```

And all the services will be up. End to end testing can be done by doing:

```
curl <container-ip>:1026/version
```

### What if I don't want to use docker-compose? ###

No problem, the only thing is that you will have to deploy a MongoDB yourself and specify the parameters.

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/fiware-orion:develop -dbhost <mongo_server>
```

By running this, it expects a MongoDB database running on `<mongo_server>:27017` and orion will use port 1026.

Any parameter added after `bitergia/fiware-orion:develop` is passed directly to orion.  The image already adds `-fg` to tell orion not to detach itself as a daemon.  This is needed if you want to keep the container running as docker stops the container when the PID 1 process inside the container exits.

### Stopping the container ###

To stop the container, just use the `docker stop <container-id>` command.  This will send the TERM signal to orion triggering a clean shutdown of the container.

### Logs and other commands ###

By default, orion sends its output to stdout/stderr and this output can be viewed via the `docker logs <container-id>` command.

If you need to run another command in the same container, you can use the `docker exec` command.

### Keeping the development tools ###

If you want to keep the development tools on the image, you can do so by modifying the following line on the [Dockerfile](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/fiware-orion/develop/Dockerfile):

```
ENV CLEAN_DEV_TOOLS 1
```

changing the value to `0`:

```
ENV CLEAN_DEV_TOOLS 0
```

This will skip the cleaning process made at the end of the [Dockerfile](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/fiware-orion/develop/Dockerfile) in order to thin the final image.  This will grow the final image size from ~250 MB to ~1 GB.  Then you can build the image by using the available [Makefile](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/Makefile) by running:

```
make orion-develop
```

## Orion 0.23.0 image ##

### Requirements ###

- MongoDB.  You can use the official images available at [Docker Hub](https://registry.hub.docker.com/_/mongo/).  This image has been tested with mongo:2.6 image.

### Image Contents ###

- [x] `centos:centos6` baseimage available [here](https://registry.hub.docker.com/_/centos/)
- [x] Orion Context Broker (built from source)
- [x] Running on port `1026`

### Usage ###

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MongoDB database
   * Data-only container for the MongoDB database
   * Orion Context Broker

The file `orion.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/orion.yml).

Once you get it, you just have to:

```
docker-compose -f orion.yml up -d
```

And all the services will be up. End to end testing can be done by doing:

```
curl <container-ip>:1026/version
```

### What if I don't want to use docker-compose? ###

No problem, the only thing is that you will have to deploy a MongoDB yourself and specify the parameters.

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/fiware-orion:0.23.0 -fg
```

By running this, it expects a MongoDB database running on:

    * MONGODB_HOSTNAME: `mongodb`
    * MONGODB_PORT: `27017`
    * ORION_PORT: `1026`

So if you have your MongoDB somewhere else, just attach it as a parameter like:

```
docker run -d --name <container-name> -e MONGODB_HOSTNAME=<mongodb-host> -e MONGODB_PORT=<mongodb-port> bitergia/fiware-orion:0.23.0 -fg
```

Any parameter added after `bitergia/fiware-orion:0.23.0` is passed directly to orion.  In the examples above, `-fg` tells orion not to detach itself as a daemon.  This is needed if you want to keep the container running as docker stops the container when the PID 1 process inside the container exits.

If you want to run another command inside the container, just pass the command to run instead of the parameters to orion:

```
docker run -d --name <container-name> bitergia/fiware-orion:0.23.0 /bin/bash
```

### Stopping the container ###

To stop the container, just use the `docker stop <container-id>` command.  This will send the TERM signal to orion triggering a clean shutdown of the container.

### Logs and other commands ###

By default, orion sends its output to stdout/stderr and this output can be viewed via the `docker logs <container-id>` command.

If you need to run another command in the same container, you can use the `docker exec` command.

## Orion 0.22.0 image ##

### Requirements ###

- MongoDB. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/mongodb/).

### Image contents ###

- [x] `bitergia/centos-6` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/centos#image-contents)
- [x] Orion Context Broker
- [x] Running on port `10026`


### Usage ###

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MongoDB database
   * Data-only container for the MongoDB database
   * Orion Context Broker as a service

The file `orion.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/orion.yml).

Once you get it, you just have to:

```
docker-compose -f orion.yml up -d
```

And all the services will be up. End to end testing can be done by doing:

```
curl <container-ip>:10026/version
```

**Note**: as retrieving the `<container-ip>` can be a bit 'tricky', we've created a set of utilities and useful scripts for handling docker images. You can find them all [here](https://github.com/Bitergia/docker/tree/master/utils).

 
### What if I don't want to use docker-compose? ###

No problem, the only thing is that you will have to deploy a MongoDB yourself and specify the parameters.

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/fiware-orion:0.23.0
```

By running this, it expects a MongoDB database running on:

    * MONGODB_HOSTNAME: `mongodb`
    * MONGODB_PORT: `27017`
    * ORION_PORT: `10026`

So if you have your MongoDB somewhere else, just attach it as a parameter like:

```
docker run -d --name <container-name> -e MONGODB_HOSTNAME=<mongodb-host> -e MONGODB_PORT=<mongodb-port> bitergia/fiware-orion:0.23.0
```

### Stopping the container ###

`docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly clean-up things.

To avoid this, we suggest to use the [docker-stop](https://github.com/Bitergia/docker/tree/master/utils#docker-stop) script available in this [repository](https://github.com/Bitergia/docker/tree/master/utils). This script basically sends the SIGPWR signal to /sbin/init inside the container, triggering the shutdown process and allowing the running services to cleanly shutdown.

### About SSH ###

SSH is enabled by default with a pre-generated insecure SSH key. As the image us based in `bitergia/centos-6` image, it contains the same SSH privileges.
That means, for accessing the image through SSH, you will need the SSH insecure keys. Those keys are the following:

* `bitergia-docker` - Available [here](https://raw.githubusercontent.com/Bitergia/docker/master/baseimages/bitergia-docker)
* `bitergia-docker.pub` - Available [here](https://raw.githubusercontent.com/Bitergia/docker/master/baseimages/bitergia-docker.pub)

Once the container is up, you can access the container easily by using our own [docker-ssh](https://github.com/Bitergia/docker/tree/master/utils#docker-ssh) script:

```
docker-ssh bitergia@<container-id>
```

Or you can just use the old-fashioned way to access a docker container: 

```
ssh bitergia@<container-ip>
```

Container IP can be retrieved using the following command:

```
docker inspect -f "{{ .NetworkSettings.IPAddress }}" <container-id>
```

You can also use the [get-container-ip](https://github.com/Bitergia/docker/tree/master/utils#get-container-ip) script provided in this repository. 

#### Using/generate your own SSH key ####

Information on how to do that can be found [here](https://github.com/Bitergia/docker/tree/master/baseimages/centos#about-ssh).
**Note** that the information below is regarding the `bitergia/centos-6` baseimage. If you have already pulled or made a `bitergia/fiware-orion` image based in the `bitergia/centos-6` image before applying the keys change, you will need to re-build both images again.

## User feedback ##

### Documentation ###

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/fiware-orion).

### Issues ###

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
