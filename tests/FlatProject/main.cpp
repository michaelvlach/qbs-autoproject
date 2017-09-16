#include <Library.h>
#include <OtherLibrary.h>

int main(int argc [[maybe_unused]], char **argv [[maybe_unused]])
{
    Library().printMessage(OtherLibrary().message());
    return 0;
}
