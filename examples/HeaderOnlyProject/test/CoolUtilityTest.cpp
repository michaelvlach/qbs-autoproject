#include <QTest>
#include <CoolUtility.h>

class CoolUtilityTest : public QObject
{
    Q_OBJECT
private slots:
    void printMessage()
    {
        coolutility::CoolUtility utility;
        QCOMPARE(utility.makeString("Hello world"), std::string("Hello world"));
    }
};

QTEST_APPLESS_MAIN(CoolUtilityTest)

#include "CoolUtilityTest.moc"
