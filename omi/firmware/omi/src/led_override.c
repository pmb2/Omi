#include "lib/core/led_override.h"

static uint8_t led_override_mode = LED_OVERRIDE_NONE;

void led_override_set(uint8_t mode)
{
    led_override_mode = mode;
}

uint8_t led_override_get(void)
{
    return led_override_mode;
}

bool led_override_is_active(void)
{
    return led_override_mode != LED_OVERRIDE_NONE;
}
