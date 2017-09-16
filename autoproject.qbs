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
            function makePath(dir, subdir)
            {
                return FileInfo.joinPaths(dir, subdir);
            }

            function getSubDirs(dir)
            {
                return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);
            }

            function getSubDirsRecursively(dir)
            {
                var dirs = !isIgnored(dir) && !isAdditional(dir) ? [dir] : [];
                var subdirs = getSubDirs(dir);
                for(var i in subdirs)
                {
                    var subdir = makePath(dir, subdirs[i]);
                    if(!isIgnored(subdir))
                        dirs = dirs.concat(getSubDirsRecursively(subdir));
                }
                return dirs;
            }

            function removeDuplicateBaseNames(list)
            {
                var baseNames = [];
                list.forEach(function(element)
                {
                    this.push(FileInfo.baseName(element));
                }, baseNames);

                return list.filter(function(element)
                {
                    var baseName = FileInfo.baseName(element);
                    return this.indexOf(baseName) == this.lastIndexOf(baseName);
                }, baseNames);
            }

            function isIgnored(dir)
            {
                for(var i in ignoredDirs)
                {
                    var ignoredDir = ignoredDirs[i];
                    if(FileInfo.isAbsolutePath(ignoredDir))
                    {
                        if(dir != ignoredDir)
                            return true;
                    }
                    else if(dir.endsWith("/" + ignoredDir))
                        return true;
                }

                return false;
            }

            function isAdditional(dir)
            {
                for(var i in additionalDirs)
                {
                    var additionalDir = additionalDirs[i];
                    if(element.endsWith("/" + additionalDir))
                        return true;
                }

                return false;
            }

            function getProjectRoots(root)
            {
                return removeDuplicateBaseNames(getSubDirsRecursively(root));
            }

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
                var projectRoots = getProjectRoots(rootDir);
            }

            function scan(dir)
            {
                var foundProjects = scanProjects(dir);
            }

            var ignoredDirs = getIgnoredDirs();
            var additionalDirs = getAdditionalDirs();
            var foundProjects = scan(rootDir);
            projects = foundProjects;
        }
    }

    references: projectscanner.projects
}
