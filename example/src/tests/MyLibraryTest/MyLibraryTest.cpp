#include <QTest>
#include <QString>
#include <MyLibrary.h>

class MyLibraryTest : public QObject
{
    Q_OBJECT
private slots:
    void message()
    {
        QCOMPARE(QString(MyLibrary().message()), QString("Hello world"));
    }
};

QTEST_APPLESS_MAIN(MyLibraryTest)

#include "MyLibraryTest.moc"
