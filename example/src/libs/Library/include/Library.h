#pragma once

#include <Common.h>
#include <QString>

#ifdef LIBRARY
#  define LIBRARY_SHARED EXPORT
#else
#  define LIBRARY_SHARED IMPORT
#endif

class LIBRARY_SHARED Library
{
public:
    QString prepareMessage(const char *message) const;
};
