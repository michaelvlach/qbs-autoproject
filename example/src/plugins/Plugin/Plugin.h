#pragma once

#include <QObject>
#include <PluginInterface.h>

class Plugin : public QObject, public PluginInterface
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.examples.Plugin" FILE "Plugin.json")
    Q_INTERFACES(PluginInterface)
public:
    QString message() const override;
};
