CFLAGS = -O3 -I../include

CROSS_COMPILE = powerpc-405-linux-gnu-

CC = $(CROSS_COMPILE)gcc
AR = $(CROSS_COMPILE)ar

TARGET = libreconos.a
OBJS = hw_thread.o tlb.o

default: $(TARGET)

$(TARGET): $(OBJS)
	$(AR) rcs $@ $(OBJS)

clean:
	rm -f $(TARGET) *.o

.PHONY: clean

