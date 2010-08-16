ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

export Q QQ NUM_OSIFS

error:
	$(error Please specify a make target (e.g. all or clean))

%:
	$(Q)make -f $(RECONOS)/tools/makefiles/eapr/Makefile.hwthreads $@

