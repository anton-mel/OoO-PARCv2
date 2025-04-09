#include "parc-macros.h"

TEST_PARC_BEGIN

    li    $2, 10;
    li    $3, 20;

    addu  $4, $2, $2;       # $4 = 20 WAW hazard
    addu  $4, $2, $3;       # $4 = 30 (should be final value)

    TEST_CHECK_EQ( $4, 30 );

TEST_PARC_END
