all: system.xmp system.mhs
	ln -sf $(RECONOS)/core/pcores/* pcores/.
	ln -sf $(RECONOS)/support/refdesigns/9.1/xup/eth_tft_cf/pcores/* pcores/.
	xps -nw -scr make_all.tcl

clean:
	rm -rf system_incl.make etc hdl implementation libgen.log platgen.log platgen.opt ppc405_0 ppc405_1 synthesis system.log system.make __xps blkdiagram _impactbatch.log
	rm -f pcores/* || /bin/true

.PHONY: all clean

