//========================================================================
// parcv2-waw.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          li     $1, 0

          MUL    $2, $1, $1

          NOP
          NOP
          NOP
          NOP

          ADDIU  $2, $1, 5

          NOP
          NOP
          NOP
          NOP

          ADDU   $3, $2, $1

          TEST_CHECK_EQ( $3, 5 )

        TEST_PARC_END
