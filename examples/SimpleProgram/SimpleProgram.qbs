import qbs

Project
{
    name: "SimpleProgram"
    property string target: [qbs.targetOS, qbs.architecture, qbs.toolchain.join("-")].join("-")

    Product
    {
        type: "application"
        name: project.name + "App"

        Depends { name: "cpp"; }
        Depends { name: project.name + "Lib"; }

        targetName: project.name
        files: ["main.cpp"]

        Group
        {
            qbs.install: true
            qbs.installDir: project.target
            fileTagsFilter: ["application"]
        }
    }

    Product
    {
        type: "dynamiclibrary"
        name: project.name + "Lib"

        Export
        {
            Depends { name: "cpp"; }
        }

        Depends { name: "cpp" }
        cpp.defines: project.name.toUpperCase() + "_LIB"

        targetName: project.name
        files: ["SimpleProgram.cpp", "SimpleProgram.h"]

        property string str:
        {
            console.info(project.name.toUpperCase() + "_LIB")
        }

        Group
        {
            qbs.install: true
            qbs.installDir: project.target
            fileTagsFilter: ["dynamiclibrary"]
        }
    }

    Product
    {
        type: "application"
        name: project.name + "Test"

        Depends { name: "cpp"; }
        Depends { name: "Qt"; submodules: ["core", "testlib"]; }
        Depends { name: project.name + "Lib" }

        files: ["SimpleProgramTest.cpp", "SimpleProgramTest.h"]

        Group
        {
            qbs.install: true
            qbs.installDir: project.target
            fileTagsFilter: ["application"]
        }
    }

    Product
    {
        type: "qch"
        name: project.name + "Doc"

        Depends { name: "Qt"; submodules: [ "core" ]; }

        builtByDefault: false
        files: ["SimpleProgram.qdoc"]

        Group
        {
            files: "SimpleProgram.qdocconf"
            fileTags: "qdocconf-main"
        }

        Group
        {
            fileTagsFilter: ["qdoc-output"]
            qbs.install: true
            qbs.installDir: "/doc"
            qbs.installSourceBase: Qt.core.qdocOutputDir
        }

        Group
        {
            fileTagsFilter: ["qch"]
            qbs.install: true
            qbs.installDir: "/doc"
        }
    }
}
