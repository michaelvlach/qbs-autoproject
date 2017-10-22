#include "Plugin.h"

#include <Library.h>
#include <MyLibrary.h>

QString Plugin::message() const
{
    return Library().prepareMessage(MyLibrary().message());
}
