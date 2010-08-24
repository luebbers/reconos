

/* timer support */
/* this map can be used for opb_timer and xps_timer */

#define TIMER_ENABLE_ALL    0x400 /* ENALL */
#define TIMER_PWM           0x200 /* PWMA0 */
#define TIMER_INTERRUPT     0x100 /* T0INT */
#define TIMER_ENABLE        0x080 /* ENT0 */
#define TIMER_ENABLE_INTR   0x040 /* ENIT0 */
#define TIMER_RESET         0x020 /* LOAD0 */
#define TIMER_RELOAD        0x010 /* ARHT0 */
#define TIMER_EXT_CAPTURE   0x008 /* CAPT0 */
#define TIMER_EXT_COMPARE   0x004 /* GENT0 */
#define TIMER_DOWN_COUNT    0x002 /* UDT0 */
#define TIMER_CAPTURE_MODE  0x001 /* MDT0 */

// structure for timer
typedef volatile struct microblaze_timer_t {
	int control; /* control/statuc register TCSR */
	int loadreg; /* load register TLR */
	int counter; /* timer/counter register */
} microblaze_timer_t;

typedef volatile struct microblaze_intc_t {
	int isr; /* interrupt status register */
	int ipr; /* interrupt pending register */
	int ier; /* interrupt enable register */
	int iar; /* interrupt acknowledge register */
	int sie; /* set interrupt enable bits */
	int cie; /* clear interrupt enable bits */
	int ivr; /* interrupt vector register */
	int mer; /* master enable register */
} microblaze_intc_t;
