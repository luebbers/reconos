SUFFIX=ngc
WRAPPER=implementation/hw_task_0_wrapper.ngc

THREADS=$(shell find . -type d -not -name ".")
THREAD_NETLISTS=$(foreach t,$(THREADS), $(t).$(SUFFIX))
WRAPPERS=$(foreach t,$(THREADS), $(t)/$(WRAPPER))

all: $(THREAD_NETLISTS)

#$(THREAD_NETLISTS) : THREAD=$(shell echo $@ | sed "s/\.ngc//")
$(THREAD_NETLISTS) : %.ngc: %/$(WRAPPER)
	cp $< $@

$(WRAPPERS) : 
$(WRAPPERS) : %/$(WRAPPER): %
	NUM_DYNAMIC_OSIFS=1 make -C $<

	
clean:
	rm -f $(THREAD_NETLISTS)
	for t in $(THREADS); do \
		NUM_DYNAMIC_OSIFS=1 make -C $$t clean; \
	done
	
.PHONY: clean all