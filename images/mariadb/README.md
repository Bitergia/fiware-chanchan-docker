## MariaDB Docker image

Dockerfile to build a [MariaDB](https://mariadb.org/en/about) container image which can be linked to other containers.

## Supported tags and respective `Dockerfile` links

* [`5.5`   (5.5/Dockerfile](https://github.com/Bitergia/fiware-chanchan/blob/master/docker/images/mariadb/5.5/Dockerfile))
* [`10.0`   (10.0/Dockerfile](https://github.com/Bitergia/fiware-chanchan/blob/master/docker/images/mariadb/10.0/Dockerfile))

## Image contents

- [x] `bitergia/ubuntu-trusty` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu#image-contents)
- [x] MariaDB repository
- [x] debconf-utils
- [x] mariadb-server
- [x] Listening on port `3306`


## Usage

Create a container using `bitergia/mariadb` image is as easy as doing:

```
docker run -d --name <container-name> bitergia/mariadb:5.5
```

or

```
docker run -d --name <container-name> bitergia/mariadb:10.0
```

* **Data storage**

As there are several ways to store data, we suggest to follow the [Docker Documentation](https://docs.docker.com/userguide/dockervolumes/) to check which procedure suits you the best.

## Stopping the container

`docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly clean-up things.

To avoid this, we suggest to use the [docker-stop](https://github.com/Bitergia/docker/tree/master/utils#docker-stop) script available in this [repository](https://github.com/Bitergia/docker/tree/master/utils). This script basically sends the SIGPWR signal to /sbin/init inside the container, triggering the shutdown process and allowing the running services to cleanly shutdown.

## About SSH

SSH is enabled by default with a pre-generated insecure SSH key. As the image us based in `bitergia/ubuntu-trusty` image, it contains the same SSH privileges.
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

Information on how to do that can be found [here](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu#about-ssh).
**Note** that the information below is regarding the `bitergia/ubuntu-trusty` baseimage. If you have already pulled or made a `bitergia/mariadb` image based in the `bitergia/ubuntu-trusty` image before applying the keys change, you will need to re-build both images again.

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan/tree/master/docker/images/mariadb).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan/issues).