#include "PrintMessage.h"

#include <QDebug>
#include <QString>

bool printMessage(const QString &message)
{
    qDebug() << message;
    return message.isEmpty();    
}
