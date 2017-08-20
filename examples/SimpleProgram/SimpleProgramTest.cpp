#include "SimpleProgramTest.h"

#include <QTest>
#include "SimpleProgram.h"

void SimpleProgramTest::exec()
{
    SimpleProgram program;
    QCOMPARE(program.exec(), 0);
}

QTEST_APPLESS_MAIN(SimpleProgramTest)
