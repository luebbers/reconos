all:
	xps -nw -scr make_all.tcl

setup:
	mkdir -p pcores
	ln -sf $(RECONOS)/support/refdesigns/9.2/xup/opb_eth_tft_cf/drivers .
	ln -fs $(RECONOS)/support/refdesigns/9.2/xup/opb_eth_tft_cf/pcores/* pcores/.
	ln -fs $(RECONOS)/support/pcores/* pcores/.
	ln -fs $(RECONOS)/core/pcores/* pcores/.
	ln -fs $(RECONOS)/demos/shared_tlb_demo/hw_task_v1_01_b pcores/.

clean:
	xps -nw -scr make_clean.tcl
	rm -rf system.log _impactbatch.log blkdiagram etc platgen.opt *.make __xps ppc405_0

mrproper: clean
	rm -rf pcores
	rm -f drivers

