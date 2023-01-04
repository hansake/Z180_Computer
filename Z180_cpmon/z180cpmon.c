/*  z180cpmon.c
 *
 *  Main program for boot, test and upload functions.
 *  Eventually also SD card test program and CP/M.
 *
 *  Part of the boot code for my DIY Z180 Computer.
 *  This program is compiled with Whitesmiths/COSMIC
 *  C compiler for Z80/Z180.
 *
 *  You are free to use, modify, and redistribute
 *  this source code. No warranties are given.
 *  Hastily Cobbled Together 2021, 2022 and 2023
 *  by Hans-Ake Lund
 */

#include <std.h>
#include "z180sd.h"

/* Program name and version */
#define PRGNAME "z180cpmon "
#define VERSION "version 2.6, "

/* External data */
extern const char upload[];     /* Upload program binary and size */
extern const int upload_size;
extern const char z180test[];   /* Test program binary and size */
extern const int z180test_size;
extern const int binstart;      /* Uploaded program header */
extern const int binsize;
extern const char builddate[];  /* Build date and time */

/* RAM/EPROM probe */
const int ramprobe = 0;
int *rampptr;

/* Test and print if executing in RAM or EPROM
 */
void execin()
    {
    printf("\nProgram is executing in: ");
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
 * return value is the length of the entered string
 */
int getkline(char *txtinp, int bufsize)
    {
    char charin;
    int ncharin;

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

/* Monitor main menu
 */
int main()
    {
    char txtin[16];
    int cmdin;
    int dumprows = 16;
    unsigned int dumpadr = 0x0000;
    unsigned int exeadr = 0x0000;
    unsigned int upladr = 0x0000;
    unsigned char blockno[4];
    unsigned long inblockno;

    memset(blockno, 0, 4);
    memset(curblkno, 0, 4);
    curblkok = NO;               /* No valid currently read SD block */
    sdinitok = (void *) INITFLG; 
    *sdinitok = 0;               /* SD card not initialized yet */
    spideselect();
    printf("=============================================\n");
    printf(PRGNAME);
    printf(VERSION);
    printf(builddate);
    execin();
    printf("Hdr: binstart: 0x%04x, binsize: 0x%04x (%d)\n", binstart, binsize, binsize);
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
                printf("  i - initialize SD card\n");
                printf("  l - print SD card partition layout\n");
                printf("  n - set/show block #N to read/write\n");
                printf("  p - print block last read/to write\n");
                printf("  q - test probe SD card\n");
                printf("  r - read block #N\n");
                printf("  s - print SD registers\n");
                printf("  t - run test program\n");
                printf("  u - upload code with Xmodem to 0x%04x\n      and execute at: 0x%04x\n",
                       upladr, exeadr);
                printf("  w - write block #N\n");
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
                sddatprt(dumpadr, dumpadr, dumprows);
                break;
            case 'e':
                printf(" e - execute address: 0x");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%x", &exeadr);
                    }
                else
                    {
                    printf("%04x", exeadr);                printf("  i - initialize SD card\n");
                    }
                printf("\n");
                break;
            case 'i':
                printf(" i - initialize SD card");
                if (sdinit())
                    printf(" - ok\n");
                else
                    printf(" - not inserted or faulty\n");
                break;
            case 'l':
                printf(" l - print partition layout\n");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                sdpartfind();
                sdpartprint();
                break;
            case 'n':
                printf(" n - block number: ");
                if (getkline(txtin, sizeof txtin))
                    {
                    sscanf(txtin, "%lu", &inblockno);
                    ul2blk(blockno, inblockno);
                    }
                else
                    printf("%lu", blk2ul(blockno));
                printf("\n");
                break;
            case 'p':
                printf(" p - print data block %lu\n", blk2ul(curblkno));
                sddatprt(sdrdbuf, 0x0000, 32);
                break;
            case 'q':
                printf(" q - test if card inserted\n");
                if (sdprobe())
                    printf(" - ok\n");
                else
                    printf(" - not initialized or inserted or faulty\n");
                break;
            case 'r':
                printf(" r - read block");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                if (sdread(sdrdbuf, blockno))
                    {
                    printf(" - ok\n");
                    memcpy(curblkno, blockno, 4);
                    }
                else
                    printf(" - read error\n");
                break;
            case 's':
                printf(" s - print SD registers\n");
                sdprtreg();
                break;
            case 't':
                printf(" t - run test program\n");
                printf("(Test code at: 0x%04x, size: %d)\n", TESTADR, z180test_size);
                memcpy(TESTADR, z180test, z180test_size);
                jumpto(TESTADR, 0, 0);
                break; /* not really needed, will never get here */
            case 'u':
                printf(" %c - upload to 0x%04x and execute at: 0x%04x\n",
                    cmdin, upladr, exeadr);
                printf("(Uploader code at: 0x%04x, size: %d)\n", LOADADR, upload_size);
                memcpy(LOADADR, upload, upload_size);
                jumpto(LOADADR, upladr, exeadr);
                break; /* not really needed, will never get here */
            case 'w':
                printf(" w - write block");
                if (!sdprobe())
                    {
                    printf(" - not initialized or inserted or faulty\n");
                    break;
                    }
                if (sdwrite(sdrdbuf, blockno))
                    {
                    printf(" - ok\n");
                    memcpy(curblkno, blockno, 4);
                    }
                else
                    printf(" - write error\n");
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

