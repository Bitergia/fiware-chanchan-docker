## MongoDB Docker image

Dockerfile to build a [MongoDB](https://www.mongodb.com/what-is-mongodb) container image which can be linked to other containers.

**Table of Contents**  

- [MongoDB Docker image](#mongodb-docker-image)
- [Requirements](#requirements)
- [Image contents](#image-contents)
- [Building the image](#building-the-image)
- [Usage](#usage)
- [Stopping the container](#stopping-the-container)
- [About SSH](#about-ssh)
  - [Using/generate your own SSH key](#usinggenerate-your-own-ssh-key)

## Requirements

* [Docker](https://github.com/docker/docker)
* `bitergia/centos-6` baseimage, available at [Dockerhub](https://registry.hub.docker.com/u/bitergia/centos-6)

## Image contents

- [x] `bitergia/centos-6` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/centos#image-contents)
- [x] MongoDB repository
- [x] MongoDB
- [x] Listening on port `27017`

## Building the image

This images are intended for Docker usage. Images are already built at [Bitergia dockerhub](https://registry.hub.docker.com/repos/bitergia/).

Still, if you want to build the entire image yourself, you can use the Makefile provided:

Clone this repository:

```
git clone https://github.com/Bitergia/fiware-chanchan.git
cd fiware-chanchan/docker/images
```

Build the image:

```
make mongodb-2.6
```
or

```
make mongodb-3.0
```

And that's it!

## Usage

Create a container using `bitergia/mongodb` image is as easy as doing:

```
docker run -d --name <container-name> bitergia/mongodb
```

* **Data storage**

As there are several ways to store data, we suggest to follow the [Docker Documentation](https://docs.docker.com/userguide/dockervolumes/) to check which procedure suits you the best.

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
**Note** that the information below is regarding the `bitergia/centos-6` baseimage. If you have already pulled or made a `bitergia/mongodb` image based in the `bitergia/centos-6` image before applying the keys change, you will need to re-build both images again.