#pragma once

#include <Common.h>
#include "LibraryInterface.h"

#ifdef LIBRARY
#  define LIBRARY_SHARED EXPORT
#else
#  define LIBRARY_SHARED IMPORT
#endif

class LIBRARY_SHARED Library : public LibraryInterface
{
public:
    void printMessage(const char *message) const override;
};
