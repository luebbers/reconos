#ifndef _MEMORY_H_
#define _MEMORY_H_

class Memory
{
public:
    Memory( int s )
    {
        data = new unsigned char[s];
        mod  = new unsigned char[s];
        size = s;
        clear();
    }

    ~Memory()
    {
        if( data != NULL ) delete[] data;
        size = 0;
        data = NULL;
    }

    void clear()
    {
        fill( 0 );
    }

    void fill( unsigned short value )
    {
        for( unsigned int i = 0; i < size; i++ ) data[i] = value;
        for( unsigned int i = 0; i < size; i++ )  mod[i] = 0;
    }

    unsigned short read( unsigned int loc )
    {
        if(loc >= size-1) return 0;
        else              return ((unsigned short)data[loc]<<8)|data[loc+1];
    }

    void write( unsigned int loc, unsigned short val, bool update = true )
    {
        if( loc >= size - 1 ) return;

        if( update )
        {
            mod[loc] = 1;
            mod[loc+1] = 1;
        }

        data[loc]   = (val >> 8) & 0xFF;
        data[loc+1] = (val >> 0) & 0xFF;
    }

    void init( const char *path )
    {
        int l;
        int v;
        char buffer[4096];

        FILE *input = fopen( path, "r" );
        if( input == NULL ) { perror( "couldn't open file" ); exit(1); }

        char *line;
        while( (line = fgets( buffer, 4096, input )) != NULL )
        {
            sscanf( line, "%X %X", &l, &v );
            write( l, v, false );
            //printf( "Initializing: %x = %x (%x%x)\n", l, v, data[l], data[l+1] );
        }
    }

    void dump( const char *path )
    {
        FILE *output = fopen( path, "w" );
        if( output == NULL ) { perror( "couldn't open file" ); exit(1); }

        for( unsigned int i = 0; i < size-1; i += 2 )
        {
            if( mod[i] || mod[i+1] )
            //if( data[i] != 0 || data[i+1] != 0 )
            {
                fprintf( output, "%4.4X ", i );
                fprintf( output, "%2.2X%2.2X\n", data[i], data[i+1] );
            }
        }
    }

private:
    unsigned int size;
    unsigned char *data;
    unsigned char *mod;
};

#endif
