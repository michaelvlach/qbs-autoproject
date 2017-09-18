#include <QTest>
#include <QPluginLoader>
#include <SomePluginInterface.h>

class SomePluginTest : public QObject
{
    Q_OBJECT
private slots:
    void printMessage()
    {
        QPluginLoader loader("SomePlugin");
        SomePluginInterface *interface = qobject_cast<SomePluginInterface*>(loader.instance());
        QVERIFY(interface);
        interface->printMessage("Hello world");
    }
};

QTEST_APPLESS_MAIN(SomePluginTest)

#include "SomePluginTest.moc"
