//========================================================================
// parcv2-spec-multi.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test two consecutive branches
          li    $1, 0
          li    $2, 1
          
          // First branch (taken)
          bne   $1, $2, 1f
          addiu $1, $1, 1
      1:  // Second branch (not taken)
          beq   $1, $2, 2f
          addiu $1, $1, 1
      2:  TEST_CHECK_EQ( $1, 0 )

        TEST_PARC_END 