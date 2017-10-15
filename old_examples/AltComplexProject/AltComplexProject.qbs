import qbs

Project
{
    name: "AltComplexProject"
    id: tidyproject
    property path targetDir: [qbs.targetOS, qbs.toolchain.join("-")].join("-")

    Project
    {
        name: "Apps"
        
        DynamicLibrary
        {
            Export
            {
                Depends { name: "cpp" }
                Depends { name: "Qt.core" }
                cpp.includePaths: ["include"]
            }

            name: "Library"
            Depends { name: "cpp" }
            Depends { name: "Qt.core" }
            cpp.includePaths: ["include"]
            files: ["include/Library.h", "src/Library/Library.cpp"]

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "dynamiclibrary"
            }
        }
        
        DynamicLibrary
        {
            Export
            {
                Depends { name: "cpp" }
                Depends { name: "Qt.core" }
                cpp.includePaths: ["include"]
            }

            name: "OtherLibrary"
            Depends { name: "cpp" }
            Depends { name: "Qt.core" }
            cpp.includePaths: ["include"]
            files: ["include/OtherLibrary.h", "src/OtherLibrary/OtherLibrary.cpp"]

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "dynamiclibrary"
            }
        }
        
        QtApplication
        {
            Depends { name: "OtherLibrary" }

            Export
            {
                Depends { name: "cpp" }
                Depends { name: "OtherLibrary" }
                cpp.includePaths: ["src/Application"]
            }
            
            name: "Application"
            files: ["src/Application/main.cpp", "src/Application/PrintMessage.h"]
            cpp.cxxLanguageVersion: "c++1z"

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "application"
            }
        }
        
        DynamicLibrary
        {
            Export
            {
                Depends { name: "cpp" }
                Depends { name: "Qt.core" }
                Depends { name: "Library"; cpp.link: false }
                cpp.includePaths: ["include"]
            }
        
            Depends { name: "cpp" }
            Depends { name: "Qt.core" }
            Depends { name: "Library" }

            name: "SomePlugin"
            files: ["src/Application/SomePlugin/SomePlugin.h", "src/Application/SomePlugin/SomePlugin.cpp", "src/Application/SomePlugin/SomePlugin.json"]
            
            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "dynamiclibrary"
            }
        }
    }
    
    Project
    {
        name: "Tests"

        QtApplication
        {
            Depends { name: "Library" }
            Depends { name: "Qt.testlib" }

            name: "LibraryTest"
            files: ["tests/Library/LibraryTest.cpp"]

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "application"
            }
        }
        
        QtApplication
        {
            Depends { name: "OtherLibrary" }
            Depends { name: "Qt.testlib" }

            name: "OtherLibraryTest"
            files: ["tests/OtherLibrary/OtherLibraryTest.cpp"]

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "application"
            }
        }
        
        QtApplication
        {
            Depends { name: "Application"; cpp.link: false }
            Depends { name: "Qt.testlib" }

            name: "ApplicationTest"
            files: ["tests/Application/ApplicationTest.cpp"]
            cpp.cxxLanguageVersion: "c++1z"

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "application"
            }
        }
        
        QtApplication
        {
            Depends { name: "SomePlugin"; cpp.link: false }
            Depends { name: "Qt.testlib" }

            name: "SomePluginTest"
            files: ["tests/SomePlugin/SomePluginTest.cpp"]

            Group
            {
                qbs.install: true
                qbs.installDir: tidyproject.targetDir
                fileTagsFilter: "application"
            }
        }
    }

    Product
    {
        Depends { name: "Qt.core" }
        builtByDefault: false
        type: "qch"
        name: "Documentation"
        files: ["AltComplexProject.qdoc",
                "include/SomePluginInterface.qdoc",
                "src/Application/Application.qdoc",
                "src/Library/Library.qdoc",
                "src/OtherLibrary/OtherLibrary.qdoc",
                "src/Application/SomePlugin/SomePlugin.qdoc"]

        Group
        {
            files: ["*.qdocconf"]
            fileTags: "qdocconf-main"
        }

        Group
        {
            fileTagsFilter: ["qdoc-output"]
            qbs.install: true
            qbs.installDir: "doc"
            qbs.installSourceBase: Qt.core.qdocOutputDir
        }

        Group
        {
            fileTagsFilter: ["qch"]
            qbs.install: true
            qbs.installDir: "doc"
        }
    }
}
