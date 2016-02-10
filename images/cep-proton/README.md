## Complex Event Processing (CEP) - Proactive Technology Online (Proton) Docker image

[Proton](https://github.com/ishkin/Proton) is an implementation of the FIWARE Complex Event Processing Generic Enabler.

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/complex-event-processing-cep-proactive-technology-online).

## Image contents

- [x] `tomcat:7.0` official image available [here](https://hub.docker.com/_/tomcat/)
- [x] [Proton](https://github.com/ishkin/Proton) from master branch.

## Usage

Create a container using `bitergia/cep-proton` image is as easy as doing:

```
docker run -d --name <container-name> bitergia/cep-proton:master
```

You can see the logs by issuing the following command:

```
docker logs -f <container-name>
```

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/cep-proton).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
