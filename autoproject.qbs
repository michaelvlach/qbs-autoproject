import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: FileInfo.baseName(sourceDirectory)
    id: autoproject

    //------------//
    //ONFIGURATION//
    //------------//
    property path autoprojectFileDirectory: "" //relative to desired project root
    property path autoprojectsDirectory: ".autoproject"
    property stringList sourceExtensions: ["cpp", "h"]
    property path qtIncludeDirectory: "C:/Qt/5.10.0/msvc2017_64/include/"
    property stringList ignoredDirectories: []

    property var rules:
    {
        return {
            TestApplication: { directories: ["test"],                      patterns: []             },
            Application:     { directories: ["", "src", "private"],        patterns: ["main.cpp"]   },
            SharedLibrary:   { directories: ["src", "private", "include"], patterns: []             },
            Interfaces:      { directories: [],                            patterns: [".h"]         },
            DocGen:          { directories: ["doc"],                       patterns: [".qdocconf"]  },
            Doc:             { directories: ["doc"],                       patterns: [".qdoc"]      }
        };
    }

    property var modules:
    {
        return {
            cinject:        { includeDirectory: "", files: ["cinject.h"] },
            cppcommandline: { includeDirectory: "", files: ["cppcommandline.h"] },
            qtestbdd:       { includeDirectory: "", files: ["qtestbdd.h"] },
            gtestbdd:       { includeDirectory: "", files: ["gtestbdd.h"] },
            gtest:          { includeDirectory: "", files: ["gtest/gtest.h"] }
        };
    }

    //Advanced
    property path rootDir: sourceDirectory.replace(autoprojectFileDirectory, "")
    property path targetDir: [qbs.targetOS, qbs.architecture, qbs.toolchain.join("-")].join("-")

    //--------------------//
    //END OF CONFIGURATION//
    //--------------------//

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
            function getIgnoredDirs()
            {
                var dirs = [autoprojectsDirectory, qbs.installRoot];
                for(var i in modules)
                {
                    var moduleDirectory = modules[i]["includeDirectory"];
                    if(!dirs.contains(moduleDirectory))
                        dirs.push(moduleDirectory);
                }
                return dirs;
            }

            function getAdditionalDirs()
            {
                var dirs = [];
                for(var i in rules)
                {
                    var ruleDirs = rules[i]["directories"];
                    for(var j in ruleDirs)
                    {
                        var dir = ruleDirs[j];
                        if(dir && !dirs.contains(dir))
                            dirs.push(dir);
                    }
                }
                return dirs;
            }

            function scanProjects(dir)
            {
                var found = [];
                var dirs = File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);
                for(var i in dirs)
                {
                    var d = dirs[i];
                    if(ignoredDirs.contains(d))
                        continue;

                    if(!additionalDirs.contains(d))
                    {
                        if(found.contains(d))
                            found.remove(d);
                        else
                        {
                            found.push(d);
                        }
                    }


                }
            }

            function scan(dir)
            {
                var foundProjects = scanProjects(dir);
            }

            var ignoredDirs = getIgnoredDirs();
            var additionalDirs = getAdditionalDirs();
            var foundProjects = scan(rootDirectory);
            projects = foundProjects;
        }
    }

    references: projectscanner.projects
}
