CC = powerpc-405-linux-gnu-gcc
APP = sort_demo_posix

# Add any other object files to this list below
APP_OBJS = sort_posix_mt_hw.o bubblesort.o data.o merge.o sort8k.o timing.o $(RECONOS)/core/linux/libreconos/src/hw_thread.o
LDLIBS = -lpthread -lrt -lm
CFLAGS += -I$(RECONOS)/core/linux/libreconos/include

all: $(APP)

$(APP): $(APP_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	-rm -f $(APP) *.elf *.gdb *.o $(APP_OBJS)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

	
