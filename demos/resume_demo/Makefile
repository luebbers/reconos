
all: hw sw

.PHONY: hw sw clean hwclean swclean

hw:
	make -C hw all

sw:
	make -C sw setup
	make -C sw all

clean:
	@echo "Please specify either 'hwclean' or 'swclean'"

hwclean:
	make -C hw clean

swclean:
	make -C sw clean


