#pragma once

#include "SimpleProgramGlobal.h"

class SIMPLEPROGRAM_SHARED SimpleProgram
{
public:
    SimpleProgram() = default;
    SimpleProgram(int argc, char **argv);

    int exec();
};
