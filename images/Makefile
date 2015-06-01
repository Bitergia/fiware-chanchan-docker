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
	$(info - cygnus:		Build Cygnus image)
	$(info - authzforce:		Build Authzforce image (based on the GE version))
	$(info )
	@echo ""

.PHONY: idm orion authzforce
idm orion authzforce: $@
	docker build -t bitergia/$@ $@/

.PHONY: cygnus
cygnus: $@
	docker build -t bitergia/$@ $@/

.PHONY: all
all: idm orion authzforce

.PHONY: clean clean_idm
clean: clean_idm

clean_idm:
	-@docker rmi bitergia/idm
