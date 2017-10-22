#include <PrintMessage.h>
#include <PluginInterface.h>
#include <QPluginLoader>

int main(int, char **)
{
    QPluginLoader loader("Plugin");
    PluginInterface *interface = qobject_cast<PluginInterface*>(loader.instance());
    return printMessage(interface ? interface->message() : "Failed to load message plugin.");
}
