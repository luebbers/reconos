/*! \file circuits.h 
 * \brief sets reconos circuits for dynamic hw threads
 */


#ifndef __CIRCUITS_H__
#define __CIRCUITS_H__

#include <reconos/reconos.h>
#include <reconos/resources.h>

//#include "../prm0_sort8k_routed_partial.bit.h"
#include "../prm0_observation_routed_partial.bit.h"
#include "../prm0_importance_routed_partial.bit.h"
//#include "../prm1_sort8k_routed_partial.bit.h"
#include "../prm1_observation_routed_partial.bit.h"
#include "../prm1_importance_routed_partial.bit.h"

//! circuits
/*reconos_circuit_t hw_thread_s_circuit;
reconos_circuit_t hw_thread_o_circuit;
reconos_bitstream_t sort8k_bitstream_0;
reconos_bitstream_t observation_bitstream_0;
reconos_bitstream_t sort8k_bitstream_1;
reconos_bitstream_t observation_bitstream_1;
*/

// bitstreams and circuits
// sort8k
/*reconos_bitstream_t sort8k_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_sort8k_routed_partial_bit,
    .size     = PRM0_SORT8K_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm0_sort8k_routed_partial.bit"
};

reconos_bitstream_t sort8k_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_sort8k_routed_partial_bit,
    .size     = PRM1_SORT8K_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm1_sort8k_routed_partial.bit"
};

reconos_circuit_t hw_thread_s_circuit = {
    .name     = "SORT8K",
    .bitstreams = {&sort8k_bitstream_0, &sort8k_bitstream_1},
    .num_bitstreams = 2,
    .signature = 0x5A5A5A5A
    //.bitstreams = {&sort8k_bitstream_0},
    //.num_bitstreams = 1
};*/


// bitstreams and circuits
// observation
reconos_bitstream_t observation_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_observation_routed_partial_bit,
    .size     = PRM0_OBSERVATION_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm0_observation_routed_partial.bit"
};

reconos_bitstream_t observation_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_observation_routed_partial_bit,
    .size     = PRM1_OBSERVATION_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm1_observation_routed_partial.bit"
};

reconos_circuit_t hw_thread_o_circuit = {
    .name     = "OBSERVATION",
    .bitstreams = {&observation_bitstream_0, &observation_bitstream_1},
    .num_bitstreams = 2,
    .signature = 0x0B0B0B0B
    //.bitstreams = {&observation_bitstream_0},
    //.num_bitstreams = 1
};

// importance
reconos_bitstream_t importance_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_importance_routed_partial_bit,
    .size     = PRM0_IMPORTANCE_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm0_importance_routed_partial.bit"
};

reconos_bitstream_t importance_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_importance_routed_partial_bit,
    .size     = PRM1_IMPORTANCE_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm1_importance_routed_partial.bit"
};

reconos_circuit_t hw_thread_i_circuit = {
    .name     = "IMPORTANCE",
    .bitstreams = {&importance_bitstream_0, &importance_bitstream_1},
    .num_bitstreams = 2,
    .signature = 0x11111111
    //.bitstreams = {&importance_bitstream_0},
    //.num_bitstreams = 1
};


#endif
