//========================================================================
// parcv2-spec-nested.S
//========================================================================

#include "parc-macros.h"

        TEST_PARC_BEGIN

          // Test nested branch speculations
          li    $1, 0
          li    $2, 1
          li    $3, 2
          
          // First branch speculation
          bne   $1, $2, 1f
          addiu $1, $1, 1
      1:  // Nested branch speculation
          bne   $1, $3, 2f
          addiu $1, $1, 1
      2:  // Final check
          TEST_CHECK_EQ( $1, 0 )

        TEST_PARC_END 