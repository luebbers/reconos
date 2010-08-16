#ifndef CHAR_LCD_SUPPORT
#define CHAR_LCD_SUPPORT

void init_char_lcd(void);
int write_char_lcd( unsigned char * buffer, unsigned int length );
int get_current_position( unsigned char * row, unsigned char * column );
int get_current_memory_position( unsigned char * address );

#endif // CHAR_LCD_SUPPORT
