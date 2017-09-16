#pragma once

#include <Common.h>

#ifdef LIBRARY
#  define LIBRARYSHARED EXPORT
#else
#  define LIBRARYSHARED IMPORT
#endif

class LIBRARYSHARED Library
{
public:
    void printMessage(const char *message) const;
};
