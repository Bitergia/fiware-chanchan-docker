MONGO_VERSION = 2.6

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
	$(info - orion: 		Build Orion Context Broker image)
	$(info - mongodb: 		Build MongoDB $(MONGO_VERSION) image)
	$(info - wilma-pep:		Build Wilma PEP Proxy image)
	$(info - cygnus:		Build Cygnus image)
	$(info - authzforce:		Build Authzforce image (based on the GE version))
	$(info - chanchanapp:		Build ChanChan App (angular client and flask server))
	$(info - idmauthlegacy:	Build IdM legacy (ruby), Orion PEP and Keypass image)
	$(info )
	$(info Other available options:)
	$(info - mongodb-2.6: 		Build MongoDB 2.6 image)
	$(info - mongodb-3.0: 		Build MongoDB 3.0 image)
	$(info )
	@echo ""

.PHONY: idm orion authzforce wilma-pep cygnus chanchanapp idmauthlegacy
idm orion authzforce wilma-pep cygnus chanchanapp idmauthlegacy: $@
	docker build -t bitergia/$@ $@/

.PHONY: mongodb-2.6 mongodb-3.0 mongodb
mongodb-2.6:
	@$(MAKE) mongodb MONGO_VERSION=2.6
mongodb-3.0:
	@$(MAKE) mongodb MONGO_VERSION=3.0
mongodb:
	docker build -t bitergia/mongodb-org:$(MONGO_VERSION) mongodb/$(MONGO_VERSION)/

.PHONY: all
all: idm orion authzforce wilma-pep cygnus chanchanapp idmauthlegacy mongodb

.PHONY: clean clean_idm
clean: clean_idm

clean_idm:
	-@docker rmi bitergia/idm
