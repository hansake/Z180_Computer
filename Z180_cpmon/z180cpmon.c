/*  z180cpmon.c
 *  Boot, test and upload functions.
 *  Eventually also SD card test program and CP/M.
 *
 *  Code for my DIY Z180 Computer. This program
 *  is compiled with Whitesmiths/COSMIC
 *  C compiler for Z80/Z180.
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties are given.
 *  Hastily Cobbled Together 2021 and 2022
 *  by Hans-Ake Lund
 */

#include <std.h>

/* Program name and version */
#define PRGNAME "z180cpmon "
#define VERSION "version 2.3, "

#define LOADADR 0xb000     /* Address in high RAM where to copy and execute uploader code */
#define TESTADR 0xf000     /* Address in high RAM where to copy and execute test code */

/* External data */
extern const char upload[];     /* Upload program binary and size */
extern const int upload_size;
extern const char z180test[];   /* Test program binary and size */
extern const int z180test_size;
extern const int binstart;      /* Uploaded program header */
extern const int binsize;
extern const char builddate[]; /* Build date and time */

/* RAM/EPROM probe */
const int ramprobe = 0;
int *rampptr;

/* Executing in RAM or EPROM
 */
void execin()
    {
    printf("\nProgram is executed in: ");
    rampptr = &ramprobe;
    *rampptr = 1; /* try to change const */
    if (ramprobe)
        printf("RAM\n");
    else
        printf("EPROM\n");
    *rampptr = 0;
    }

/* Get line from keyboard
 * edit line with BS
 * returns when CR or Ctrl-C is entered
 * return value is length of entered string
 */
int getkline(char *txtinp, int bufsize)
    {
    int ncharin;
    char charin;

    for (ncharin = 0; ncharin < (bufsize - 1); ncharin++)
        {
        charin = getchar();
        if (charin == '\r') /* CR */
            {
            *txtinp = 0;
            return (ncharin);
            }
        else if (charin == 3) /* Ctrl-C */
            return (0);
        else if (charin == '\b') /* BS */
            {
            if (0 < ncharin)
                {
                putchar('\b');
                putchar(' ');
                putchar('\b');
                ncharin--;
                txtinp--;
                }
            }
        else
            {
            putchar(charin);
            *txtinp++ = charin;
            }
        }
    *txtinp = 0;
    return (ncharin);
    }

/* Print data in hex and ASCII */
void datprt(unsigned char *prtbuf, unsigned int prtbase, int dumprows)
    {
    /* Variables used for "pretty-print" */
    int allzero, dmpline, dotprted, lastallz, nbytes;
    unsigned char *prtptr;

    prtptr = prtbuf;
    dotprted = NO;
    lastallz = NO;
    for (dmpline = 0; dmpline < dumprows; dmpline++)
        {
        /* test if all 16 bytes are 0x00 */
        allzero = YES;
        for (nbytes = 0; nbytes < 16; nbytes++)
            {
            if (prtptr[nbytes] != 0)
                allzero = NO;
            }
        if (lastallz && allzero && (dmpline != (dumprows -1)))
            {
            if (!dotprted)
                {
                printf("*\n");
                dotprted = YES;
                }
            }
        else
            {
            dotprted = NO;
            /* print offset */
            printf("%04x ", (dmpline * 16) + prtbase);
            /* print 16 bytes in hex */
            for (nbytes = 0; nbytes < 16; nbytes++)
                printf("%02x ", prtptr[nbytes]);
            /* print these bytes in ASCII if printable */
            printf(" |");
            for (nbytes = 0; nbytes < 16; nbytes++)
                {
                if ((' ' <= prtptr[nbytes]) && (prtptr[nbytes] < 127))
                    putchar(prtptr[nbytes]);
                else
                    putchar('.');
                }
            printf("|\n");
            }
        prtptr += 16;
        lastallz = allzero;
        }
    }

/* Monitor main menu
 */
int main()
    {
    char txtin[16];
    int cmdin;
    int dumprows = 16;
    unsigned int dumpadr = 0x0000;
    unsigned int csidat = 0x00;
    unsigned int csodat = 0x5a;
    unsigned int exeadr = 0x0000;
    unsigned int spiidat = 0x00;
    unsigned int spiodat = 0x5a;
    unsigned int upladr = 0x0000;

    printf(PRGNAME);
    printf(VERSION);
    printf(builddate);
    execin();
    printf("Header - binstart: 0x%04x, binsize: 0x%04x (%d)\n", binstart, binsize, binsize);
    while (YES) /* forever (until Ctrl-C) */
        {
        printf("cmd (? for help): ");

        cmdin = getchar();
        switch (cmdin)
            {
            case '?':
                printf(" ? - help\n");
                printf(PRGNAME);
                printf(VERSION);
                printf(builddate);
                execin();
                printf("Commands:\n");
                printf("  ? - help\n");
                printf("  a - set address for upload\n");
                printf("  d - dump memory content to screen\n");
                printf("  e - set address for execute\n");
                printf("  i - CSIO input\n");
                printf("  o - CSIO output\n");
                printf("  g - SPI input\n");
                printf("  s - SPI output\n");
                printf("  t - run test program\n");
                printf("  u - upload code with Xmodem to 0x%04x\n      and execute at: 0x%04x\n",
                       upladr, exeadr);
                printf("  Ctrl-C to reload monitor from EPROM\n");
                break;
            case 'a':
                printf(" a - upload address:  0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &upladr);
                    exeadr = upladr;
                    }
                else
                    {
                    printf("%04x", upladr);
                    }
                printf("\n");
                break;
            case 'd':
                printf(" d - dump memory content starting at: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &dumpadr);
                    }
                else
                    {
                    printf("%04x", dumpadr);
                    }
                printf(" rows: ");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%d", &dumprows);
                    }
                else
                    {
                    printf("%d", dumprows);
                    }
                printf("\n");
                datprt(dumpadr, dumpadr, dumprows);
                break;
            case 'e':
                printf(" e - execute address: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &exeadr);
                    }
                else
                    {
                    printf("%04x", exeadr);
                    }
                printf("\n");
                break;
            case 'i':
                setcso(1);
                csidat = getcsio();
                setcso(0);
                printf(" i - CSIO input: 0x%02x\n", csidat);
                break;
            case 'o':
                printf(" o - CSIO output: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &csodat);
                    }
                else
                    {
                    printf("%02x", csodat);
                    }
                printf("\n");
                setcso(1);
                putcsio(csodat);
                setcso(0);
                break;
            case 'g':
                setcso(1);
                spiidat = getspi();
                setcso(0);
                printf(" g - SPI input: 0x%02x\n", spiidat);
                break;
            case 's':
                printf(" s - SPI output: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &spiodat);
                    }
                else
                    {
                    printf("%02x", spiodat);
                    }
                printf("\n");
                setcso(1);
                putspi(spiodat);
                setcso(0);
                break;
            case 't':
                printf(" t - run test program\n");
                printf("(Test code at: 0x%04x, size: %d)\n", TESTADR, z180test_size);
                memcpy(TESTADR, z180test, z180test_size);
                jumpto(TESTADR, 0, 0);
                break;
            case 'u':
                printf(" %c - upload to 0x%04x and execute at: 0x%04x\n",
                    cmdin, upladr, exeadr);
                printf("(Uploader code at: 0x%04x, size: %d)\n", LOADADR, upload_size);
                memcpy(LOADADR, upload, upload_size);
                jumpto(LOADADR, upladr, exeadr);
                break;
            case 0x03: /* Ctrl-C */
                printf("reloading monitor from EPROM\n");
                reload();
                break; /* not really needed, will never get here */
            default:
                printf(" invalid command\n");
            }
        }

    }

