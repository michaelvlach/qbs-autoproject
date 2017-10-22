#include <QTest>
#include <QPluginLoader>
#include <QString>
#include <PluginInterface.h>

class PluginTest : public QObject
{
    Q_OBJECT
private slots:
    void printMessage()
    {
        QPluginLoader loader("Plugin");
        PluginInterface *interface = qobject_cast<PluginInterface*>(loader.instance());
        QVERIFY(interface);
        QCOMPARE(QString("Hello world"), interface->message("Hello world"));
    }
};

QTEST_APPLESS_MAIN(PluginTest)

#include "PluginTest.moc"
