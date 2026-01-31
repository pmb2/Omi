#ifndef LED_OVERRIDE_H
#define LED_OVERRIDE_H

#include <stdbool.h>
#include <stdint.h>

typedef enum {
    LED_OVERRIDE_NONE = 0,
    LED_OVERRIDE_GREEN_SOLID = 1,
    LED_OVERRIDE_GREEN_BLINK = 2,
} led_override_mode_t;

void led_override_set(uint8_t mode);
uint8_t led_override_get(void);
bool led_override_is_active(void);

#endif // LED_OVERRIDE_H
