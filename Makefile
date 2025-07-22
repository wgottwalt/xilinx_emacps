ccflags-y = -DEXPORT_SYMTAB -DCONFIG_XILINX_PS_EMAC_HWTSTAMP -W -Wall -Wextra
obj-m := xilinx_emacps.o

KDIR ?= /lib/modules/$(shell uname -r)/build/
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

-include $(KDIR)/Rules.make
