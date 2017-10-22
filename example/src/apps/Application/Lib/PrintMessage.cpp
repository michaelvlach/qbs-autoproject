#include "PrintMessage.h"

#include <QDebug>
#include <QString>

bool PrintMessage::printMessage(const QString &message)
{
    qDebug() << message;
    return !message.isEmpty();
}
