//========================================================================
// parcv2-ooo.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          li    $4, 0
          la    $2, tdata_0
          lh    $4, $2
          addiu $4, $4, 1
          addiu $4, $4, 1
          addiu $4, $4, 1
          addiu $4, $4, 1
          TEST_CHECK_EQ( $4, 4 )

        TEST_PARC_END

tdata_0: .word 0xdeadbeef