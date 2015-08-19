## Authorization PDP - AuthZForce Docker minimal image

[Authorization PDP - AuthZForce](http://catalogue.fiware.org/enablers/authorization-pdp-authzforce) is a Reference Implementation of Authorization PDP (formerly Access Control GE).

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/authorization-pdp-authzforce).

This image is intended to work together with [Identity Manager - Keyrock](http://catalogue.fiware.org/enablers/identity-management-keyrock) and [PEP Proxy Wilma](http://catalogue.fiware.org/enablers/pep-proxy-wilma) generic enabler; and also integrated in our [Chanchan APP](https://github.com/Bitergia/fiware-chanchan).

## Image contents

- [x] `tomcat:7.0` official image available [here](https://hub.docker.com/_/tomcat/)
- [x] Authzforce 4.2.0

## Usage

This image gives you a minimal installation for testing purposes. The [AuthZForce Installation and administration guide](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Authorization_PDP_-_AuthZForce_-_Installation_and_Administration_Guide_%28R4.2.0%29#Appendix) provides you a better approach for using it in a production environment.

This image, if used with the [Chanchan APP](https://github.com/Bitergia/fiware-chanchan), is fully provided for testing. [PEP Proxy Wilma](http://catalogue.fiware.org/enablers/pep-proxy-wilma)incluided in Chanchan APP is aware of the [Domain creation](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Authorization_PDP_-_AuthZForce_-_Installation_and_Administration_Guide_%28R4.2.0%29#Domain_Creation). 

Still, you can always do it yourself. 

Create a container using `bitergia/authzforce` image by doing:

```
docker run -d --name <container-name> bitergia/authzforce:4.2.0
```

As stands in the [AuthZForce Installation and administration guide](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Authorization_PDP_-_AuthZForce_-_Installation_and_Administration_Guide_%28R4.2.0%29#Policy_Domain_Administation) you can:

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

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/authzforce).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
