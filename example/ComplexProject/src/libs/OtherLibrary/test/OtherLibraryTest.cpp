#include <QTest>
#include <QString>
#include <OtherLibrary.h>

class OtherLibraryTest : public QObject
{
    Q_OBJECT
private slots:
    void message()
    {
		QCOMPARE(QString(OtherLibrary().message()), QString("Hello world"));
    }
};

QTEST_APPLESS_MAIN(OtherLibraryTest)

#include "OtherLibraryTest.moc"
