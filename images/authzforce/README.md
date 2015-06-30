## Authorization PDP - AuthZForce Docker minimal image

[Authorization PDP - AuthZForce](http://catalogue.fiware.org/enablers/authorization-pdp-authzforce) is a Reference Implementation of Authorization PDP (formerly Access Control GE).

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/authorization-pdp-authzforce).

This image is intended to work together with [Identity Manager - Keyrock](http://catalogue.fiware.org/enablers/identity-management-keyrock) and [PEP Proxy Wilma](http://catalogue.fiware.org/enablers/pep-proxy-wilma) generic enabler; and also integrated in our [Chanchan APP](https://github.com/Bitergia/fiware-chanchan).

**Table of Contents**

- [Requirements](#requirements)
- [Image contents](#image-contents)
- [Building the image](#building-the-image)
- [Usage](#usage)
- [Stopping the container](#stopping-the-container)
- [About SSH](#about-ssh)
  - [Using/generate your own SSH key](#usinggenerate-your-own-ssh-key)

## Requirements

* [Docker](https://github.com/docker/docker)
* `bitergia/ubuntu-trusty` baseimage, available at [Dockerhub](https://registry.hub.docker.com/u/bitergia/ubuntu-trusty)

## Image contents

- [x] `bitergia/ubuntu-trusty` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu#image-contents)
- [x] openjdk-7-jdk
- [x] tomcat7
- [x] Authzforce 4.2.0

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
make authzforce
```

And that's it!

## Usage

This image gives you a minimal installation for testing purposes. The [AuthZForce Installation and administration guide](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Authorization_PDP_-_AuthZForce_-_Installation_and_Administration_Guide_%28R4.2.0%29#Appendix) provides you a better approach for using it in a production environment.

This image, if used with the Chanchan APP, is fully provided. [PEP Proxy Wilma](http://catalogue.fiware.org/enablers/pep-proxy-wilma) image is aware of the [Domain creation](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Authorization_PDP_-_AuthZForce_-_Installation_and_Administration_Guide_%28R4.2.0%29#Domain_Creation). 

Still, you can always do it your self. As stands in the [AuthZForce Installation and administration guide](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Authorization_PDP_-_AuthZForce_-_Installation_and_Administration_Guide_%28R4.2.0%29#Policy_Domain_Administation) you can:

* **Create a domain**

```
curl -s --request POST \
--header "Accept: application/xml" \
--header "Content-Type: application/xml;charset=UTF-8" \
--data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' \
 http://<authzforce-container-ip>:8080/authzforce/domains
```

* **Retrieve the domain ID**

```
curl -s --request GET http://<authzforce-container-ip>:8080/authzforce/domains
```

* **Domain removal**

```
curl --verbose --request DELETE \
--header "Content-Type: application/xml;charset=UTF-8" \
--header "Accept: application/xml" \
http://<authzforce-container-ip>:8080/authzforce/domains/<domain-id>
```

* **User and Role Management Setup && Domain Role Assignment**

This tasks are now delegated into the [Identity Manager - Keyrock](http://catalogue.fiware.org/enablers/identity-management-keyrock) enabler. Here you can find how to use the interface for that purpose: [How to manage AuthZForce in Fiware](https://www.fiware.org/devguides/handling-authorization-and-access-control-to-apis/how-to-manage-access-control-in-fiware/).


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
**Note** that the information below is regarding the `bitergia/ubuntu-trusty` baseimage. If you have already pulled or made a `bitergia/authzforce` image based in the `bitergia/ubuntu-trusty` image before applying the keys change, you will need to re-build both images again.