//========================================================================
// parcv2-ooo.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          li    $2, 2
          li    $3, 1
          mul   $4, $2, $3
          li    $3, 1
          mul   $4, $2, $3
          li    $3, 1
          addu $2, $4, $4
          TEST_CHECK_EQ( $2, 4 )
          TEST_CHECK_EQ( $3, 1 )
          TEST_CHECK_EQ( $4, 2 )

        TEST_PARC_END
