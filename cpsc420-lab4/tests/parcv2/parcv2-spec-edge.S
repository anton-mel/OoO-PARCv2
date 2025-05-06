//========================================================================
// parcv2-spec-edge.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test branch with zero condition
          li    $1, 0
          beq   $1, $0, 1f    // Branch if $1 == 0
          addiu $1, $1, 1
      1:  TEST_CHECK_EQ( $1, 0 )

          // Test branch with negative condition
          li    $2, -1
          bltz  $2, 2f        // Branch if $2 < 0
          addiu $2, $2, 1
      2:  TEST_CHECK_EQ( $2, -1 )

          // Test branch with positive condition
          li    $3, 1
          bgtz  $3, 3f        // Branch if $3 > 0
          addiu $3, $3, 1
      3:  TEST_CHECK_EQ( $3, 1 )

          // Test branch with equal condition
          li    $4, 5
          li    $5, 5
          beq   $4, $5, 4f    // Branch if $4 == $5
          addiu $4, $4, 1
      4:  TEST_CHECK_EQ( $4, 5 )

        TEST_PARC_END 