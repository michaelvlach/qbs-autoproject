#include <CoolUtility.h>
#include <QDebug>
#include <QString>

int main(int argc [[maybe_unused]], char **argv [[maybe_unused]])
{
    qInfo() << QString::fromStdString(coolutility::CoolUtility().makeString("Hello world"));
    return 0;
}
