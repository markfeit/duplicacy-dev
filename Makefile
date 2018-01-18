#
# Makefile for building Duplicacy
#

# Configure the following to taste.

NAME=duplicacy

# Location of original code, sans protocol
DUPLICACY_GCHEN=github.com/gilbertchen/$(NAME)

# Forked respository
REPO=git@github.com:markfeit/duplicacy.git


# No user-serviceable parts below this point.

GO_DIR=gopath
GO_BIN=$(GO_DIR)/bin
GOPATH:=$(shell mkdir -p $(GO_DIR) && cd $(GO_DIR) && pwd -P)
GO:=GOPATH=$(GOPATH) go

DUPLICACY_CLONE=$(GO_DIR)/src/$(DUPLICACY_GCHEN)

WORK=work

BIN_LINK=$(NAME)
BIN_LINK_TO=$(GO_BIN)/$(NAME)


default: build


#
# Application/removal of a patch to undo something in the source's
# peculiar to Gilbert Chen's environment.  See
# https://github.com/gilbertchen/duplicacy/issues/321.
#

PATCHFILE=$(WORK)/src/duplicacy_azurestorage.go
PATCH_ORIG=github.com/gilbertchen/azure-sdk-for-go/storage
PATCH_FIXED=github.com/azure/azure-sdk-for-go/storage

patch::
	[ -e "$(PATCHFILE)" ] \
	    && sed -i -e 's|$(PATCH_ORIG)|$(PATCH_FIXED)|g' $(PATCHFILE) \
	    || true

unpatch::
	[ -e "$(PATCHFILE)" ] \
	    && sed -i -e 's|$(PATCH_FIXED)|$(PATCH_ORIG)|g' $(PATCHFILE) \
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
	$(MAKE) patch
	$(GO) get -u "$(DUPLICACY_GCHEN)/..."
	$(MAKE) unpatch
	touch $@
TO_CLEAN += $(WORK) $(NAME)

clone: $(BUILT)



build: clone patch
	rm -f $(BIN_LINK)
	cd $(DUPLICACY_CLONE) \
	    && $(GO) build duplicacy/duplicacy_main.go
	$(MAKE) unpatch
	ln -s "$(BIN_LINK_TO)" "$(BIN_LINK)"
TO_CLEAN += $(BIN_LINK)


# TODO: It would be nice to have a commit target that unpatches,
# commits/pushes all sources and re-adds the patch.

#
# Housecleaning
#

# Note that this will fail if there are uncommitted changes other than
# the patch.
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
