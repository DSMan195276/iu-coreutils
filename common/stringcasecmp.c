
#include <ctype.h>

int stringcasecmp(const char *s1, const char *s2)
{
    for (; *s1 && *s2; s1++, s2++)
        if (toupper(*s1) != toupper(*s2))
            return 1;

    if (*s1 || *s2)
        return 1;

    return 0;
}

