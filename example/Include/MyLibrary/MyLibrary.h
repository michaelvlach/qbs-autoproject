#pragma once

#include <Common.h>

#ifdef MYLIBRARY
#  define MYLIBRARY_SHARED EXPORT
#else
#  define MYLIBRARY_SHARED IMPORT
#endif

class MYLIBRARY_SHARED MyLibrary
{
public:
    const char *message() const;
};
