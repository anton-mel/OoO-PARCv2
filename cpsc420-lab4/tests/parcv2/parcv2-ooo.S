//========================================================================
// parcv2-ooo.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // slow MUL → $1 = 0 (4-cycle)
          MUL    $1, $0, $0

          // fast ADDIU → $1 = 5 (1-cycle)
          ADDIU  $1, $0, 5

          // wait out both writebacks (MUL takes 4 cycles)
          NOP
          NOP
          NOP
          NOP

          // now read $1 from the reg‐file (not from bypass)
          ADDU   $2, $1, $0

          // on I2O2 this will see the MUL’s “0” and trap;
          // with an in-order ROB it will be 5 and pass
          TEST_CHECK_EQ( $2, 5 )

        TEST_PARC_END
