#pragma once

#include <QtPlugin>

class SomePluginInterface
{
public:
    virtual ~SomePluginInterface() noexcept = default;

    virtual void printMessage(const char *message) const = 0;
};

Q_DECLARE_INTERFACE(SomePluginInterface, "org.examples.SomePluginInterface");
