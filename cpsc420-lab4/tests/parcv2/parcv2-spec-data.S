//========================================================================
// parcv2-spec-data.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test branch with simple data dependency
          li    $1, 0
          li    $2, 1
          
          // Branch depends on result of previous instruction
          addiu $1, $1, 1
          bne   $1, $2, 1f
          addiu $1, $1, 1
      1:  TEST_CHECK_EQ( $1, 1 )

          // Test with simple arithmetic in speculation path
          li    $3, 2
          addiu $3, $3, 1    // $3 = 3
          bne   $3, $2, 2f   // Should take branch
          addiu $3, $3, 1
      2:  TEST_CHECK_EQ( $3, 3 )

        TEST_PARC_END 