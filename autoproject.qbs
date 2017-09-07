import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: FileInfo.baseName(sourceDirectory)
    id: autoproject

    //Configuration
    property path autoprojectFileDirectory: "" //relative to project root
    property path autoprojectsDirectory: "autoprojects"
    property stringList additionalProjectDirectories: ["include", "private", "resources", "src", "include", "doc", "test"]
    property stringList sourceExtensions: ["cpp", "h"]
    property var productTemplates:
    {
        var templates =
        {
            TestApplication: ["Test.h", "test.h", "Test.cpp", "test.cpp"],
            Application: ["main.cpp"],
            SharedLibrary: [".cpp"],
            Interfaces: [".h"],
            DocGenProduct: [".qdocconf"],
            DocProduct: [".qdoc"]
        };
        return templates;
    }
    property var externalModules:
    {
        var modules =
        {
            cinject: ["cinject.h"],
            cppcommandline: ["cppcommandline.h"],
            qtestbdd: ["qtestbdd.h"],
            gtestbdd: ["gtestbdd.h"],
            gtest: ["gtest/gtest.h"]
        };
        return modules;
    }

    //Advanced
    property path rootDirectory: sourceDirectory.replace(autoprojectFileDirectory, "")
    property path targetDirectory: [qbs.targetOS, qbs.architecture, qbs.toolchain.join("-")].join("-")
    property path qtIncludeDirectory: "C:/Qt/5.10.0/msvc2017_64/include/"
    property stringList ignoredDirectories: [autoprojectsDirectory]

    Probe
    {
        id: qtscanner
        condition: File.exists(qtIncludeDirectory)
        property var modules: {}

        configure:
        {
            function getSubDirs(dir) { return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot); }
            function getFilesInDirectory(dir) { File.directoryEntries(dir, File.Files); }
            function makePath(dir, subdir) { return FileInfo.joinPaths(dir, subdir); }
            function getQtModuleName(subdir) { return subdir.replace("Qt", "").toLowerCase() }

            var qtModules = {};
            var subdirs = getSubDirs(qtIncludeDirectory);

            for(var i in subdirs)
                qtModules[getQtModuleName(subdirs[i])] = getFilesInDirectory(makePath(qtIncludeDirectory, subdirs[i]));

            modules = qtModules;
        }
    }

    Probe
    {
        id: projectscanner
        property var projects: []

        configure:
        {
            //utility
            function prependPath(element, index, array) { array[index] = makePath(this, element); }
            function makePath(dir, sub) { return FileInfo.joinPaths(dir, sub); }
            function getFiles(dir) { return File.directoryEntries(dir, File.Files); }
            function getFilesWithPath(dir)
            {
                var files = getFiles(dir);
                files.forEach(prependPath, dir);
                return files;
            }
            function getProjectFiles(dir)
            {
                var files = getFilesWithPath(dir);
                for(var i in additionalProjectDirectories)
                    files = files.concat(getFilesWithPath(makePath(dir, additionalProjectDirectories[i])));
                return files;
            }

            var foundProjects = scan(rootDirectory);

            function scan(dir)
            {
                var project = {};
                project["products"] = [];
                var files = getProjectFiles(dir);

                for(var i in files)
                {
                    var file = files[i];

                    for(var template in productTemplates)
                    {
                        var patterns = productTemplates[template];

                        for(var j in patterns)
                        {
                            if(file.endsWith(patterns[j]))
                            {

                            }
                        }
                    }
                }

                return [];
            }

            projects = foundProjects;
        }
    }

    references: projectscanner.projects
}
