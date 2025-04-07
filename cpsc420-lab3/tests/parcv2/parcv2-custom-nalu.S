#include "parc-macros.h"

        .data
data_0: .word  0xAABBCCDD
data_1: .word  0x11223344

TEST_PARC_BEGIN

    # $2 points to data_0
    la    $2, data_0

    # $3 = 0xDEADBEEF
    li    $3, 0xDEADBEEF

    lw    $4, 0($2)        # Non-ALU instruction (Load)
    sw    $3, 4($2)        # Non-ALU instruction (Store) – must stall

    lw    $5, 4($2)        # Load back the stored value

    TEST_CHECK_EQ( $4, 0xAABBCCDD )    # original value
    TEST_CHECK_EQ( $5, 0xDEADBEEF )    # new stored value

TEST_PARC_END
