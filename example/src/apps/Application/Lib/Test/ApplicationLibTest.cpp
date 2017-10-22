#include <QTest>
#include <PrintMessage.h>

class ApplicationLibTest : public QObject
{
    Q_OBJECT
private slots:
    void printMessage()
    {
        QCOMPARE(printMessage("Hello world"), true);
        QCOMPARE(printMessage(""), false);
    }
};

QTEST_APPLESS_MAIN(ApplicationTest)

#include "ApplicationLibTest.moc"
