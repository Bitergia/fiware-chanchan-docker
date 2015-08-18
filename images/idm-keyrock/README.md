## IDM KeyRock Docker image

The [IDM KeyRock](https://github.com/ging/fi-ware-idm) is an implementation of the FIWARE Identity Manager Generic Enabler.

Find detailed information of this Generic enabler at [Fiware catalogue](http://catalogue.fiware.org/enablers/identity-management-keyrock).

## Image contents

- [x] `ubuntu:14.04` baseimage available [here](https://hub.docker.com/_/ubuntu/)
- [x] KeyRock backend based on OpenStack KeyStone
- [x] KeyRock frontend based on OpenStack Horizon
- [x] Keystone running on port `5000`
- [x] Horizon running on port `443`

## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * Authzforce
   * IDM KeyRock

The file `idm-keyrock.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/idm-keyrock.yml).

Once you get it, you just have to:

```
docker-compose -f idm-keyrock.yml up -d
```

And all the services will be up. You can test it accessing the IDM KeyRock we interface:

```
http://<container-ip>
```

**Note**: as retrieving the `<container-ip>` can be a bit 'tricky', we've created a set of utilities and useful scripts for handling docker images. You can find them all [here](https://github.com/Bitergia/docker/tree/master/utils).

 
## What if I don't want to use docker-compose?

No problem, you can run the container alone and use it services.

```
docker run -d --name <container-name> bitergia/idm-keyrock:4.3.0
```

By running this, it expects an Authzforce instance running by default on:

    * AUTHZFORCE_HOSTNAME: `authzforce`
    * AUTHZFORCE_PORT: `8080`
    * MAGIC_KEY: `daf26216c5434a0a80f392ed9165b3b4`

So if you have your Authzforce somewhere else, just attach it as a parameter like:

```
docker run -d --name <container-name> \
-e AUTHZFORCE_HOSTNAME=<authzforce-host> \
-e AUTHZFORCE_PORT=<authzforce-port> \
-e MAGIC_KEY=<magic-key> \
bitergia/idm-keyrock:4.3.0
```

## IdM Users, Organizations, Apps, Roles and Permissions

This IdM image was intended to work for the [Fiware Chanchan](https://github.com/Bitergia/fiware-chanchan). Due to this, we've generated Users, Organizations, Apps, Roles and Permissions adapted to it. 

**Note** the following provision is intended just for testing purposes. To add/remove information to this image, you can always use the [Identity API](http://developer.openstack.org/api-ref-identity-v3.html)

### Users

| Role     | Username           | Password   |
|----------|--------------------|------------|
| Admin    | idm                | idm        |
| Provider | pepproxy@test.com  | test       |
| Owner    | user0@test.com     | test       |
| Owner    | user1@test.com     | test       |
| Owner    | user2@test.com     | test       |
| Owner    | user3@test.com     | test       |
| Owner    | user4@test.com     | test       |
| Owner    | user5@test.com     | test       |
| Owner    | user6@test.com     | test       |
| Owner    | user7@test.com     | test       |
| Owner    | user8@test.com     | test       |
| Owner    | user9@test.com     | test       |

### Organizations (or *projects* if using the [Identity API](http://developer.openstack.org/api-ref-identity-v3.html))

| Organization name   | Description                    | Users                     |
|---------------------|--------------------------------|---------------------------|
| Organization A      | Test Organization A            | user0@test.com (owner)    |
| Organization B      | Test Organization B            | user1@test.com (owner)    |


### Apps

| Application name  | Description                       | URL                       | Redirect URI                     |
|-------------------|-----------------------------------|---------------------------|----------------------------------|
| FIWARE devGuide   | Fiware devGuide Test Application  | http://compose_devguide_1 | http://compose_devguide_1/login  |

### Roles

| Role name           | Granted to user                         | 
|---------------------|-----------------------------------------|
| Provider            | pepproxy@test.com                       |
| Orion Operations    | user0@test.com                          |
|                     | user1@test.com                          |

### Permissions

We've added several permissions for Orion Operations. You can check all of them by accessing the IdM or [here](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/idm-keyrock/4.3.0/keystone.py#L537)

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/idm-keyrock).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
