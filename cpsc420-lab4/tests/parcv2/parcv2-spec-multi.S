//========================================================================
// parcv2-spec-multi.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test register file write port conflicts
          li    $1, 1
          li    $2, 2
          li    $3, 3
          
          // Test multiple writes to same register
          addiu $1, $1, 1
          addiu $1, $1, 1
          addiu $1, $1, 1
          TEST_CHECK_EQ( $1, 4 )
          
          // Test writes to different registers
          addiu $2, $2, 1
          addiu $3, $3, 1
          TEST_CHECK_EQ( $2, 3 )
          TEST_CHECK_EQ( $3, 4 )

        TEST_PARC_END 
        TEST_PARC_END 