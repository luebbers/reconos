include ../pr_msg_demo.rprj

export EDK_BASE_DIR LAYOUT HW_THREAD_DIR PAROPTS MAPOPTS STATIC_THREADS DYNAMIC_THREADS ADDTHREAD_OPTS MAKETOP_OPTS ADDOSIF_OPTS

ifeq ($(RECONOS),)
    $(error ReconOS environment variable $$RECONOS not defined)
endif

error:
	$(error Please specify a make target (e.g. all or clean))

planahead_prepare:
	rm -rf edk-static/implementation/hw_task_.*

%:
	make -f $(RECONOS)/tools/makefiles/eapr/Makefile $@
