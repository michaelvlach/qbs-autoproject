#pragma once

#include <Common.h>

#ifdef OTHERLIBRARY
#  define OTHERLIBRARY_SHARED EXPORT
#else
#  define OTHERLIBRARY_SHARED IMPORT
#endif

class OTHERLIBRARY_SHARED OtherLibrary
{
public:
    const char *message() const;
};
