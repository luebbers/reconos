CC=powerpc-405-linux-gnu-gcc
CFLAGS= -Wall -O -I libreconos/include

HWDIR=opb_eth_cf
LINUXDIR=linux-2.6.27-rc9-xlnx

all: hw linux shared_tlb_demo

setup:
	ln -fs $(RECONOS)/core/linux/libreconos .

hw:
	make all -C $(HWDIR)

linux:
	cp $(HWDIR)/ppc405_0/libsrc/device-tree/xilinx.dts $(LINUXDIR)/arch/powerpc/boot/dts/virtex405-xup-opb-eth-tft-cf.dts
	make -C $(LINUXDIR) ARCH=powerpc CROSS_COMPILE=powerpc-405-linux-gnu- clean simpleImage.virtex405-xup-opb-eth-tft-cf

libreconos/lib/libreconos.a:
	make -C libreconos

shared_tlb_demo: shared_tlb_demo.o libreconos/lib/libreconos.a
	$(CC) -o shared_tlb_demo shared_tlb_demo.o -L libreconos/lib -l reconos -l rt

clean:
	rm -f *.o shared_tlb_demo

mrproper: clean
	make -C $(HWDIR) clean
	make -C $(LINUXDIR) clean
	rm -f libreconos

