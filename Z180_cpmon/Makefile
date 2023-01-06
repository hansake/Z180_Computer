# Makefile to build test program
# for my DIY Z180 computer 
# handling a SD card disk and
# eventually with CP/M
#
include gmsl

# Build configuration
#
PROTO = cxz180.proto
ARGS = -dprom -dsavlnk
EXECDIR = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/

# Load addresses for programs copied to high RAM
#
TESTRUNADR = 0xf000
LOADRUNADR = 0xb000

all: z180cpmon.bin /home/hal/Z180_computer/z180cpmon.bin

# Main monitor program
#
z180hwinit.o : Crtsrom.s z180hwinit.s z180.inc
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crtsrom.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o z180hwinit.s

z180aio.o : z180aio.s z180.inc
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o $<

z180sdasm.o : z180sdasm.s
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o $<

z180cpmon.o: z180cpmon.c z180sd.h cpmbiosadr.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180sddrv.o: z180sddrv.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180sdrdwr.o: z180sdrdwr.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180sddrvprt.o: z180sddrvprt.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180sdpart.o: z180sdpart.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180sdparprt.o: z180sdparprt.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

cpmbiosadr.h:
	echo "#define BIOSADR $(BIOSADR)" > cpmbiosadr.h
	echo "#define CCPADR $(CCPADR)" >> cpmbiosadr.h

z180cpmon.80: z180hwinit.o z180aio.o z180cpmon.o z180sdasm.o z180sddrv.o z180sdrdwr.o z180sddrvprt.o \
z180sdpart.o z180sdparprt.o z180uplbinc.o z180testbinc.o cpmsys.o
	date +'const char builddate[] = "built %F %R";' > builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^ builddate.o

z180cpmon.bin: z180cpmon.80
	$(EXECDIR)hex80 -o $(basename $@).hex $<
	$(EXECDIR)unhex -o $@ $(basename $@).hex
	$(EXECDIR)sizinbin $@

# Simple test program for RAM and CPU, copied to and running in high RAM
#
z180test.o: z180test.s z180.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<

z180test.80: z180test.o
	$(EXECDIR)lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b$(TESTRUNADR) $<

z180test.bin: z180test.80
	$(EXECDIR)stripmhdr -o $@ $<

z180testbinc.c: z180test.bin
	$(EXECDIR)bintoc -v -n z180test -o $@ $^

z180testbinc.o: z180testbinc.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

# Upload program, copied to and running in high RAM
#
z180upload.o: z180upload.s z180.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<

z180upload.80: z180upload.o
	$(EXECDIR)lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b$(LOADRUNADR) $<

z180upload.bin: z180upload.80
	$(EXECDIR)stripmhdr -o $@ $<

z180uplbinc.c: z180upload.bin
	$(EXECDIR)bintoc -v -n upload -o $@ $^

z180uplbinc.o: z180uplbinc.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

# The CP/M and BIOS code is built and linked with the monitor
#
SDCODE = z180sdio.o z180sdbiorw.o

# The link addresses for CCP and BDOS are calculated
# backwards from where the BIOS starts.
# The size of BIOS may be from end of BDOS
# to end of memory.
BIOSADR = 0xee00
# size of BDOS: 0xe00 (3584) bytes
BDOSADR = $(shell printf "0x%x" $(call subtract, \
              $(shell printf "%d" $(BIOSADR)), 3584))
# size of CPP: 0x800 (2048) bytes
CCPADR = $(shell printf "0x%x" $(call subtract, \
              $(shell printf "%d" $(BDOSADR)), 2048))

cpmsys.o: cpmsys.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

cpmsys.c: cpmsys.bin
	$(EXECDIR)bintoc -v -n cpmsys -o $@ $^

cpmsys.bin: cpmsys.80
	$(EXECDIR)stripmhdr -o $@ $<

cpmsys.80: ccp.o bdos.o z180bios.o $(SDCODE)
	$(EXECDIR)lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b$(CCPADR) +def ccp=__text__ ccp.o \
	+text -b$(BDOSADR) +def bdos=__text__ bdos.o \
	+text -b$(BIOSADR) +def bios=__text__ z180bios.o $(SDCODE) $(LIBDIR)/libi.z80 $(LIBDIR)/libm.z80

bdos.o: bdos.s cpm.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<

ccp.o: ccp.s cpm.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<

z180bios.o: z180bios.s cpm.inc z180.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<

z180sdio.o: z180sdio.s z180.inc
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o $<

z180sdbiorw.o: z180sdbiorw.c z180sd.h
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

# "Utility functions" in make
#
/home/hal/Z180_computer/z180cpmon.bin: z180cpmon.bin
	@echo "Copy binary to directories for upload and EPROM burning."
	cp $< $@
	cp $< /home/hal/VirtualBox_shared/Z180/

clean:
	rm -f *.o *.80 *.map *.lnk *.ls *.err *.bin *.hex builddate.c builddate.o \
	z180testbinc.c z180uplbinc.c

