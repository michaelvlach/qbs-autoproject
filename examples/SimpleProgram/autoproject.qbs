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
    property stringList ignoredDirectories: []
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
            function makePath(dir, subdir) { return FileInfo.joinPaths(dir, subdir); }

            var scannedProjects = [];


            projects = scannedProjects;
        }
    }

    references: projectscanner.projects
}
