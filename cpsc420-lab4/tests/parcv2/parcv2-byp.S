//========================================================================
// parcv2-ooo.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          li    $1, 0
          li    $2, 0
          addiu $1, $1, 1
          addiu $2, $2, 2
          TEST_CHECK_EQ( $1, 1 )
          TEST_CHECK_EQ( $2, 2 )

        TEST_PARC_END
