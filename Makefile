#
# Makefile for the bare-metal-arm code.
#
#

# Check if the ARM compiler is on the PATH, else set a prefix for finding it.
ifneq ("$(shell which arm-none-eabi-gcc)", "")
  ARMPREFIX =
else
  ARMPREFIX = ./gcc-arm/bin/
endif

CC = $(ARMPREFIX)arm-none-eabi-gcc
AR = $(ARMPREFIX)arm-none-eabi-ar
OBJCOPY = $(ARMPREFIX)arm-none-eabi-objcopy
OBJDUMP = $(ARMPREFIX)arm-none-eabi-objdump

DEBUG_OPTS = -g3 -gdwarf-2 -gstrict-dwarf
OPTS = -Os
TARGET = -mcpu=cortex-m0plus
CFLAGS = -ffunction-sections -fdata-sections -Wall -Wa,-adhlns="$@.lst" \
		 -fmessage-length=0 $(TARGET) -mthumb -mfloat-abi=soft \
		 $(DEBUG_OPTS) $(OPTS) -I .

LIBOBJS = _startup.o syscalls.o uart.o delay.o accel.o touch.o usb.o \
		ring.o tests.o

INCLUDES = freedom.h common.h

.PHONY:	clean gcc-arm

# -------------------------------------------------------------------------------

all:	demo.srec demo.asm

libbare.a: $(LIBOBJS)
	$(AR) -rv libbare.a $(LIBOBJS)
	
clean:
	rm -f *.o *.lst *.elf libbare.a *.srec *.asm

%.o:	%.c
	$(CC) $(CFLAGS) -c $<
	
%.asm:	%.elf
	$(OBJDUMP) --disassemble $< >$@
	
%.srec:	%.elf
	$(OBJCOPY) -O srec $< $@
	
%.elf:	%.o mkl25z4.ld libbare.a
	$(CC) $(CFLAGS) -T mkl25z4.ld -o $@ $< libbare.a
	
# -------------------------------------------------------------------------------

# Download and unpack the GCC ARM embedded toolchain (binaries)
gcc-arm:
	curl --location https://launchpad.net/gcc-arm-embedded/4.8/4.8-2013-q4-major/+download/gcc-arm-none-eabi-4_8-2013q4-20131204-linux.tar.bz2 | tar jx
	ln -s gcc-arm-none-eabi-4_8-2013q4 gcc-arm
