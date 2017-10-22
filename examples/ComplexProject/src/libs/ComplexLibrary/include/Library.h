#pragma once

#include <Common.h>

#ifdef LIBRARY
#  define LIBRARYSHARED EXPORT
#else
#  define LIBRARYSHARED IMPORT
#endif

class LIBRARY_SHARED Library
{
public:
    void printMessage(const char *message) const;
};
