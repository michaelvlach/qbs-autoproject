#include "SomePlugin.h"

#include <Library.h>

void SomePlugin::printMessage(const char *message) const
{
    Library().printMessage(message);
}