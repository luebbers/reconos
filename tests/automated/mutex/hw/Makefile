include $(shell find .. -name "*.rprj")

export EDK_BASE_DIR LAYOUT HW_THREAD_DIR PAROPTS MAPOPTS STATIC_THREADS DYNAMIC_THREADS ADDTHREAD_OPTS MAKETOP_OPTS ADDOSIF_OPTS

ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

error:
	$(error Please specify a make target (e.g. all or clean))

all: bits-static

.PHONY: error all

%:
	make -f $(RECONOS)/tools/makefiles/eapr/Makefile $@
