#pragma once

#include <SomePluginInterface.h>

class SomePlugin : public QObject, public SomePluginInterface
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.examples.SomePlugin" FILE "SomePlugin.json")
    Q_INTERFACES(SomePluginInterface)
public:
    void printMessage(const char *message) const override;
};
