ECOS_CONFIG=ecos_config.ecc
ECOS_BUILD=ecos_build
ECOS_INSTALL=$(ECOS_BUILD)/install
ECOS_SRC=$(ECOS_REPOSITORY)
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)
CFLAGS = 

#COMMON_OBJECTS=src/observation.o src/bgr2hsv.o src/histogram.o framework/user_src/uf_likelihood.o src/ethernet.o src/display.o src/tft_screen.o framework/src/particle_filter.o framework/user_src/uf_init_particles.o framework/src/sampling.o framework/src/importance.o framework/src/resampling.o framework/user_src/uf_prediction.o framework/user_src/uf_get_observation.o  framework/user_src/uf_receive_new_measurement.o  framework/user_src/uf_output.o  framework/user_src/uf_set_reference_data.o framework/src/timing.o
#ECOS_OBJECTS=src/object_tracker.o
#ECOS_TARGETS=object_tracker.elf
#PC_OBJECTS=src/object_tracker_pc.o
#PC_TARGETS=object_tracker_pc
