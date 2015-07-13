## Backend Device Management - IDAS IoT Agent for OMA LWM2M over CoAP Docker image

The [Backend Device Management](http://catalogue.fiware.org/enablers/backend-device-management-idas) is an implementation of the Backend Device Management GE. 

Find detailed information of this Generic enabler at [Architecture Description](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/FIWARE.ArchitectureDescription.IoT.Backend.DeviceManagement).

## Requirements

- MongoDB. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/mongodb/).
- Orion. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/fiware-orion/).


## Image contents

- [x] `bitergia/centos-6` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/centos#image-contents)
- [x] [Fiware IoT Agent for OMA LWM2M over CoAP](https://github.com/telefonicaid/lightweightm2m-iotagent)


## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MongoDB database
   * Data-only container for the MongoDB database
   * Orion Context Broker as a service
   * IDAS IoT Agent for OMA LWM2M over CoAP

The file `idas.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan/master/docker/compose/idas.yml).

Once you get it, you just have to:

```
docker-compose -f idas.yml up -d idasiotalwm2m
```
And all the services will be up. End to end testing can be done using the complete [chanchanapp docker compose](https://github.com/Bitergia/fiware-chanchan/blob/master/docker/compose/chanchan-new.yml).

**Note**: as retrieving the `<container-ip>` can be a bit 'tricky', we've created a set of utilities and useful scripts for handling docker images. You can find them all [here](https://github.com/Bitergia/docker/tree/master/utils).

 
## What if I don't want to use docker-compose?

No problem, the only thing is that you will have to deploy a MongoDB and Orion yourself and modify the [config parameters](https://github.com/Bitergia/fiware-chanchan/blob/master/docker/images/idas/iota-lwm2m/0.2.0/config.js).

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/idas-iota-lwm2m:0.2.0
```

By running this, it expects a MongoDB database and Orion running on:

    * MONGODB_HOSTNAME: `mongodb`
    * MONGODB_PORT: `27017`
    * MONGODB_DATABASE: `iota-cpp`
    * ORION_HOSTNAME: `orion`
    * ORION_PORT: `10026`

And also, the following settings are pre-configured:

	* IOTA_SERVER_PORT: `4041`
	* IOTA_DEFAULT_SERVICE: `bitergiaidas`
	* IOTA_DEFAULT_SUBSERVICE: `/devices`

So if you have your MongoDB and Orion somewhere else, or you want to configure the port or default service, just attach it as a parameter like:

```
docker run -d --name <container-name> \
-e MONGODB_HOSTNAME=<mongodb-host> \
-e MONGODB_PORT=<mongodb-port> \
-e MONGODB_DATABASE=<mongodb-database> \
-e ORION_HOSTNAME=<orion-host> \
-e ORION_PORT=<orion-port> \
-e IOTA_SERVER_PORT=<iota-port> \
-e IOTA_DEFAULT_SERVICE=<iota-service> \
-e IOTA_DEFAULT_SUBSERVICE=<iota-subservice> \
bitergia/idas-iota-cpp:1.2.0
```


## Stopping the container

`docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly clean-up things.

To avoid this, we suggest to use the [docker-stop](https://github.com/Bitergia/docker/tree/master/utils#docker-stop) script available in this [repository](https://github.com/Bitergia/docker/tree/master/utils). This script basically sends the SIGPWR signal to /sbin/init inside the container, triggering the shutdown process and allowing the running services to cleanly shutdown.

## About SSH

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

### Using/generate your own SSH key

Information on how to do that can be found [here](https://github.com/Bitergia/docker/tree/master/baseimages/centos#about-ssh).
**Note** that the information below is regarding the `bitergia/centos-6` baseimage. If you have already pulled or made a `bitergia/idas-iota-lwm2m` image based in the `bitergia/centos-6` image before applying the keys change, you will need to re-build both images again.

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan/tree/master/docker/images/idas/iota-lwm2m).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan/issues).
