MONGO_VERSION = 2.6
ORION_VERSION = 0.23.0
MARIADB_VERSION = 10.0
CYGNUS_VERSION = 0.5.1
IDM_VERSION = 4.3.0
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
	$(info - idm-keyrock:		Build Keyrock IdM image (based on the new Keyrock version))
	$(info - orion:		Build Orion Context Broker $(ORION_VERSION) image)
	$(info - mongodb:		Build MongoDB $(MONGO_VERSION) image)
	$(info - idas:			Build IDAS images)
	$(info - pep-wilma:		Build PEP Wilma Proxy image)
	$(info - cygnus:		Build Cygnus image)
	$(info - authzforce:		Build Authzforce image (based on the GE version))
	$(info - idmauthlegacy:	Build IdM legacy (ruby), Orion PEP and Keypass image)
	$(info - idas-iota-cpp:	Build IDAS IoTAgent CPlusPlus image (Ultralight 2.0, MQTT, TT))
	$(info - idas-iota-lwm2m:	Build IDAS OMA Lightweight M2M IoTAgent image)
	$(info - mariadb:		Build MariaDB $(MARIADB_VERSION) image)
	$(info )
	$(info Other available options:)
	$(info - orion.ubuntu:		Build Orion Context Broker using Ubuntu baseimage)
	$(info - orion-0.22.0:		Build Orion Context Broker 0.22.0 baseimage)
	$(info - orion-0.22.0.ubuntu:	Build Orion Context Broker 0.22.0 using Ubuntu baseimage)
	$(info - mongodb-2.6:		Build MongoDB 2.6 image)
	$(info - mongodb-3.0:		Build MongoDB 3.0 image)
	$(info - mariadb-5.5:		Build MariaDB 5.5 image)
	$(info - mariadb-10.0:		Build MariaDB 10.0 image)
	$(info - idas-ul20:		Build IDAS UltraLight 2.0 IoTAgent image)
	$(info )
	@echo ""

.PHONY: idm-keyrock
idm-keyrock:
	docker build -t bitergia/idm-keyrock:$(IDM_VERSION) idm-keyrock/$(IDM_VERSION)/

.PHONY: authzforce
authzforce:
	docker build -t bitergia/authzforce:$(AUTHZFORCE_VERSION) authzforce/$(AUTHZFORCE_VERSION)/

.PHONY: pep-wilma
pep-wilma:
	docker build -t bitergia/pep-wilma:$(WILMA_VERSION) pep-wilma/$(WILMA_VERSION)/

.PHONY: cygnus
cygnus:
	docker build -t bitergia/cygnus:$(CYGNUS_VERSION) cygnus/$(CYGNUS_VERSION)/

.PHONY: orion-0.22.0 orion
orion-0.22.0:
	@$(MAKE) orion ORION_VERSION=0.22.0
orion:
	docker build -t bitergia/fiware-orion:$(ORION_VERSION) fiware-orion/$(ORION_VERSION)/

.PHONY: idmauthlegacy
idmauthlegacy:
	docker build -t bitergia/$@ $@/

.PHONY: mongodb-2.6 mongodb-3.0 mongodb
mongodb-2.6:
	@$(MAKE) mongodb MONGO_VERSION=2.6
mongodb-3.0:
	@$(MAKE) mongodb MONGO_VERSION=3.0
mongodb:
	docker build -t bitergia/mongodb:$(MONGO_VERSION) mongodb/$(MONGO_VERSION)/

.PHONY: mariadb-10.0 mariadb-5.5 mariadb
mariadb-10.0:
	@$(MAKE) mariadb MARIADB_VERSION=10.0
mariadb-5.5:
	@$(MAKE) mariadb MARIADB_VERSION=5.5
mariadb:
	docker build -t bitergia/mariadb:$(MARIADB_VERSION) mariadb/$(MARIADB_VERSION)/

.PHONY: orion.ubuntu orion-0.22.0.ubuntu
orion-0.22.0.ubuntu: 
	@$(MAKE) orion.ubuntu ORION_VERSION=0.22.0
orion.ubuntu:
	docker build -t bitergia/fiware-orion:$(ORION_VERSION) -f fiware-orion/$(ORION_VERSION)/Dockerfile.$@ fiware-orion/$(ORION_VERSION)/

.PHONY: idas idas-ul20 idas-iota-lwm2m idas-iota-cpp
idas: idas-iota-lwm2m idas-iota-cpp
idas-ul20:
	docker build -t bitergia/idas:ul20 idas/ul20/
idas-iota-lwm2m:
	docker build -t bitergia/idas-iota-lwm2m:$(IDAS_LWM2M_VERSION) idas/iota-lwm2m/$(IDAS_LWM2M_VERSION)/

idas-iota-cpp:
	docker build -t bitergia/idas-iota-cpp:$(IDAS_IOTACPP_VERSION) idas/iota-cpp/$(IDAS_IOTACPP_VERSION)/

.PHONY: all
all: idm-keyrock orion authzforce pep-wilma cygnus idmauthlegacy mongodb mariadb idas

.PHONY: clean clean_idm-keyrock
clean: clean_idm-keyrock

clean_idm-keyrock:
	-@docker rmi bitergia/idm-keyrock
