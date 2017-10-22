#pragma once

#include <QtPlugin>
#include <QString>

class PluginInterface
{
public:
    virtual QString message() const = 0;
};

Q_DECLARE_INTERFACE(PluginInterface, "org.examples.plugininterface");
