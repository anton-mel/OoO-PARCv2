//========================================================================
// parcv2-spec-data.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test branches with data dependencies
          li    $1, 0
          li    $2, 1
          
          // Branch depends on result of previous instruction
          addiu $1, $1, 1
          bne   $1, $2, 1f
          addiu $1, $1, 1
      1:  // Branch depends on result of speculated instruction
          bne   $1, $2, 2f
          addiu $1, $1, 1
      2:  TEST_CHECK_EQ( $1, 1 )

          // Test with muldiv instruction in speculation path
          li    $3, 2
          li    $4, 3
          mul   $5, $3, $4    // $5 = 6
          bne   $5, $4, 3f    // Should not take branch
          addiu $5, $5, 1
      3:  TEST_CHECK_EQ( $5, 6 )

        TEST_PARC_END 