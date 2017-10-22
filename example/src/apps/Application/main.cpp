#include <PrintMessage.h>
#include <PluginInterface.h>
#include <QPluginLoader>
#include <QDebug>

int main(int, char **)
{
    QString pluginName = "Plugin";
#ifdef QT_DEBUG
    pluginName.append("d");
#endif
    qDebug() << pluginName;
    QPluginLoader loader(pluginName);
    PluginInterface *interface = qobject_cast<PluginInterface*>(loader.instance());
    return printMessage(interface ? interface->message() : "Failed to load message plugin.");
}
