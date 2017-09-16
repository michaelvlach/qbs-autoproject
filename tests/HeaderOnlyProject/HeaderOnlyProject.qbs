import qbs

Project
{
    Product
    {
        Export
        {
            Depends { name: "cpp" }
            cpp.includePaths: ["include"]
        }

        name: "CoolUtility"

        Group
        {
            qbs.install: true
            qbs.installDir: "include"
            files: ["include/CoolUtility.h"]
        }
    }

    QtApplication
    {
        Depends { name: "CoolUtility" }
        Depends { name: "Qt.testlib" }

        name: "CoolUtilityTest"
        files: ["test/CoolUtilityTest.cpp"]

        Group
        {
            qbs.install: true
            fileTagsFilter: "application"
        }
    }

    QtApplication
    {
        Depends { name: "CoolUtility" }
        Depends { name: "Qt.core" }

        name: "CoolUtilityExample"
        files: ["example/main.cpp"]
        cpp.cxxLanguageVersion: "c++1z"

        Group
        {
            qbs.install: true
            fileTagsFilter: "application"
        }
    }
}
