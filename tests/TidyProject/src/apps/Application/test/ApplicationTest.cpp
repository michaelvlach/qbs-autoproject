#include <QTest>
#include <PrintMessage.h>

class ApplicationTest : public QObject
{
    Q_OBJECT
private slots:
    void mainTest()
    {
        QCOMPARE(printMessage(), 0);
    }
};

QTEST_APPLESS_MAIN(ApplicationTest)

#include "ApplicationTest.moc"
