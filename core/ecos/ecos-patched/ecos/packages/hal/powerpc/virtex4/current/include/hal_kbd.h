#ifndef HAL_KBD_H
#define HAL_KBD_H

//-----------------------------------------------------------------------------
// Keyboard definitions

#define	KBDATAPORT	0x40010000		// data I/O port
#define	KBCMDPORT	0x40010001		// command port (write)
#define	KBSTATPORT	0x40010001		// status port	(read)
#define KBINRDY         0x01
#define KBOUTRDY        0x02
#define KBTXTO          0x40                    // Transmit timeout - nothing there
#define KBTEST          0xAB

// Scan codes

#define	LSHIFT		0x2a
#define	RSHIFT		0x36
#define	CTRL		0x1d
#define	ALT		0x38
#define	CAPS		0x3a
#define	NUMS		0x45

#define	BREAK		0x80

// Bits for KBFlags

#define	KBNormal	0x0000
#define	KBShift		0x0001
#define	KBCtrl		0x0002
#define KBAlt		0x0004
#define	KBIndex		0x0007	// mask for the above

#define	KBExtend	0x0010
#define	KBAck		0x0020
#define	KBResend	0x0040
#define	KBShiftL	(0x0080 | KBShift)
#define	KBShiftR	(0x0100 | KBShift)
#define	KBCtrlL		(0x0200 | KBCtrl)
#define	KBCtrlR		(0x0400 | KBCtrl)
#define	KBAltL		(0x0800 | KBAlt)
#define	KBAltR		(0x1000 | KBAlt)
#define	KBCapsLock	0x2000
#define	KBNumLock	0x4000

#define KBArrowUp       0x48
#define KBArrowRight    0x4D
#define KBArrowLeft     0x4B
#define KBArrowDown     0x50

//-----------------------------------------------------------------------------
// Keyboard Variables

static	int	KBFlags = 0;
static	cyg_uint8 KBPending = 0xFF;
static	cyg_uint8 KBScanTable[128][4] = {
//	Normal		Shift		Control		Alt
// 0x00
    {	0xFF,		0xFF,		0xFF,		0xFF,   },
    {	0x1b,		0x1b,		0x1b,		0xFF,	},
    {	'1',		'!',		0xFF,		0xFF,	},
    {	'2',		'"',		0xFF,		0xFF,	},
    {	'3',		'#',		0xFF,		0xFF,	},
    {	'4',		'$',		0xFF,		0xFF,	},
    {	'5',		'%',		0xFF,		0xFF,	},
    {	'6',		'^',		0xFF,		0xFF,	},
    {	'7',		'&',		0xFF,		0xFF,	},
    {	'8',		'*',		0xFF,		0xFF,	},
    {	'9',		'(',		0xFF,		0xFF,	},
    {	'0',		')',		0xFF,		0xFF,	},
    {	'-',		'_',		0xFF,		0xFF,	},
    {	'=',		'+',		0xFF,		0xFF,	},
    {	'\b',		'\b',		0xFF,		0xFF,	},
    {	'\t',		'\t',		0xFF,		0xFF,	},
// 0x10
    {	'q',		'Q',		0x11,		0xFF,	},
    {	'w',		'W',		0x17,		0xFF,	},
    {	'e',		'E',		0x05,		0xFF,	},
    {	'r',		'R',		0x12,		0xFF,	},
    {	't',		'T',		0x14,		0xFF,	},
    {	'y',		'Y',		0x19,		0xFF,	},
    {	'u',		'U',		0x15,		0xFF,	},
    {	'i',		'I',		0x09,		0xFF,	},
    {	'o',		'O',		0x0F,		0xFF,	},
    {	'p',		'P',		0x10,		0xFF,	},
    {	'[',		'{',		0x1b,		0xFF,	},
    {	']',		'}',		0x1d,		0xFF,	},
    {	'\r',		'\r',		'\n',		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	'a',		'A',		0x01,		0xFF,	},
    {	's',		'S',		0x13,		0xFF,	},
// 0x20
    {	'd',		'D',		0x04,		0xFF,	},
    {	'f',		'F',		0x06,		0xFF,	},
    {	'g',		'G',		0x07,		0xFF,	},
    {	'h',		'H',		0x08,		0xFF,	},
    {	'j',		'J',		0x0a,		0xFF,	},
    {	'k',		'K',		0x0b,		0xFF,	},
    {	'l',		'L',		0x0c,		0xFF,	},
    {	';',		':',		0xFF,		0xFF,	},
    {	0x27,		'@',		0xFF,		0xFF,	},
    {	'#',		'~',		0xFF,		0xFF,	},
    {	'`',		'~',		0xFF,		0xFF,	},
    {	'\\',		'|',		0x1C,		0xFF,	},
    {	'z',		'Z',		0x1A,		0xFF,	},
    {	'x',		'X',		0x18,		0xFF,	},
    {	'c',		'C',		0x03,		0xFF,	},
    {	'v',		'V',		0x16,		0xFF,	},
// 0x30
    {	'b',		'B',		0x02,		0xFF,	},
    {	'n',		'N',		0x0E,		0xFF,	},
    {	'm',		'M',		0x0D,		0xFF,	},
    {	',',		'<',		0xFF,		0xFF,	},
    {	'.',		'>',		0xFF,		0xFF,	},
    {	'/',		'?',		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	' ',		' ',		' ',		' ',	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xF1,		0xE1,		0xFF,		0xFF,	},
    {	0xF2,		0xE2,		0xFF,		0xFF,	},
    {	0xF3,		0xE3,		0xFF,		0xFF,	},
    {	0xF4,		0xE4,		0xFF,		0xFF,	},
    {	0xF5,		0xE5,		0xFF,		0xFF,	},
// 0x40
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},

    {	0x15,		0x15,		0x15,		0x15,	},
    {	0x10,		0x10,		0x10,		0x10,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
// 0x50
    {	0x04,		0x04,		0x04,		0x04,	},
    {	0x0e,		0x0e,		0x0e,		0x0e,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
// 0x60
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
// 0x70
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
    {	0xFF,		0xFF,		0xFF,		0xFF,	},
};

static int KBIndexTab[8] = { 0, 1, 2, 2, 3, 3, 3, 3 };

#endif

