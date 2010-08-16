#ifndef _CPU_H_
#define _CPU_H_

#include "memory.h"

#define OPCODE_ADD      0x0
#define OPCODE_SUB      0x1
#define OPCODE_OR       0x2
#define OPCODE_AND      0x3
#define OPCODE_ADDC     0x8
#define OPCODE_SUBC     0x9
#define OPCODE_ORC      0xA
#define OPCODE_ANDC     0xB
#define OPCODE_BRA      0xE
#define OPCODE_JMP      0x7
#define OPCODE_JMPC     0xF
#define OPCODE_SET      0x6
#define OPCODE_SW       0x5
#define OPCODE_LW       0x4
#define OPCODE_SWC      0xD
#define OPCODE_LWC      0xC

class Cpu
{
public:
    Cpu( Memory *mem )
    {
        this->mem = mem;
    }

    Cpu( Memory *mem, bool debug )
    {
        this->mem = mem;
        this->debug = debug;
    }

    void run()
    {
        init();
        while( !stop ) next();
        showregs();
    }

    void run( unsigned int instr )
    {
        init();
        while( instr-- > 0 && !stop ) next();
        showregs();
    }

    void showregs()
    {
        printf( "STA = %2.2X\n", sta );
        for( int i = 0; i < 16; i++ )
        {
            printf( "R%d = %4.4X\n", i, regs[i] );
        }
    }

private:
    void init()
    {
        for( int i = 0; i < 16; i++ ) regs[i] = 0;
        regs[1] = 1;
        sta = 0;
        pc = 0;
        stop = false;
    }

    void next()
    {
        unsigned short next = mem->read( pc );
        int o = oper3( next );
        int b = braoff( next );
        unsigned int s = oper1( next );
        unsigned int t = oper2( next );
        unsigned int d = oper3( next );
        unsigned int j = jmpoff( next );

        switch( instr(next) )
        {
        case OPCODE_ADD:
            if( d > 1 )
            {
                regs[d] = regs[s] + regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "ADD: (PC=%4.4X) (INST=%4.4X) (R%d=%d)\n", pc, next, d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_SUB:
            if( d > 1 ) 
            {
                regs[d] = regs[s] - regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "SUB: (PC=%4.4X) (INST=%4.4X) (R%d=%d)\n", pc, next, d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_OR:
            if( d > 1 )
            {
                regs[d] = regs[s] | regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "OR  (PC=%4.4X) (INST=%4.4X) (R%d=%d)\n", pc, next, d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_AND:
            if( d > 1 ) 
            {
                regs[d] = regs[s] & regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "AND: (PC=%4.4X) (INST=%4.4X) (R%d=%d)\n", pc, next, d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_ADDC:
            if( d > 1 && (sta & 0xF) )
            {
                regs[d] = regs[s] + regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "ADDC: (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (R%d=%d)\n", pc, next, (sta&0xF), d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_SUBC:
            if( d > 1 && (sta & 0xF) )
            {
                regs[d] = regs[s] - regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "SUBC: (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (R%d=%d)\n", pc, next, (sta&0xF), d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_ORC:
            if( d > 1 && (sta & 0xF) )
            {
                regs[d] = regs[s] | regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "ORC  (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (R%d=%d)\n", pc, next, (sta&0xF), d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_ANDC:
            if( d > 1 && (sta & 0xF) )
            {
                regs[d] = regs[s] & regs[t];
                updatesta( s, t, d );
            }

            if( debug ) printf( "ANDC: (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (R%d=%d)\n", pc, next, (sta&0xF), d, regs[d] );
            pc = pc + 2;
            break;

        case OPCODE_BRA:
            if( debug ) printf( "BRA: (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (MSK=%1.1X) (OFF=%d)\n", pc, next, sta, s, b );
            if( ((sta & 0xF) & s) > 0 ) { pc += b; if( b == 0 ) stop = true; }
            else                        { pc += 2; }
            break;

        case OPCODE_JMP:
            unsigned int old = pc;
            pc = (pc & 0x80) | ((j & 0xFFF) << 3);
            if( debug ) printf( "JMP: (PC=%4.4X) (INST=%4.4X) (DST=%4.4X)\n", old, next, pc );
            if( pc == old ) stop = true;
            break;

        case OPCODE_JMPC:
            if( debug ) printf( "JMPC: (PC=%4.4X) (STA=%1.1X) (INST=%4.4X)\n", pc, (sta&0xF), next );
            if( (sta & 0xF) > 0 )
            {
                unsigned int old = pc;
                pc = (pc & 0x80) | ((j & 0xFFF) << 3);
                if( pc == old ) stop = true;
            }
            else
            {
                pc = pc + 2;
            }
            break;

        case OPCODE_SET:
            unsigned nmsk = (((regs[s] == regs[t] == 0) << 3) |
                             ((regs[s] > regs[t])  << 2) |
                             ((regs[s] == regs[t]) << 1) |
                             ((regs[s] < regs[t])  << 0)) & d;
            sta = (sta & 0xF0) | (nmsk & 0x0F);
            if( debug ) printf( "SET: (PC=%4.4X) (INST=%4.4X) (MSK=%1.1X)\n", pc, next, nmsk );
            pc = pc + 2;
            break;

        case OPCODE_LW:
            if( t > 1 ) regs[t] = mem->read( regs[s] + 2*o );
            if( debug ) printf( "LW:  (PC=%4.4X) (INST=%4.4X) (O=%d) (R%d=%d)\n", pc, next, 2*o, t, regs[t] );
            pc = pc + 2;
            break;

        case OPCODE_SW:
            mem->write( regs[s] + 2*o, regs[t] );
            if( debug ) printf( "SW:  (PC=%4.4X) (INST=%4.4X) (O=%d) (M[%d]=%d)\n", pc, next, 2*o, regs[s]+2*o, regs[t] );
            pc = pc + 2;
            break;

        case OPCODE_LWC:
            if( t > 1 && (sta & 0xF) > 0 ) regs[t] = mem->read( regs[s] + 2*o );
            if( debug ) printf( "LWC:  (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (O=%d) (R%d=%d)\n", pc, next, (sta&0xF), 2*o, t, regs[t] );
            pc = pc + 2;
            break;

        case OPCODE_SWC:
            if( (sta&0xF) > 0 ) mem->write( regs[s] + 2*o, regs[t] );
            if( debug ) printf( "SWC:  (PC=%4.4X) (INST=%4.4X) (STA=%1.1X) (O=%d) (M[%d]=%d)\n", pc, next, (sta&0xF), 2*o, regs[s]+2*o, regs[t] );
            pc = pc + 2;
            break;

        default:
            if( debug ) printf( "Unknown Instruction: %4.4X\n", next );
            pc = pc + 2;
        }
    }

    void updatesta( int s, int t, int d )
    {
        unsigned nmsk = (((regs[d] == 0) << 3) |
                         ((regs[s] > regs[t])  << 2) |
                         ((regs[s] == regs[t]) << 1) |
                         ((regs[s] < regs[t])  << 0)) & 0xF;
        sta = (sta & 0xF0) | (nmsk & 0x0F);
    }

    unsigned int instr( unsigned short intsr )
    {
        return ((intsr >> 12) & 0xF);
    }

    unsigned int oper1( unsigned short intsr )
    {
        return ((intsr >> 8) & 0xF);
    }

    unsigned int oper2( unsigned short intsr )
    {
        return ((intsr >> 4) & 0xF);
    }

    unsigned int oper3( unsigned short intsr )
    {
        return ((intsr >> 0) & 0xF);
    }

    int braoff( unsigned short intsr )
    {
        unsigned int off = (intsr >> 0) & 0xFF;
        if( off >= 128 ) off = -((~off & 0xFF) + 1);
        return 2*off;
    }


    unsigned int jmpoff( unsigned short intsr )
    {
        return ((intsr >> 0) & 0xFFF);
    }

private:
    signed short  regs[16];
    unsigned char sta;
    unsigned int  pc;
    Memory        *mem;
    bool          debug;
    bool          stop;
};

#endif
