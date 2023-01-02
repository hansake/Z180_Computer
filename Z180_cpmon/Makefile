# Makefile to build test program
# for my DIY Z180 computer 
# eventually with a SD card disk
#
include gmsl

# Build configuration
#
PROTO = cxz180.proto
ARGS = -dprom -dsavlnk
EXECDIR = /opt/wsl/bin/
LIBDIR = /opt/wsl/lib/z80/

TESTRUNADR = 0xf000
LOADRUNADR = 0xb000

all: z180cpmon.bin /home/hal/Z180_computer/z180cpmon.bin

z180testbinc.o: z180testbinc.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180testbinc.c: z180test.bin
	$(EXECDIR)bintoc -v -n z180test -o $@ $^

z180test.bin: z180test.80
	$(EXECDIR)stripmhdr -o $@ $<

z180test.80: z180test.o
	$(EXECDIR)lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b$(TESTRUNADR) $<

z180test.o: z180test.s z180.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o Crtsrom.s

z180hwinit.o : z180hwinit.s z180.inc
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o $<

z180aio.o : z180aio.s z180.inc
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -dlistcs +o $<

z180cpmon.o: z180cpmon.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180uplbinc.o: z180uplbinc.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o $<

z180uplbinc.c: z180upload.bin
	$(EXECDIR)bintoc -v -n upload -o $@ $^

z180upload.bin: z180upload.80
	$(EXECDIR)stripmhdr -o $@ $<

z180upload.80: z180upload.o
	$(EXECDIR)lnk80 -o $@ +map=$(basename $@).map -t -rt -rd -cb +h \
	+text -b$(LOADRUNADR) $<

z180upload.o: z180upload.s z180.inc
	$(EXECDIR)x80 -o $@ +l > $(basename $<).ls $<

z180cpmon.80: z180hwinit.o z180aio.o z180cpmon.o z180uplbinc.o z180testbinc.o
	date +'const char builddate[] = "built %F %R";' > builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -I "|/opt/wsl/include/v30/" -dlistcs -dnostrict -s +o builddate.c
	$(EXECDIR)cx80 -proto $(PROTO) $(ARGS) -L$(LIBDIR) -o $@ -v -dmap $^ builddate.o

z180cpmon.bin: z180cpmon.80
	$(EXECDIR)hex80 -o $(basename $@).hex $<
	$(EXECDIR)unhex -o $@ $(basename $@).hex
	$(EXECDIR)sizinbin $@

/home/hal/Z180_computer/z180cpmon.bin: z180cpmon.bin
	@echo "Copy binary to directories for upload and EPROM burning."
	cp $< $@
	cp $< /home/hal/VirtualBox_shared/Z180/

clean:
	rm -f *.o *.80 *.map *.lnk *.ls *.err *.bin *.hex builddate.c builddate.o \
	z180testbinc.c z180uplbinc.c


