sort_demo: Demonstrator for ReconOS
===================================

Files and Directories
---------------------

    src/        all necessary source files (hw and sw)
    runme.sh    script to build project


To build hardware:

    ./runme.sh
    cd sort_demo_generated
    . settings.sh
    cd hw
    make bits-static

Bitstream will be in
    sort_demo_generated/hw/edk-static/implementation/system.bit    


To build software (after building hardware): 
    cd sort_demo_generated
    . settings.sh
    cd sw
    make setup.mb deps ecos.mb posix

Executables will be in the same directory (*.elf).

    
