#include "Library.h"

#include <QDebug>

void Library::printMessage(const char *message) const
{
    qInfo() << message;
}
