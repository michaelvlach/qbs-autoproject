import qbs

Project
{
    name: "TidyProject"
    id: tidyproject
    property path targetDir: [qbs.targetOS, qbs.toolchain.join("-")].join("-")

    Project
    {
        name: "Libs"
        
        Project
        {
            name: "Library"

            DynamicLibrary
            {
                Export
                {
                    Depends { name: "cpp" }
                    Depends { name: "Qt.core" }
                    cpp.includePaths: ["include", "include/Library"]
                }

                name: "Library"
                Depends { name: "cpp" }
                Depends { name: "Qt.core" }
                cpp.includePaths: ["include", "include/Library"]
                files: ["include/Library/Library.h", "src/libs/Library/Library.cpp"]

                Group
                {
                    qbs.install: true
                    qbs.installDir: tidyproject.targetDir
                    fileTagsFilter: "dynamiclibrary"
                }
            }

            QtApplication
            {
                Depends { name: "Library" }
                Depends { name: "Qt.testlib" }

                name: "LibraryTest"
                files: ["src/libs/Library/test/LibraryTest.cpp"]

                Group
                {
                    qbs.install: true
                    qbs.installDir: tidyproject.targetDir
                    fileTagsFilter: "application"
                }
            }
        }

        Project
        {
            name: "OtherLibrary"

            DynamicLibrary
            {
                Export
                {
                    Depends { name: "cpp" }
                    cpp.includePaths: ["include", "include/OtherLibrary"]
                }

                name: "OtherLibrary"
                Depends { name: "cpp" }
                cpp.includePaths: ["include", "include/OtherLibrary"]
                files: ["include/OtherLibrary/OtherLibrary.h", "src/libs/OtherLibrary/OtherLibrary.cpp"]

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
                Depends { name: "Qt.testlib" }

                name: "OtherLibraryTest"
                files: ["src/libs/OtherLibrary/test/OtherLibraryTest.cpp"]

                Group
                {
                    qbs.install: true
                    qbs.installDir: tidyproject.targetDir
                    fileTagsFilter: "application"
                }
            }
        }
    }

    Project
    {
        name: "Apps"
        
        Project
        {
            name: "Application"
        
            QtApplication
            {
                Depends { name: "Interfaces" }
                Depends { name: "OtherLibrary" }

                Export
                {
                    Depends { name: "cpp" }
                    Depends { name: "Interfaces" }
                    Depends { name: "OtherLibrary" }
                    cpp.includePaths: ["src/apps/Application"]
                }
                
                name: "Application"
                files: ["src/apps/Application/main.cpp", "src/apps/Application/PrintMessage.h"]
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
                Depends { name: "Application" }
                Depends { name: "Qt.testlib" }

                name: "ApplicationTest"
                files: ["src/apps/Application/test/ApplicationTest.cpp"]
                cpp.cxxLanguageVersion: "c++1z"

                Group
                {
                    qbs.install: true
                    qbs.installDir: tidyproject.targetDir
                    fileTagsFilter: "application"
                }
            }
        }
    }
    
    Project
    {
        name: "Plugins"
        
        Project
        {
            name: "SomePlugin"
        
            DynamicLibrary
            {
                Export
                {
                    Depends { name: "cpp" }
                    Depends { name: "Qt.core" }
                    Depends { name: "Interfaces" }
                }
            
                Depends { name: "cpp" }
                Depends { name: "Qt.core" }
                Depends { name: "Interfaces" }
                Depends { name: "Library" }

                name: "SomePlugin"
                files: ["src/plugins/SomePlugin/SomePlugin.h", "src/plugins/SomePlugin/SomePlugin.cpp", "src/plugins/SomePlugin/SomePlugin.json"]
                
                Group
                {
                    qbs.install: true
                    qbs.installDir: tidyproject.targetDir
                    fileTagsFilter: "dynamiclibrary"
                }
            }
            
            QtApplication
            {
                Depends { name: "SomePlugin"; cpp.link: false }
                Depends { name: "Qt.testlib" }

                name: "SomePluginTest"
                files: ["src/plugins/SomePlugin/test/SomePluginTest.cpp"]

                Group
                {
                    qbs.install: true
                    qbs.installDir: tidyproject.targetDir
                    fileTagsFilter: "application"
                }
            }
        }
    }
    
    Product
    {
        name: "Interfaces"
        files: ["include/Interfaces/*.h"]

        Export
        {
            Depends { name: "cpp" }
            cpp.includePaths: ["include/Interfaces"]
        }
    }

    Product
    {
        Depends { name: "Qt.core" }
        builtByDefault: false
        type: "qch"
        name: "Documentation"
        files: ["doc/TidyProject.qdoc",
                "doc/SomePluginInterface.qdoc",
                "src/apps/Application/doc/Application.qdoc",
                "src/libs/Library/doc/Library.qdoc",
                "src/libs/OtherLibrary/doc/OtherLibrary.qdoc",
                "src/plugins/SomePlugin/doc/SomePlugin.qdoc"]

        Group
        {
            files: ["doc/*.qdocconf"]
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
