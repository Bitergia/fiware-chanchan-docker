## PEP Proxy - Wilma Docker image

The [PEP Proxy - Wilma](https://github.com/ging/fi-ware-pep-proxy) is an implementation of the implementation of PEP Proxy Generic Enabler.

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/pep-proxy-wilma).

## Image contents

- [x] `bitergia/ubuntu-trusty` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu#image-contents)
- [x] Node.js
- [x] PEP Wilma

## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * Orion (service protected)
   * Authzforge (permissions persitance)
   * IDM KeyRock (identitiy management)
   * PEP Wilma as a service

The file `pep-wilma.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan/master/docker/compose/pep-wilma.yml).

Once you get it, you just have to:

```
docker-compose -f pep-wilma.yml up -d
```

And all the services will be up. End to end testing can be done using the complete [chanchanapp docker compose](https://github.com/Bitergia/fiware-chanchan/blob/master/docker/compose/chanchan-new.yml).

**Note**: as retrieving the `<container-ip>` can be a bit 'tricky', we've created a set of utilities and useful scripts for handling docker images. You can find them all [here](https://github.com/Bitergia/docker/tree/master/utils).

 
## What if I don't want to use docker-compose?

No problem, the only thing is that you will have to deploy IDM, Authzforge and Orion containers yourself and their IPs with the hosts idm, authzforge and orion in wilma-pep container.

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
**Note** that the information below is regarding the `bitergia/ubuntu-trusty` baseimage. If you have already pulled or made a `bitergia/pep-wilma image based in the `bitergia/ubuntu-trusty` image before applying the keys change, you will need to re-build both images again.

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan/tree/master/docker/images/pep-wilma).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan/issues).
