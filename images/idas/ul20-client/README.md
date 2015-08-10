## Backend Device Management - UL2.0/HTTP simple client Docker image

The [Backend Device Management](http://catalogue.fiware.org/enablers/backend-device-management-idas) is an implementation of the Backend Device Management GE. 

Find detailed information of this Generic enabler at [Architecture Description](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/FIWARE.ArchitectureDescription.IoT.Backend.DeviceManagement).

## Requirements

- Ultralight 2.0/HTTP IoT Agent. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/idas-iota-cpp/).
- Orion. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/fiware-orion/).


## Image contents

- [x] `centos:centos6` baseimage available [here](https://registry.hub.docker.com/_/centos/)
- [x] [Fiware Figway](https://github.com/telefonicaid/fiware-figway) scripts to interact with IDAS IoT Agent using the Ultralight 2.0/HTTP protocol.
- [x] Custom scripts to read thermal sensors data and send it to the Iot Agent using Fiware Figway scripts.

## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MongoDB database
   * Data-only container for the MongoDB database
   * Orion Context Broker as a service
   * IDAS IoT Agent for UL2.0/HTTP, MQTT and Thinking Things
   * This scripts.

The file `idas.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/idas.yml).

Once you get it, you just have to:

```
docker-compose -f idas.yml up -d ul20client
```
And all the services will be up.
 
## What if I don't want to use docker-compose?

No problem, the only thing is that you will have to deploy a MongoDB, orion and IoT Agent yourself and modify the parameters for the script (see below).

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/ul20-client:latest --acpi
```

By running this, it expects Orion and IoT Agent running on:

    * ORION_HOSTNAME: `orion`
    * ORION_PORT: `1026`
	* IOTA_HOSTNAME: `iota`
	* IOTA_PORT: `8080`

You can set some extra parameters via the following environment variables:

	* UL20_SERVICE_NAME: the service name to register with the IoT Agent,
	* UL20_SERVICE_PATH: the path for the service,
	* UL20_API_KEY: the api key to use when communicating with the IoT Agent,

This variables have predefined default values if not set.

So if you have your Orion and IoT Agent somewhere else, just attach it as a parameter like:

```
docker run -d --name <container-name> \
-e ORION_HOSTNAME=<orion-host> \
-e ORION_PORT=<orion-port> \
-e IOTA_HOSTNAME=<iota-host> \
-e IOTA_PORT=<iota-port> \
bitergia/ul20-client:latest
```

## Parameters ##

The image pass all the specified parameters to the custom script.  This are the available parameters:

```
  -h  --help                 Show this help.
  -v  --version              Show program version.

  Required parameters:

  -f  --fake                 Use a fake sensor (generates random data).  Use --min and --max to set minimum and maximum values allowed.
  -a  --acpi                 Use acpi detected thermal sensors.
  -s  --sys                  Use sensors from /sys/class/thermal/.

  Extra parameters for fake sensor:

  -m  --min <value>          Minimum <value> for fake sensor.
  -M  --max <value>          Maximum <value> for fake sensor.
  -V  --variance <value>     Maximum variance between generated values.
  -i  --id <id>              Id for the fake sensor.  Default value is '0'.
  -t  --type <type>          Type of the fake sensor.  Default value is 'random'.

  Optional parameters:

  -d  --delay <value>        Delay in seconds between sensor readings. Default is 10 seconds.
```

The script requires one of `--fake`, `--acpi` or `--sys` to be specified.  So to try to use the thermal sensors detected via acpi, we just use `--acpi`.

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/idas/iota-cpp).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
