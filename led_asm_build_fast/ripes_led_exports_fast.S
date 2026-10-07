.equ LED_MATRIX_0_BASE,   0xf0000000
.equ LED_MATRIX_0_WIDTH,  0x23
.equ LED_MATRIX_0_HEIGHT, 0x19
.include "led_renderer_rv32_fast.S"
