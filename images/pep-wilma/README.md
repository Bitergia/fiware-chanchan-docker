## PEP Proxy - Wilma Docker image

The [PEP Proxy - Wilma](https://github.com/ging/fi-ware-pep-proxy) is an implementation of PEP Proxy Generic Enabler.

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/pep-proxy-wilma).

## Image contents

- [x] `bitergia/ubuntu-trusty` baseimage contents listed [here](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu#image-contents)
- [x] Node.js
- [x] PEP Wilma
- [x] PEP Wilma running on port `1026`

## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file for testing that launches:

   * Orion (a service to protect)
   * Authzforce (permissions persitance)
   * IDM KeyRock (identitiy management)
   * PEP Wilma as a service

The file `pep-wilma.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/pep-wilma.yml).

Once you get it, you just have to:

```
docker-compose -f pep-wilma.yml up -d
```

And all the services will be up. At this point, you will have to use the `X-Auth-Token` to be able to make requests against the protected resource, as described [here](https://github.com/ging/fi-ware-idm/wiki/Using-the-FIWARE-LAB-instance#authorization-code-grant).

In our image, you can retrieve the `X-Auth-Token` by doing:

```
docker exec -i -t <pepwilma-container-name> auth-token.sh <user-email> <password>
```

And you will get a fresh one. This step can be done as many times as you want, to get a fresh token. So in our IdM, we've already authorized `user0@test.com` to make requests against Orion. You just have to get a token for that user:

```
docker exec -i -t <pepwilma-container-name> auth-token.sh user0@test.com test
```

And then send one of the [authorized requests](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/idm-keyrock#permissions) against the Proxy. For example:

```
(curl <wilmapep-container-ip>:<wilmapep-container-port>/v1/updateContext -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-Auth-Token: <x-auth-token>' -d @- | python -mjson.tool) <<EOF
{
    "contextElements": [
        {
            "type": "Room",
            "isPattern": "false",
            "id": "Room1",
            "attributes": [
            {
                "name": "temperature",
                "type": "float",
                "value": "23"
            },
            {
                "name": "pressure",
                "type": "integer",
                "value": "720"
            }
            ]
        }
    ],
    "updateAction": "APPEND"
}
EOF
```

**Note**: as retrieving the `<container-ip>` can be a bit 'tricky', we've created a set of utilities and useful scripts for handling docker images. You can find them all [here](https://github.com/Bitergia/docker/tree/master/utils).

And that's it!

You can always play with the users, roles and permissions at IdM (add, remove...) to check that the resource is being well protected :)

For that purpose, the user aware of roles management is the `pepproxy@test.com` (provider). This means, you will have to login with this user in order to be able to handle the roles and permissions of the application. Check [here](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/idm-keyrock#idm-users-organizations-apps-roles-and-permissions) the full list of users, organizations, roles and apps provided.

## What if I don't want to use docker-compose?

No problem, the only thing is that you will have to deploy IDM, Authzforce and Orion containers yourself and their IPs with the hosts idm, authzforce and orion in wilma-pep container.

```
docker run -d --name <container-name> bitergia/pep-wilma:4.3.0
```

By running this, it expects an Authzforce, IdM Keystone and App to protect running by default on:

	* AUTHZFORCE_HOSTNAME: `authzforce`
    * AUTHZFORCE_PORT: `8080`
	* IDM_KEYSTONE_HOSTNAME: `idm`
    * IDM_KEYSTONE_PORT: `5000`
    * APP_HOSTNAME: `orion`
    * APP_PORT: `10026`

Also, the following parameters can be re-configured in the PEP-Wilma:

	* PEP_USERNAME: `pepproxy@test.com`
 	* PEP_PASSWORD: `test`
	* PEP_PORT: `1026`
	* IDM_USERNAME: `user0@test.com`
	* IDM_USERPASS: `test`
	* MAGIC_KEY: `daf26216c5434a0a80f392ed9165b3b4`

So if you have your Authzforce, Keystone and Orion (or app to protect) somewhere else, just attach it as a parameter like:

```
docker run -d --name <container-name> \
-e AUTHZFORCE_HOSTNAME=<authzforce-host> \
-e AUTHZFORCE_PORT=<authzforce-port> \
-e IDM_KEYSTONE_HOSTNAME=<keystone-host> \
-e IDM_KEYSTONE_PORT=<keystone-port> \
-e APP_HOSTNAME=<app-host> \
-e APP_PORT=<app-port> \
bitergia/pep-wilma:4.3.0
```

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
**Note** that the information below is regarding the `bitergia/ubuntu-trusty` baseimage. If you have already pulled or made a `bitergia/pep-wilma` image based in the `bitergia/ubuntu-trusty` image before applying the keys change, you will need to re-build both images again.

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/pep-wilma).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
