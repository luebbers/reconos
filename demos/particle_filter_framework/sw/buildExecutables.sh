#!/bin/bash

make clean

make executables/object_tracker_soccer_sw.elf
make executables/object_tracker_soccer_hw_s.elf
make executables/object_tracker_soccer_hw_i.elf
make executables/object_tracker_soccer_hw_r.elf
make executables/object_tracker_soccer_hw_a.elf

make executables/object_tracker_football_sw.elf
make executables/object_tracker_football_hw_s.elf
make executables/object_tracker_football_hw_i.elf
make executables/object_tracker_football_hw_r.elf
make executables/object_tracker_football_hw_a.elf

make executables/object_tracker_hockey_sw.elf
make executables/object_tracker_hockey_hw_s.elf
make executables/object_tracker_hockey_hw_i.elf
make executables/object_tracker_hockey_hw_r.elf
make executables/object_tracker_hockey_hw_a.elf












