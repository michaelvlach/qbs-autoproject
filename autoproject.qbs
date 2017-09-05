import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: FileInfo.baseName(sourceDirectory)
    id: autoproject

    property path autoprojectFileDirectory: "" //relative to project root
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
            function createProject(dir) { return { name: FileInfo.baseName(rootDir), path: dir, qtDeps: [], files: getProjectSourceFiles(dir), deps: [], includes: getProjectIncludes(files), headers: getProjectHeaders(files), publicHeaders: [], publicIncludes: [], doc: createDocProject(dir), test: createTestProject(dir), subProjects: [] }; }
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
            scan(rootDirectory);

            function hasExtension(file, extensions)
            {
                for(var i in extensions)
                {
                    if(file.endsWith(extensions[i]))
                        return true;
                }
                return false;
            }

            function scan(dir)
            {
                var files = File.directoryEntries(dir, File.Files);
                var sources = [];
                var headers = [];
                var docs = [];
                var docConfigs = [];
                var miscFiles = [];

                for(var i in files)
                {
                    var file = files[i];
                    if(hasExtensions(file, sourceExtensions))
                        sources.push(file);
                    else if(hasExtension(file, headerExtensions))
                        headers.push(file);
                    else if(hasExtension(file, documentationExtensions))
                        docs.push(file);
                    else if(hasExtension(file, documentationConfigExtensions))
                        docConfigs.push(file);
                    else if(hasExtension(file, additionalExtensions))
                        miscFiles.push(file);
                }


            }

//            function scanDir(dir)
//            {
//                var project = createProject(dir);

//                var dirs = getSubDirs(dir);
//                var ignored = ignoredDirectories.concat(additionalDirectories);

//                for(var i in dirs)
//                {
//                    var subdir = dirs[i];

//                    if(ignored.contains(subdir))
//                        continue;
//                    else if(subdir == includeDirectory)
//                    {
//                        var subdirs = getSubDirs(makePath(dir, includeDirectory));
//                        project["publicHeaders"] = getProjectHeaders(makePath(dir, includeDirectory));

//                        for(var j in subdirs)
//                        {
//                            var sub = makePath(dir, subdir, subdirs[j]);
//                            project["subProjects"].push(scanProjects(sub));
//                        }
//                    }
//                    else
//                        project["subProjects"].push(scanProjects(sub));
//                }

//                return project;
//            }

            projects = scannedProjects;
        }
    }

    references: projectscanner.projects
}
