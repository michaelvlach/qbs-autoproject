#include "Plugin.h"

#include <Library.h>
#include <MyLibrary.h>

QString Plugin::message() const
{
    Library().prepareMessage(MyLibrary().message());
}
