#
# Makefile for building Duplicacy
#

# Configure the following to taste.

NAME=duplicacy

# Tag to be added to version number (e.g., 1.2.3-foo).  This must not
# contain hyphens or quotes.
# VERSION_TAG=wasabi20180227

# Location of original code, sans protocol
DUPLICACY_GCHEN=github.com/gilbertchen/$(NAME)

# Forked respository
#REPO=git@github.com:gilbertchen/$(NAME).git
REPO=git@github.com:markfeit/$(NAME).git
# Set this to check out a branch
REPO_BRANCH=swift-v2

ALT_GO := ./go


# No user-serviceable parts below this point.

GO_DIR=./gopath
GO_BIN=$(shell readlink -f '$(GO_DIR)/bin')
GOPATH:=$(shell mkdir -p $(GO_DIR) && cd $(GO_DIR) && pwd -P)


ifdef ALT_GO
  RUN_GO += $(shell readlink -f '$(ALT_GO)')/bin/go
else
  RUN_GO += go
endif
GO := GOPATH=$(GOPATH) GO111MODULE=off $(RUN_GO)

DUPLICACY_CLONE=$(GO_DIR)/src/$(DUPLICACY_GCHEN)

WORK=work

BIN_LINK=$(NAME)
BIN_LINK_TO=$(DUPLICACY_CLONE)/$(NAME)_main


default: build


#
# Application/removal of patches:
#
# - Add $(VERSION_TAG) to version number
#
# - Undo something in the sources peculiar to Gilbert Chen's
#   environment.  See details at
#   https://github.com/gilbertchen/duplicacy/issues/321.
#

PATCHFILE=$(WORK)/src/duplicacy_azurestorage.go
PATCH_ORIG=github.com/gilbertchen/azure-sdk-for-go/storage
PATCH_FIXED=github.com/azure/azure-sdk-for-go/storage

VERSIONFILE=$(WORK)/duplicacy/duplicacy_main.go


unpatch::
ifneq ($(VERSION_TAG),)
	[ -e "$(VERSIONFILE)" ] \
	    && sed -i -e 's/\(app\.Version[^"]*".*[^-]*\)-[^"]\+/\1/g' \
	        $(VERSIONFILE) \
	    || true
endif
	[ -e "$(PATCHFILE)" ] \
	    && sed -i -e 's|$(PATCH_FIXED)|$(PATCH_ORIG)|g' $(PATCHFILE) \
	    || true


patch: unpatch
ifneq ($(VERSION_TAG),)
	[ -e "$(VERSIONFILE)" ] \
	    && sed -i -e 's/\(app\.Version[^"]*"[^"]*\)/\1-$(VERSION_TAG)/g' \
	        $(VERSIONFILE) \
	    || true
endif
	[ -e "$(PATCHFILE)" ] \
	    && sed -i -e 's|$(PATCH_ORIG)|$(PATCH_FIXED)|g' $(PATCHFILE) \
	    || true


#
# Clone and Build
#

BUILT=$(GO_DIR)/.built
$(BUILT):
	[ -d "$(DUPLICACY_CLONE)" ] \
	    || git clone "$(REPO)" "$(DUPLICACY_CLONE)"
	rm -f "$(WORK)"
	ln -s "$(DUPLICACY_CLONE)" "$(WORK)"
ifdef REPO_BRANCH
	git -C "$(WORK)" checkout "$(REPO_BRANCH)"
endif
	$(MAKE) patch
	$(GO) get -v -u "$(DUPLICACY_GCHEN)/..."
	$(MAKE) unpatch
	touch $@
TO_CLEAN += $(WORK) $(NAME)

clone: $(BUILT)



build: clone patch
	rm -f $(BIN_LINK) $(GO_DIR)/bin/$(NAME)
	cd $(DUPLICACY_CLONE) \
	    && $(GO) clean \
	    && $(GO) build duplicacy/duplicacy_main.go
	$(MAKE) unpatch
	ln -s "$(BIN_LINK_TO)" "$(BIN_LINK)"
TO_CLEAN += $(BIN_LINK)


#
# Testing
#

TEST_STORAGE=wasabi
TEST_STORAGE_CONF=$(DUPLICACY_CLONE)/src/test_storage.conf

$(TEST_STORAGE_CONF):
	@echo "No storage configuration in $@"
	@false
TO_CLEAN += $(TEST_STORAGE_CONF)

test-storage: $(TEST_STORAGE_CONF)
	cd $(DUPLICACY_CLONE) \
	&& $(GO) test -run TestStorage ./src -storage $(TEST_STORAGE)
TESTS += storage

test-backupmanager: $(TEST_STORAGE_CONF)
	cd $(DUPLICACY_CLONE) \
	&& $(GO) test -run TestBackupManager ./src -storage $(TEST_STORAGE)
TESTS += backupmanager


test: build
	$(MAKE) patch
	$(MAKE) $(TESTS:%=test-%)
	$(MAKE) unpatch



#
# Housecleaning
#

# Note that this will fail if there are uncommitted changes.
clean: unpatch
	@if [ -d "$(DUPLICACY_CLONE)" ] ; \
	then \
	    if [ $$(git -C "$(DUPLICACY_CLONE)" ls-files -m | wc -l) -ne 0 ] ; \
	    then \
	        echo ; \
	        echo "NOTE: Not cleaning work directory containing changes" ; \
	        echo ; \
	        false ; \
	    fi ; \
	fi
	rm -rf $(GO_DIR) $(TO_CLEAN)
	find . -name "*~" -print0 | xargs -0 rm -rf


# Do a forced cleaning, even if there are changes.
clean-force:
	rm -rf $(DUPLICACY_CLONE)
	$(MAKE) clean
