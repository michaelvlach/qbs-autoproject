#include <QTest>
#include <PrintMessage.h>

class ApplicationLibTest : public QObject
{
    Q_OBJECT
private slots:
    void printMessageTest()
    {
        QCOMPARE(printMessage("Hello world"), true);
        QCOMPARE(printMessage(""), false);
    }
};

QTEST_APPLESS_MAIN(ApplicationLibTest)

#include "ApplicationLibTest.moc"
