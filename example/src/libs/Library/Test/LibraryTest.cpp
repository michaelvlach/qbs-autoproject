#include <QTest>
#include <Library.h>

class LibraryTest : public QObject
{
    Q_OBJECT
private slots:
    void printMessage()
    {
        QCOMPARE(QString("Hello world"), Library().prepareMessage("Hello world"));
    }
};

QTEST_APPLESS_MAIN(LibraryTest)

#include "LibraryTest.moc"
