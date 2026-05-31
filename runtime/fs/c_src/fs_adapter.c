#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <dirent.h>
#endif

#include "moonbit.h"

static char content_buf[65536] = {0};
static char error_buf[256] = {0};
static char list_buf[65536] = {0};
static char path_utf8[4096] = {0};

// ── UTF-16 → UTF-8 (for path input) ──
static int utf16_to_utf8(const uint16_t* utf16, char* utf8, size_t utf8_size) {
#ifdef _WIN32
    int len = WideCharToMultiByte(CP_UTF8, 0, (LPCWSTR)utf16, -1, utf8, (int)utf8_size, NULL, NULL);
    if (len <= 0) return -1;
    return 0;
#else
    size_t pos = 0;
    while (*utf16 && pos < utf8_size - 1) {
        uint32_t cp = *utf16;
        if (cp >= 0xD800 && cp <= 0xDBFF && *(utf16 + 1) >= 0xDC00 && *(utf16 + 1) <= 0xDFFF) {
            cp = 0x10000 + ((cp - 0xD800) << 10) + (*(utf16 + 1) - 0xDC00);
            utf16++;
        }
        if (cp < 0x80) {
            utf8[pos++] = (char)cp;
        } else if (cp < 0x800) {
            if (pos + 2 > utf8_size - 1) break;
            utf8[pos++] = 0xC0 | (cp >> 6);
            utf8[pos++] = 0x80 | (cp & 0x3F);
        } else if (cp < 0x10000) {
            if (pos + 3 > utf8_size - 1) break;
            utf8[pos++] = 0xE0 | (cp >> 12);
            utf8[pos++] = 0x80 | ((cp >> 6) & 0x3F);
            utf8[pos++] = 0x80 | (cp & 0x3F);
        } else {
            if (pos + 4 > utf8_size - 1) break;
            utf8[pos++] = 0xF0 | (cp >> 18);
            utf8[pos++] = 0x80 | ((cp >> 12) & 0x3F);
            utf8[pos++] = 0x80 | ((cp >> 6) & 0x3F);
            utf8[pos++] = 0x80 | (cp & 0x3F);
        }
        utf16++;
    }
    utf8[pos] = '\0';
    return 0;
#endif
}

// ── UTF-8 → MoonBit String (for return values) ──
static moonbit_string_t utf8_to_moonbit_string(const char* utf8) {
#ifdef _WIN32
    int utf16_len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
    if (utf16_len <= 0) {
        utf16_len = 1;
    }
    moonbit_string_t result = moonbit_make_string_raw(utf16_len - 1);
    if (result) {
        MultiByteToWideChar(CP_UTF8, 0, utf8, -1, (LPWSTR)result, utf16_len);
    }
    return result;
#else
    // Count UTF-16 code units needed
    size_t utf16_len = 0;
    const unsigned char* s = (const unsigned char*)utf8;
    while (*s) {
        uint32_t cp;
        if (*s < 0x80) {
            cp = *s; s += 1;
        } else if ((*s & 0xE0) == 0xC0) {
            cp = *s & 0x1F; s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
        } else if ((*s & 0xF0) == 0xE0) {
            cp = *s & 0x0F; s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
        } else if ((*s & 0xF8) == 0xF0) {
            cp = *s & 0x07; s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
        } else {
            cp = 0; s += 1;
        }
        if (cp < 0x10000) {
            utf16_len++;
        } else {
            utf16_len += 2;
        }
    }
    moonbit_string_t result = moonbit_make_string_raw((int32_t)utf16_len);
    if (!result) return NULL;
    uint16_t* dst = result;
    s = (const unsigned char*)utf8;
    while (*s) {
        uint32_t cp;
        if (*s < 0x80) {
            cp = *s; s += 1;
        } else if ((*s & 0xE0) == 0xC0) {
            cp = *s & 0x1F; s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
        } else if ((*s & 0xF0) == 0xE0) {
            cp = *s & 0x0F; s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
        } else if ((*s & 0xF8) == 0xF0) {
            cp = *s & 0x07; s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
            cp = (cp << 6) | (*s & 0x3F); s += 1;
        } else {
            cp = 0; s += 1;
        }
        if (cp < 0x10000) {
            *dst++ = (uint16_t)cp;
        } else {
            cp -= 0x10000;
            *dst++ = (uint16_t)(0xD800 | (cp >> 10));
            *dst++ = (uint16_t)(0xDC00 | (cp & 0x3FF));
        }
    }
    return result;
#endif
}

int fs_read_file(moonbit_string_t path_utf16) {
    if (utf16_to_utf8(path_utf16, path_utf8, sizeof(path_utf8)) != 0) {
        snprintf(error_buf, sizeof(error_buf), "Path conversion failed");
        return -1;
    }
    FILE* f = fopen(path_utf8, "rb");
    if (!f) {
        snprintf(error_buf, sizeof(error_buf), "Cannot open file: %s", path_utf8);
        return -1;
    }
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (len < 0) {
        snprintf(error_buf, sizeof(error_buf), "Failed to get file size: %s", path_utf8);
        fclose(f);
        return -1;
    }
    if (len >= (long)sizeof(content_buf)) {
        snprintf(error_buf, sizeof(error_buf), "File too large (max %zu bytes)", sizeof(content_buf) - 1);
        fclose(f);
        return -1;
    }
    size_t n = fread(content_buf, 1, (size_t)len, f);
    content_buf[n] = '\0';
    fclose(f);
    return 0;
}

moonbit_string_t fs_get_content(void) {
    return utf8_to_moonbit_string(content_buf);
}

moonbit_string_t fs_last_error(void) {
    return utf8_to_moonbit_string(error_buf);
}

int fs_list_dir(moonbit_string_t dir_utf16) {
    if (utf16_to_utf8(dir_utf16, path_utf8, sizeof(path_utf8)) != 0) {
        snprintf(error_buf, sizeof(error_buf), "Path conversion failed");
        return -1;
    }
#ifdef _WIN32
    char pattern[1024];
    snprintf(pattern, sizeof(pattern), "%s\\*", path_utf8);
    WIN32_FIND_DATA ffd;
    HANDLE hFind = FindFirstFile(pattern, &ffd);
    if (hFind == INVALID_HANDLE_VALUE) {
        snprintf(error_buf, sizeof(error_buf), "Cannot open directory: %s", path_utf8);
        return -1;
    }
    size_t pos = 0;
    do {
        if (strcmp(ffd.cFileName, ".") == 0 || strcmp(ffd.cFileName, "..") == 0) {
            continue;
        }
        size_t len = strlen(ffd.cFileName);
        if (pos + len + 2 > sizeof(list_buf)) break;
        if (pos > 0) list_buf[pos++] = '\n';
        memcpy(list_buf + pos, ffd.cFileName, len);
        pos += len;
    } while (FindNextFile(hFind, &ffd) != 0);
    FindClose(hFind);
    list_buf[pos] = '\0';
#else
    DIR* d = opendir(path_utf8);
    if (!d) {
        snprintf(error_buf, sizeof(error_buf), "Cannot open directory: %s", path_utf8);
        return -1;
    }
    struct dirent* entry;
    size_t pos = 0;
    while ((entry = readdir(d)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        size_t len = strlen(entry->d_name);
        if (pos + len + 2 > sizeof(list_buf)) break;
        if (pos > 0) list_buf[pos++] = '\n';
        memcpy(list_buf + pos, entry->d_name, len);
        pos += len;
    }
    closedir(d);
    list_buf[pos] = '\0';
#endif
    return 0;
}

moonbit_string_t fs_get_list_result(void) {
    return utf8_to_moonbit_string(list_buf);
}

// ── Write file ──
int fs_write_file(moonbit_string_t path_utf16, moonbit_string_t content_utf16) {
    if (utf16_to_utf8(path_utf16, path_utf8, sizeof(path_utf8)) != 0) {
        snprintf(error_buf, sizeof(error_buf), "Path conversion failed");
        return -1;
    }
    // Convert content from UTF-16 to UTF-8
    char content_utf8[65536] = {0};
    if (utf16_to_utf8(content_utf16, content_utf8, sizeof(content_utf8)) != 0) {
        snprintf(error_buf, sizeof(error_buf), "Content conversion failed");
        return -1;
    }
    FILE* f = fopen(path_utf8, "wb");
    if (!f) {
        snprintf(error_buf, sizeof(error_buf), "Cannot write file: %s", path_utf8);
        return -1;
    }
    size_t len = strlen(content_utf8);
    if (fwrite(content_utf8, 1, len, f) != len) {
        snprintf(error_buf, sizeof(error_buf), "Write failed: %s", path_utf8);
        fclose(f);
        return -1;
    }
    fclose(f);
    return 0;
}

// ── Delete file ──
int fs_delete_file(moonbit_string_t path_utf16) {
    if (utf16_to_utf8(path_utf16, path_utf8, sizeof(path_utf8)) != 0) {
        snprintf(error_buf, sizeof(error_buf), "Path conversion failed");
        return -1;
    }
    if (remove(path_utf8) != 0) {
        snprintf(error_buf, sizeof(error_buf), "Cannot delete file: %s", path_utf8);
        return -1;
    }
    return 0;
}

// ── File exists ──
int fs_file_exists(moonbit_string_t path_utf16) {
    if (utf16_to_utf8(path_utf16, path_utf8, sizeof(path_utf8)) != 0) {
        return 0;
    }
    FILE* f = fopen(path_utf8, "rb");
    if (f) {
        fclose(f);
        return 1;
    }
    return 0;
}