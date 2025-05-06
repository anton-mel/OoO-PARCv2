//========================================================================
// parcv2-spec-multi.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test basic value forwarding
          li    $1, 0
          li    $2, 1
          
          // Simple value forwarding chain
          addiu $1, $1, 1
          addiu $1, $1, 1
          addiu $1, $1, 1
          TEST_CHECK_EQ( $1, 3 )

        TEST_PARC_END 
        TEST_PARC_END 