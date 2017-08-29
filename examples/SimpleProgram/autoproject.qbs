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
            function createDocProject(dir) { return { name: FileInfo.baseName(rootDir) + "Doc", path: makePath(dir, documentationDirectory), qtDeps: [], deps: [], conf: "" }; }
            function createProject(dir) { return { name: FileInfo.baseName(rootDir), path: dir, qtDeps: [], files: getProjectSourceFiles(dir), deps: [], includes: getProjectIncludes(files), headers: getProjectHeaders(files), doc: createDocProject(dir), test: createTestProject(dir), subprojects: [] }; }
            function createTestProject(dir) { return { name: FileInfo.baseName(rootDir) + "Test", path: makePath(dir, testDirectory), qtDeps: [], deps: [], files: [], includes: [] }; }
            function getFilesInDirectory(dir) { File.directoryEntries(dir, File.Files); }
            function getProjectDirectories(dir) { return [dir].concat(prependPath(dir, additionalDirectories)); }
            function getProjectFiles(dir) { var files = []; var dirs = getProjectDirectories(dir); for(var i in dirs) files = files.concat(prependPath(dirs[i], getFilesInDirectory(dirs[i]))); return files; }
            function getProjectIncludes(files) { var includes = []; for(var i in files) includes = includes.concat(getRegexResults(readFile(files[i]), /#include [<|"](.*)[>|"]/g)); return removeDuplicates(includes); }
            function getProjectHeaders(files) { var headers = []; for(var i in files) if(isHeader(files[i])) headers.push(FileInfo.baseName(files[i])); return removeDuplicates(headers); }
            function getProjectSourceFiles(dir) { return getProjectFiles(dir).filter(function(element) { return isHeader(file) || isSource(file); }); }
            function getRegexResults(text, regex) { var results, regexResult = []; while(regexResult = regexp.exec(content)) results.push(regexResult[1]); return results; }
            function getSubDirs(dir) { return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot); }
            function hasExtension(file, extensions) { for(var i in extensions) if(file.endsWith("." + extensions[i])) return true; return false; }
            function isDoc(file) { return hasExtension(file, documentationExtensions); }
            function isDocConf(file) { return hasExtension(file, documentationConfigExtensions); }
            function isHeader(file) { return hasExtension(file, headerExtensions); }
            function isSource(file) { return hasExtension(file, sourceExtensions); }
            function makePath(path, subpath, subsubpath) { return FileInfo.joinPaths(path, subpath, subsubpath); }
            function makePath(path, subpath) { return FileInfo.joinPaths(path, subpath); }
            function prependPath(path, list) { var prependedList = []; return list.forEach(function(element) { this.push(FileInfo.joinPaths(path, element)); }, prependedList); }
            function readFile(file) { return TextFile(file, TextFile.ReadOnly).readAll(); }
            function removeDuplicates(ar) { return ar.filter(function(element, index, array) { return array.indexOf(element) == index; }); }

            var scannedProjects = [];

            function scanProjects(dir)
            {
                var project = createProject(dir);

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
