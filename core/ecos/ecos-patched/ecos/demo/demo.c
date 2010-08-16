/* 
 * Mind eCos demo
 * 
 * Copyright (c) 2005 Mind NV
 * 
 * Author : Jan Olbrechts (jano@mind.be)
 */

#include <stdio.h>
#include <string.h>
#include <cyg/io/io.h>
#include <cyg/hal/led_manager.h>
#include <stdlib.h>
#include <network.h>
#include <cyg/hal/char_lcd_support.h>
#include <cyg/hal/hal_if.h>
#include "startThread.h"


cyg_io_handle_t demo_serial_handle;

void demo_init_serial()
{
  if (cyg_io_lookup( "/dev/ser0", &demo_serial_handle )) {
    diag_printf("No /dev/ser0\n");
    for (;;);
  }
}

void demo_print_serial(char* string)
{
  cyg_uint32 len = strlen(string);
  cyg_io_write( demo_serial_handle, string, &len );
  len = 2;
  cyg_io_write( demo_serial_handle, "\r\n", &len );
}

void demo_leds_test(void* dummy)
{
  for (;;) {
    turn_on_led(1 << 0);
    sleep(1);
    turn_on_led(1 << 1);
    sleep(1);
    turn_on_led(1 << 2);
    sleep(1);
    turn_on_led(1 << 3);
    sleep(1);
    turn_off_led(1 << 0);
    sleep(1);
    turn_off_led(1 << 1);
    sleep(1);
    turn_off_led(1 << 2);
    sleep(1);
    turn_off_led(1 << 3);
    sleep(1);
  }
}

void demo_a()
{
  printf("This is function a\n");
}

static void demo_server_test(void* dummy, int readNotWrite)
{
    int s, client, client_len;
    struct sockaddr_in client_addr, local;
    char buf[1024];
    int one = 1;
    fd_set in_fds;
    int num, len;
    struct timeval tv;

    bzero(buf, sizeof(buf));

    init_all_network_interfaces();
    printf("Network initialized!\n");

    s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) {
        perror("stream socket");
    }
    if (setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one))) {
        perror("setsockopt SO_REUSEADDR");
    }
    if (setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &one, sizeof(one))) {
        perror("setsockopt SO_REUSEPORT");
    }
    memset(&local, 0, sizeof(local));
    local.sin_family = AF_INET;
    local.sin_len = sizeof(local);
    if (readNotWrite)
      local.sin_port = htons(1234);
    else
      local.sin_port = htons(1235);
    local.sin_addr.s_addr = INADDR_ANY;
    if(bind(s, (struct sockaddr *) &local, sizeof(local)) < 0) {
        perror("bind error");
    }
    listen(s, SOMAXCONN);
    while (true) {
        client_len = sizeof(client_addr);
        if ((client = accept(s, (struct sockaddr *)&client_addr, &client_len)) < 0) {
            perror("accept");
        }
        client_len = sizeof(client_addr);
        getpeername(client, (struct sockaddr *)&client_addr, &client_len);
        diag_printf("connection from %s:%d\n", inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));

        while (true) {
          if (readNotWrite) {
            len = read(client, buf, sizeof(buf));
            if (len <= 0)
              break;
          } else {
            len = write(client, buf, sizeof(buf));
            if (len <= 0)
              break;
          }
        }
        close(client);
    }
    close(s);
}

static void demo_server_test_read(void* dummy)
{
  demo_server_test(dummy, 1);
}

static void demo_server_test_write(void* dummy)
{
  demo_server_test(dummy, 0);
}

void demo_loop_test(void* dummy)
{
  int i, j;
  volatile char a;
  char* buf;

  // Test the data cache
  buf = (char*) malloc(50);

  for (;;) {
    for (i = 0; i < (1000000); i++) {
      for (j = 0; j < 50; j++) {
        a = buf[j];
      }
    }
    //breakpoint();
  }
}

void demo_lcd_test(void* dummy)
{
  write_char_lcd("test ", 5);
  write_char_lcd("LCD ", 4);
  write_char_lcd("1234", 4);
}

void demo_serial_test(void* dummy)
{
  demo_print_serial("Serial port test");
  for (;;) {
    sleep(1);
    demo_print_serial("tick");
    sleep(1);
    demo_print_serial("tack");
  }
}

void demo_console_test(void* dummy)
{
  char word[1024];

  for (;;) {
    scanf("%s", word);
    printf("You typed: %s\n", word);
  }
}

void cyg_start()
{
  printf("main started!\n");

  demo_init_serial();

  // Init everything
  init_led_manager();
  printf("Leds initialized!\n");
  init_char_lcd();
  printf("Lcd initialized!\n");
  demo_init_serial();
  printf("Serial initialized!\n");

  // Start threads
  // Loop thread disabled to measure TCP performance
  // startThread("Loop test", demo_loop_test, 10);
  // printf("Loop thread started!\n");
  startThread("Tcp read test", demo_server_test_read, 10);
  startThread("Tcp write test", demo_server_test_write, 10);
  printf("Tcp echo thread started!\n");
  startThread("Lcd test", demo_lcd_test, 10);
  printf("Lcd thread started!\n");
  startThread("Serial test", demo_serial_test, 10);
  printf("Serial thread started!\n");
  startThread("Leds test", demo_leds_test, 10);
  printf("Leds thread started!\n");
  // keyboard driver not ready yet
  //startThread("Console test", demo_console_test, 10);
  //printf("Console thread started!\n");

  cyg_scheduler_start();
}

