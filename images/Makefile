MONGO_VERSION = 2.6
ORION_VERSION = 0.23.0
MARIADB_VERSION = 10.0
CYGNUS_VERSION = 0.5.1
IDM_VERSION = master
WILMA_VERSION = 4.3.0
AUTHZFORCE_VERSION = 4.2.0
IDAS_LWM2M_VERSION = 0.2.0
IDAS_IOTACPP_VERSION = 1.2.0

.PHONY: help
help:
	$(info )
	$(info This makefile will help you build docker images for the Fiware-ChanChan)
	$(info components based on the bitergia baseimages.)
	$(info )
	$(info Available options:)
	$(info )
	$(info - all:			Build all available images)
	$(info - idm-keyrock:		Build Keyrock IdM image (based on master version))
	$(info - idm-keyrock-5.1.0:	Build Keyrock IdM image (based on release 5.1.0))
	$(info - idas:			Build IDAS images)
	$(info - pep-wilma:		Build PEP Wilma Proxy image)
	$(info - cygnus:		Build Cygnus image)
	$(info - authzforce:		Build Authzforce image (based on the GE version))
	$(info - idas-iota-cpp:	Build IDAS IoTAgent CPlusPlus image (Ultralight 2.0, MQTT, TT))
	$(info - idas-iota-lwm2m:	Build IDAS OMA Lightweight M2M IoTAgent image)
	$(info )
	$(info Other available options:)
	$(info - ul20-client:		Build IDAS UltraLight 2.0 Test Client image)
	$(info - cygnus-develop:	Build Cygnus image from git develop branch)
	$(info )
	$(info Deprecated images:  The following images have been deprecated.  See README.md)
	$(info - orion:		Build Orion Context Broker $(ORION_VERSION) image)
	$(info - mongodb:		Build MongoDB $(MONGO_VERSION) image)
	$(info - idmauthlegacy:	Build IdM legacy (ruby), Orion PEP and Keypass image)
	$(info - mariadb:		Build MariaDB $(MARIADB_VERSION) image)
	$(info - orion.ubuntu:		Build Orion Context Broker using Ubuntu baseimage)
	$(info - orion-develop:		Build Orion Context Broker from git develop baseimage)
	$(info - orion-0.22.0:		Build Orion Context Broker 0.22.0 baseimage)
	$(info - orion-0.22.0.ubuntu:	Build Orion Context Broker 0.22.0 using Ubuntu baseimage)
	$(info - mongodb-2.6:		Build MongoDB 2.6 image)
	$(info - mongodb-3.0:		Build MongoDB 3.0 image)
	$(info - mariadb-5.5:		Build MariaDB 5.5 image)
	$(info - mariadb-10.0:		Build MariaDB 10.0 image)
	$(info - idm-keyrock-4.3.0:	Build Keyrock IdM image (based on the new Keyrock version))
	$(info )
	@echo ""

.PHONY: idm-keyrock
idm-keyrock:
	docker build -t bitergia/idm-keyrock:$(IDM_VERSION) idm-keyrock/$(IDM_VERSION)/
.PHONY: idm-keyrock-5.1.0
idm-keyrock-5.1.0:
	@$(MAKE) idm-keyrock IDM_VERSION=5.1.0

.PHONY: authzforce
authzforce:
	docker build -t bitergia/authzforce:$(AUTHZFORCE_VERSION) authzforce/$(AUTHZFORCE_VERSION)/

.PHONY: pep-wilma
pep-wilma:
	docker build -t bitergia/pep-wilma:$(WILMA_VERSION) pep-wilma/$(WILMA_VERSION)/

.PHONY: cygnus cygnus-develop
cygnus-develop:
	@$(MAKE) cygnus CYGNUS_VERSION=develop
cygnus:
	docker build -t bitergia/cygnus:$(CYGNUS_VERSION) cygnus/$(CYGNUS_VERSION)/

.PHONY: idas idas-iota-lwm2m idas-iota-cpp ul20-client
idas: idas-iota-lwm2m idas-iota-cpp
ul20-client:
	docker build -t bitergia/ul20-client idas/ul20-client
idas-iota-lwm2m:
	docker build -t bitergia/idas-iota-lwm2m:$(IDAS_LWM2M_VERSION) idas/iota-lwm2m/$(IDAS_LWM2M_VERSION)/

idas-iota-cpp:
	docker build -t bitergia/idas-iota-cpp:$(IDAS_IOTACPP_VERSION) idas/iota-cpp/$(IDAS_IOTACPP_VERSION)/

.PHONY: all
all: idm-keyrock authzforce pep-wilma cygnus idas

.PHONY: clean clean_idm-keyrock
clean: clean_idm-keyrock

clean_idm-keyrock:
	-@docker rmi bitergia/idm-keyrock

deprecation-warning:
	$(warning )
	$(warning This image has been deprecated and is no longer maintained.)
	$(warning Use the official image where available (see README.md).)
	$(warning )
ifneq ($(BUILD_DEPRECATED), yes)
	$(warning Use 'BUILD_DEPRECATED=yes ${MAKE} ...' to force image build.)
	$(error )
else
	$(warning Using BUILD_DEPRECATED=yes.)
	$(warning Forced build.)
endif

# The following images have been deprecated.

.PHONY: orion-0.22.0 orion-develop orion
orion-0.22.0:
	@$(MAKE) orion ORION_VERSION=0.22.0
orion-develop:
	@$(MAKE) orion ORION_VERSION=develop
orion: deprecation-warning
	docker build -t bitergia/fiware-orion:$(ORION_VERSION) fiware-orion/$(ORION_VERSION)/

.PHONY: idmauthlegacy
idmauthlegacy: deprecation-warning
	docker build -t bitergia/$@ $@/

.PHONY: mongodb-2.6 mongodb-3.0 mongodb
mongodb-2.6:
	@$(MAKE) mongodb MONGO_VERSION=2.6
mongodb-3.0:
	@$(MAKE) mongodb MONGO_VERSION=3.0
mongodb: deprecation-warning
	docker build -t bitergia/mongodb:$(MONGO_VERSION) mongodb/$(MONGO_VERSION)/

.PHONY: mariadb-10.0 mariadb-5.5 mariadb
mariadb-10.0:
	@$(MAKE) mariadb MARIADB_VERSION=10.0
mariadb-5.5:
	@$(MAKE) mariadb MARIADB_VERSION=5.5
mariadb: deprecation-warning
	docker build -t bitergia/mariadb:$(MARIADB_VERSION) mariadb/$(MARIADB_VERSION)/

.PHONY: orion.ubuntu orion-0.22.0.ubuntu
orion-0.22.0.ubuntu:
	@$(MAKE) orion.ubuntu ORION_VERSION=0.22.0
orion.ubuntu: deprecation-warning
	docker build -t bitergia/fiware-orion:$(ORION_VERSION) -f fiware-orion/$(ORION_VERSION)/Dockerfile.$@ fiware-orion/$(ORION_VERSION)/

.PHONY: idm-keyrock-4.3.0
idm-keyrock-4.3.0: deprecation-warning
	@$(MAKE) idm-keyrock IDM_VERSION=4.3.0
