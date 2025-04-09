#include "parc-macros.h"

TEST_PARC_BEGIN

    li    $2, 42;
    li    $3, 58;

    addu  $4, $2, $3;       # $4 = 100 RAW hazard
    addu  $5, $4, $3;       # $4 is written in previous instr

    TEST_CHECK_EQ( $5, 158 );

TEST_PARC_END
