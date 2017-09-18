#include <QPluginLoader>
#include <OtherLibrary.h>
#include <SomePluginInterface.h>

#include <QCoreApplication>
#include <QDebug>

int printMessage()
{
    QPluginLoader loader("SomePlugin");
    SomePluginInterface *interface = qobject_cast<SomePluginInterface*>(loader.instance());

    int result = 0;

    if(interface)
        interface->printMessage(OtherLibrary().message());
    else
        result = 1;

    return result;
}
