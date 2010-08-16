#include <stdio.h>
#include <stdlib.h>
#include "cpu.h"
#include "memory.h"

int main( int argc, char *argv[] )
{
    Memory mem( 256 );
    Cpu cpu( &mem, true );

    if( argc > 2 ) exit( 1 );
    else if( argc == 2 )    mem.init( argv[1] );
    
    cpu.run( 2000 );
    mem.dump( "changed.m" );
    return 0;
}
