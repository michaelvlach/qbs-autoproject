import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: FileInfo.baseName(sourceDirectory)
    id: autoproject

    //-------------//
    //CONFIGURATION//
    //-------------//
    property path pathToRoot: "examples/FlatProject"
    property path autoprojectsDirectory: ".autoproject"
    property path targetDir: [qbs.targetOS, qbs.architecture, qbs.toolchain.join("-")].join("-")
    property stringList additionalProjectDirs: ["src", "include", "doc", "test", "private", "resources"]
    property stringList headerExtensions: ["h"]
    property stringList sourceExtensions: ["cpp"]
    property path qtIncludeDirectory: "C:/Qt/5.10.0/msvc2017_64/include/"
    property stringList ignoredDirs: [autoprojectsDirectory, "build", "bin"]
    property stringList ignoredFiles: [".gitignore", "*.qbs", "*.user", "LICENSE", "*.md", "*.txt"]

    property var productRules:
    {
        //files: [], additionalFiles: [], additionalDirectories: [], regex: "", item: ""
        //In-built items: CppApplication, DynamicLibrary, StaticLibrary, Product, Documentation
        return {
            Test:       { files: ["*Test.cpp"], additionalFiles: ["*Test.h", "*Mock.h"], additionalDirectories: ["mocks"], item: "CppApplication" },
            DLib:       { files: ["*.h"], regex: "class.*SHARED ", additionalFiles: ["*.cpp", "*.h"], item: "DynamicLibrary" },
            App:        { files: ["main.cpp"], additionalFiles: ["*.cpp", "*.h"], item: "CppApplication" },
            Interfaces: { files: ["*.h"], regex: "class.*Interface|__declspec\\(dllexport\\)", additionalFiles: ["*.h"], item: "Product" },
            DocGen:     { files: ["*.qdocconf"], item: "Documentation" },
            Docs:       { files: ["*.qdoc"], item: "Product" },
            SLib:       { additionalFiles: ["*.cpp", "*.h"], item: "StaticLibrary" }
        };
    }

    property var modules:
    {
        //includeDirectory: "", files: []
        return {
            cinject: { files: ["cinject.h"] },
            cppcommandline: { files: ["cppcommandline.h"] },
            qtestbdd: { files: ["qtestbdd.h"] },
            gtestbdd: { files: ["gtestbdd.h"] },
            gtest: { files: ["gtest/gtest.h"] }
        };
    }

    //--------------------//
    //END OF CONFIGURATION//
    //--------------------//
    property path root:
    {
        if(FileInfo.isAbsolutePath(pathToRoot))
            return pathToRoot;
        else if(sourceDirectory.contains(pathToRoot))
            return sourceDirectory.replace(pathToRoot, "");
        else
            return FileInfo.joinPaths(sourceDirectory, pathToRoot);
    }

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
            function getProduct(project, product)
            {
                if(!project["products"][product])
                    project["products"][product] = {files: []};

                return project["products"][product];
            }

            function readFile(file)
            {
                return TextFile(file).readAll();
            }

            function hasMatch(file, pattern)
            {
                return readFile(file).search(pattern) != -1;
            }

            function scan(dir)
            {
                var files = File.directoryEntries(dir, File.Files).filter(function(filename)
                {
                    for(var i in ignoredFiles)
                        if(ignoredFiles[i].startsWith("*") ? filename.endsWith(ignoredFiles[i].substring(1)) : filename == ignoredFiles[i])
                            return false;
                    return true;
                });

                var project = { name: FileInfo.baseName(dir), path: dir, products: {} };

                for(var i in productRules)
                {
                    var rule = productRules[i];
                    if(!rule["files"] && !project["products"][i])
                        project["products"][i] = {files: []};
                    else
                    {
                        files = files.filter(function(filename)
                        {
                            for(var j in rule["files"])
                            {
                                var pattern = rule["files"][j];
                                if(pattern.startsWith("*") ? filename.endsWith(pattern.substring(1)) : filename == pattern)
                                {
                                    if(rule["regex"] && !hasMatch(FileInfo.joinPaths(dir, filename), rule["regex"]))
                                        return true;

                                    var product = getProduct(project, i);
                                    product["files"].push(FileInfo.joinPaths(dir, filename));
                                    return false;
                                }
                                else
                                    return true;
                            }
                        });
                    }
                }

                if(files)
                {
                    for(var i in project["products"])
                    {
                        files = files.filter(function(filename)
                        {
                            for(var j in productRules[i]["additionalFiles"])
                            {
                                var pattern = productRules[i]["additionalFiles"][j];
                                if(pattern.startsWith("*") ? filename.endsWith(pattern.substring(1)) : filename == pattern)
                                {
                                    project["products"][i]["files"].push(FileInfo.joinPaths(dir, filename));
                                    return false;
                                }
                                else
                                    return true;
                            }
                        });
                    }
                }

                return project;
            }

            var proj = scan(root);

            console.info("Name: " + proj["name"]);
            console.info("Name: " + proj["path"]);

            for(var i in proj["products"])
            {
                console.info(i + ": " + proj["products"][i]["files"]);
            }
        }
    }

    references: projectscanner.projects
}
