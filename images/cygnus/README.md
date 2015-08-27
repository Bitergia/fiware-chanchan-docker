## Cygnus - Docker minimal image

[Cygnus](https://github.com/telefonicaid/fiware-cygnus) is a connector in charge of persisting Orion context data in certain configured third-party storages, creating a historical view of such data.

Cygnus uses the subscription/notification feature of Orion.

This image is intended to work together with [Orion](https://registry.hub.docker.com/u/bitergia/fiware-orion/) and [MariaDB](https://registry.hub.docker.com/_/mariadb/) for data persistance; and also integrated in FIWARE [Developers Guide Application]https://github.com/Bitergia/fiware-devguide-app).

## Image contents

- [x] `centos:6` baseimage available [here](https://registry.hub.docker.com/_/centos/)
- [x] openjdk-6-jdk
- [x] Apache Flume 1.4.0
- [x] Cygnus (built from git develop branch sources)

## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MariaDB database
   * Data-only container for the MariaDB database
   * Orion Context Broker as a service
   * Cygnus as a service

The file `cygnus.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/cygnus.yml).

Once you get it, you just have to:

```
docker-compose -f cygnus.yml up -d
```

And all the services will be up. End to end testing can be done by doing publishing in orion context with entities [following this format](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/cygnus/0.5.1/docker-entrypoint.sh#L115).

 
## What if I don't want to use docker-compose?

No problem, the only thing is that you will have to deploy a MariaDB and Orion Context Broker yourself and specify the parameters.

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/cygnus:develop
```

By running this, it expects the following parameters (mandatory):

	* MYSQL_HOST
	* MYSQL_PORT
	* MYSQL_USER
	* MYSQL_PASSWORD

And the following ones are set by default to:

	* ORION_HOSTNAME: `orion`
	* ORION_PORT: `1026`

So if you have your MariaDB and Orion somewhere else, just attach its parameters like:

```
docker run -d --name <container-name> \
-e MYSQL_HOST=<mysql-host> \
-e MYSQL_PORT=<mysql-port> \
-e MYSQL_USER=<mysql-user> \
-e MYSQL_PASSWORD=<mysql-password> \
-e ORION_HOSTNAME=<orion-host> \
-e ORION_PORT=<orion-port> \
bitergia/cygnus:develop
```

If you want to use your own custom configuration file, add it as a volume like this:
```
docker run -d --name <container-name> --volume <my-cygnus.conf>:/config/cygnus.conf bitergia/cygnus:develop
```

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/cygnus).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
