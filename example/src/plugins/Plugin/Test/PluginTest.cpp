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
        QString pluginName = "Plugin";
#ifdef QT_DEBUG
        pluginName.append("d");
#endif
        QPluginLoader loader(pluginName);
        PluginInterface *interface = qobject_cast<PluginInterface*>(loader.instance());
        QVERIFY(interface);
        QCOMPARE(QString("Hello world"), QString(interface->message()));
    }
};

QTEST_APPLESS_MAIN(PluginTest)

#include "PluginTest.moc"
