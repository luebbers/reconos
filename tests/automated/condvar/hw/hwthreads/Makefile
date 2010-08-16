ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

export Q QQ NUM_DYNAMIC_OSIFS DYNAMIC_THREADS

error:
	$(error Please specify a make target (e.g. all or clean))

%:
	$(Q)make -f $(RECONOS)/tools/makefiles/eapr/Makefile.hwthreads $@

