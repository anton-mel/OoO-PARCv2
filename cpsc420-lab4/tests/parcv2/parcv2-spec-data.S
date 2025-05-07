//========================================================================
// parcv2-spec-data.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test branches with register dependencies
          li    $1, 0
          li    $2, 1
          
          // First register dependency
          addiu $1, $1, 1
          beq   $1, $2, 1f
          addiu $1, $1, 1
      1:  // Second register dependency
          addiu $2, $2, 1
          bne   $1, $2, 2f
          addiu $1, $1, 1
      2:  TEST_CHECK_EQ( $1, 1 )
          TEST_CHECK_EQ( $2, 2 )

        TEST_PARC_END 