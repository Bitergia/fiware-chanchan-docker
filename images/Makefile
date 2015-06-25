MONGO_VERSION = 2.6
ORION_VERSION = 0.22.0
MARIADB_VERSION = 10.0
CYGNUS_VERSION = 0.5.1

.PHONY: help
help:
	$(info )
	$(info This makefile will help you build docker images for the Fiware-ChanChan)
	$(info components based on the bitergia baseimages.)
	$(info )
	$(info Available options:)
	$(info )
	$(info - all:			Build all available images)
	$(info - idm:			Build Keyrock IdM image (based on the new Keyrock version))
	$(info - orion: 		Build Orion Context Broker $(ORION_VERSION) image)
	$(info - mongodb: 		Build MongoDB $(MONGO_VERSION) image)
	$(info - idas:			Build IDAS images)
	$(info - wilma-pep:		Build Wilma PEP Proxy image)
	$(info - cygnus:		Build Cygnus image)
	$(info - authzforce:		Build Authzforce image (based on the GE version))
	$(info - chanchanapp:		Build ChanChan App (angular client and flask server))
	$(info - idmauthlegacy:	Build IdM legacy (ruby), Orion PEP and Keypass image)
	$(info - idas-ul20:		Build IDAS UltraLight 2.0 IoTAgent image)
	$(info - mariadb: 		Build MariaDB $(MARIADB_VERSION) image)
	$(info )
	$(info Other available options:)
	$(info - orion-ubuntu:		Build Orion Context Broker image using Ubuntu baseimage)
	$(info - mongodb-2.6: 		Build MongoDB 2.6 image)
	$(info - mongodb-3.0: 		Build MongoDB 3.0 image)
	$(info - mariadb-5.5: 		Build MariaDB 5.5 image)
	$(info - mariadb-10.0:		Build MariaDB 10.0 image)
	$(info )
	@echo ""

.PHONY: idm authzforce wilma-pep cygnus chanchanapp idmauthlegacy
idm authzforce wilma-pep cygnus chanchanapp idmauthlegacy: $@
	docker build -t bitergia/$@ $@/
	-[ "$@" = "cygnus" ] && docker tag -f bitergia/$@ bitergia/$@:$(CYGNUS_VERSION) || true

.PHONY: mongodb-2.6 mongodb-3.0 mongodb
mongodb-2.6:
	@$(MAKE) mongodb MONGO_VERSION=2.6
mongodb-3.0:
	@$(MAKE) mongodb MONGO_VERSION=3.0
mongodb:
	docker build -t bitergia/mongodb-org:$(MONGO_VERSION) mongodb/$(MONGO_VERSION)/

.PHONY: mariadb-10.0 mariadb-5.5 mariadb
mariadb-10.0:
	@$(MAKE) mariadb MARIADB_VERSION=10.0
mariadb-5.5:
	@$(MAKE) mariadb MARIADB_VERSION=5.5
mariadb:
	docker build -t bitergia/mariadb:$(MARIADB_VERSION) mariadb/$(MARIADB_VERSION)/

.PHONY: orion orion.ubuntu orion.centos6 orion-ubuntu
orion-ubuntu: orion.ubuntu
orion: orion.centos6
orion.centos6 orion.ubuntu:
	docker build -t bitergia/orion:$(ORION_VERSION) -f orion/Dockerfile.$@ orion/

.PHONY: idas idas-ul
idas: idas-ul20
idas-ul20:
	docker build -t bitergia/idas:ul20 idas/ul20/

.PHONY: all
all: idm orion authzforce wilma-pep cygnus chanchanapp idmauthlegacy mongodb mariadb

.PHONY: clean clean_idm
clean: clean_idm

clean_idm:
	-@docker rmi bitergia/idm
