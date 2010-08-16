include ../resume_demo.rprj

export EDK_BASE_DIR LAYOUT HW_THREAD_DIR PAROPTS MAPOPTS STATIC_THREADS ADDTHREAD_OPTS MAKETOP_OPTS

ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

error:
	$(error Please specify a make target (e.g. all or clean))

%:
	make -f $(RECONOS)/tools/makefiles/eapr/Makefile $@
