import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: FileInfo.baseName(sourceDirectory)
    id: autoproject

    property path autoprojectFileDirectory: ""
    property path rootDirectory: sourceDirectory.replace(autoprojectFileDirectory, "")
    property path autoprojectsDirectory: "autoprojects"
    property path targetDirectory: [qbs.targetOS, qbs.architecture, qbs.toolchain.join("-")].join("-")
    property path testDirectory: "test"
    property path includeDirectory: "include"
    property path qtIncludeDirectory: "C:/Qt/5.10.0/msvc2017_64/include/"
    property path documentationDirectory: "doc"
    property stringList additionalDirectories: ["private", "resources"]
    property stringList ignoredDirectories: [autoprojectsDirectory]
    property stringList headerExtensions: ["h"]
    property stringList sourceExtensions: ["cpp"]
    property stringList documentationExtensions: ["qdoc"]
    property stringList documentationConfigExtensions: ["qdocconf"]
    property stringList additionalExtensions: ["ui", "rc"]

    property var externalModules:
    {
        return { ModuleName: "path/to/include",
                 OtherModule: "path/to/include" }
    }

    Probe
    {
        id: qtscanner
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
            function getSubDirs(dir) { return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot); }
            function getFilesInDirectory(dir) { File.directoryEntries(dir, File.Files); }
            function makePath(dir, subdir, file) { return FileInfo.joinPaths(dir, subdir, file); }
            function makePath(dir, subdir) { return FileInfo.joinPaths(dir, subdir); }
            function hasExtension(file, extensions) { for(var i in extensions) if(file.endsWith("." + extensions[i])) return true; return false; }
            function isHeader(file) { return hasExtension(file, headerExtensions); }
            function isSource(file) { return hasExtension(file, sourceExtensions); }
            function isDoc(file) { return hasExtension(file, documentationExtensions); }
            function isDocConf(file) { return hasExtension(file, documentationConfigExtensions); }
            function readFile(file) { return TextFile(file, TextFile.ReadOnly).readAll(); }
            function getRegexResults(text, regex) { var results, regexResult = []; while(regexResult = regexp.exec(content)) results.push(regexResult[1]); return results; }
            function removeDuplicates(ar) { return ar.filter(function(element, index, array) { return array.indexOf(element) == index; }); }

            var scannedProjects = [];

            function scanProjects(rootDir)
            {
                var project = {}
                project["name"] = FileInfo.baseName(rootDir);
                project["path"] = rootDir;
                project["include"] = [];
                project["headers"] = [];
                project["sources"] = [];
                project["doc"] = {};
                project["test"] = {};

                var files = getFilesInDirectory(rootDir);

                for(var i in files)
                {
                    var file = files[i];

                    if(isHeader(file))
                        project["headers"].push(file);
                    else if(isSource(file))
                        project["sources"].push(file);
                    else
                        continue;

                    project["include"] = removeDuplicates(project["include"].concat(getRegexResults(readFile(makePath(rootDir, file), /#include [<|"](.*)[>|"]/g))));
                }

                var dirs = getSubDirs(rootDir);

                for(var i in dirs)
                {
                    var dir = dirs[i];

                    if(ignoredDirectories.contains(dir))
                        continue;
                    else if(additionalDirectories.contains(dir))
                    {
                        //TODO: Call above with the project object and append the path...
                    }
                    else if(dir == includeDirectory)
                    {
                        //TODO
                    }
                    else if(dir == testDirectory)
                    {
                        var test = {};
                        test["include"] = [];
                        test["headers"] = [];
                        test["sources"] = [];
                        files = getFilesInDirectory(makePath(rootDir, testDirectory));

                        for(var i in files)
                        {
                            var file = files[i];

                            if(isHeader(file))
                                test["headers"].push(file);
                            else if(isSource(file))
                                test["sources"].push(file);
                            else
                                continue;

                            test["include"] = removeDuplicates(test["include"].concat(getRegexResults(readFile(makePath(rootDir, testDirectory, file), /#include [<|"](.*)[>|"]/g))));
                        }
                    }
                    else if(dir == documentationDirectory)
                    {
                        var doc = {};
                        doc["docs"] = [];
                        doc["docconf"] = "";
                        files = getFilesInDirectory(makePath(rootDir, documentationDirectory));

                        for(var i in files)
                        {
                            var file = files[i];

                            if(isDoc(file))
                                doc["docs"].push(file);
                            else if(isDocConf(file))
                                doc["docconf"].push(file);
                        }
                    }
                    else
                        project.subProjects.push(scannedProjects(FileInfo.joinPaths(rootDir, dir)));
                }


                return project;
            }

            projects = scannedProjects;
        }
    }

    references: projectscanner.projects
}
