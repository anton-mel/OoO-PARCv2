//========================================================================
// parcv2-spec-multi.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test branch target calculation
          li    $1, 0
          li    $2, 4
          
          // Calculate branch target dynamically
          addiu $1, $1, 1
          addiu $1, $1, 1
          addiu $1, $1, 1
          beq   $1, $2, 1f
          addiu $1, $1, 1
      1:  TEST_CHECK_EQ( $1, 3 )

        TEST_PARC_END 