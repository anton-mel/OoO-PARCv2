//=========================================================================
// parcv2-ooo.S
//=========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // 1) slow MUL → writes $1 = 0 (4-cycle latency)
          MUL    $1, $0, $0

          // 2) fast ADDIU → writes $1 = 5 (1-cycle latency)
          ADDIU  $1, $0, 5

          // 3) copy result into $2
          ADDU   $2, $1, $0

          // 4) must be 5 (fails on I2O2, passes once you have in-order ROB)
          TEST_CHECK_EQ( $2, 5 )

        TEST_PARC_END
