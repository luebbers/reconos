proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "XI2c" "NUM_INSTANCES" "C_BASEADDR" "C_HIGHADDR"
}
