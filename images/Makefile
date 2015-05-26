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
	$(info )
	@echo ""

.PHONY: idm
idm: $@
	docker build -t bitergia/$@ $@/

.PHONY: all
all: idm

.PHONY: clean clean_idm
clean: clean_idm

clean_idm:
	-@docker rmi bitergia/idm
