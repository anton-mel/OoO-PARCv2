#include "parc-macros.h"

TEST_PARC_BEGIN

    li    $2, 1;
    li    $3, 2;

    addu  $4, $2, $2;       # $4 = 2
    addu  $5, $3, $3;       # $5 = 4 (no hazard, dual issue should work)

    TEST_CHECK_EQ( $4, 2 );
    TEST_CHECK_EQ( $5, 4 );

TEST_PARC_END
