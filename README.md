This is an up-port of the original Xilinx emacps driver, last version from kernel 4.14.x commit e3dc7279 from  [Xilinx Linux kernel repo](https://github.com/Xilinx/linux-xlnx). The driver is reworked to be usable with the latest LTS kernel (currently 6.1, 6.6 and 6.12, 6.18-7.1, Mainline and Xilinx). The reason for this is it's support for hardware time-stamping (PTP), even if being broken to some degree. The internal design of the registers of the Zynq-7000 hardware is not sufficient to get proper PTP support, some of the stamps are just scrambled. If known, this can be dealt with in userspace and the scrambled stamps can be dropped. If properly done, this works good enough.

This driver can be build as external an external module, but I advice against this. It works best if integrated into the kernel and compiled as a builtin driver.

build as external Module (the repo provides a Makefile):
 - fully prepare a, means fully compile it (make prepare is not enough)
 - call `make` with `KDIR=<path to prepared kernel>`
 - switching is done via the build flag `-DCONFIG_XILINX_PS_EMAC_HWTSTAMP`, which is active by default
 - if cross-compiling is used, provide `ARCH=` and `CROSS_COMPILE=`

build as in-tree driver:
- copy the driver to `drivers/net/ethernet/xilinx/`
- update the Kconfig file in this directory with
```
config XILINX_PS_EMAC
       tristate "Xilinx Zynq tri-speed EMAC support"
       depends on ARCH_ZYNQ
       select PHYLIB
       help
         This driver supports tri-speed EMAC.

config XILINX_PS_EMAC_HWTSTAMP
       bool "Generate hardware packet timestamps (experimental)"
       depends on XILINX_PS_EMAC
       select PTP_1588_CLOCK
       default n
       help
         Generate hardare packet timestamps. This is to facilitate IEEE 1588.
```
 - add this line to the Makefile also in this directory
```obj-$(CONFIG_XILINX_PS_EMAC) += xilinx_emacps.o```
- use `make menuconfig` to configure the driver under
```
device drivers -> network device support -> ethernet driver support -> xilinx -> xilinx zynq tri-speed emac support
```

To use this now compiled driver you also need to update your device-tree, but this is very specific to your setup. A proper device-entry would look like this, though it is up to you to know your own system.
```
// in the amba section
  ...
	gem0: ethernet@e000b000 {
		compatible = "xlnx,zynq-gem", "cdns,gem";
		reg = <0xe000b000 0x1000>;
		status = "disabled";
		interrupts = <0 22 4>;
		clocks = <&clkc 30>, <clkc 30>, <&clkc 13>;
		clock-names = "pclk", "hclk", "tx_clk";
		xlnx,has-mdio = <1>;
		#address-cells = <1>;
		#size-cells = <0>;
	};
  ...
// global
&gem0 {
	status = "okay";
	phy-mode = "rgmii-id";
	phy-handle = <&ethernet_phy>;
	xlnx,ptp-enet-clock = <0x69f6bcb>; // 111 MHz
	mdio {
		#address-cells = <1>;
		#size-cells = <0>;
		ethernet_phy: ethernet-phy@0 {
			reg = <0>;
			device_type = "ethernet-phy";
		};
	};
};
```
