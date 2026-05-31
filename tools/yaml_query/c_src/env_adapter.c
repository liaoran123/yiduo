#include <stdlib.h>
#include <string.h>

static char env_buf[4096] = {0};

const char* yq_getenv(const char* key) {
    const char* val = getenv(key);
    if (val) {
        size_t len = strlen(val);
        if (len >= sizeof(env_buf)) len = sizeof(env_buf) - 1;
        memcpy(env_buf, val, len);
        env_buf[len] = '\0';
        return env_buf;
    }
    return "";
}