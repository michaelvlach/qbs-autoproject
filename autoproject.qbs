import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    name: FileInfo.baseName(sourceDirectory)
    property stringList headerExtensions: ["h"]
    property stringList sourceExtensions: ["cpp"]
    property stringList documentationExtensions: ["qdoc", "qdocconf"]
    property stringList additionalFileEtensions: ["rc", "ui"]
    property stringList additionalProjectDirectories: []
    property stringList ignoreDirs: []
    property stringList ignoreFiles: []
    property path autoprojectDir: "autoproject"
    property path qtIncludeRoot: "C:/Qt/5.10.0/msvc2017_64/include/"
    //END OF CONFIGURATION

    Probe
    {
        id: config
        property string target: ""
        property string headers: ""
        property string sources: ""
        property string files: ""
        property string ignoredFiles: ""
        property stringList ignoredDirs: []
        property stringList additionalDirs: []
        property path destination: FileInfo.joinPaths(sourceDirectory, autoprojectDir);

        configure:
        {
            function getSubdirs(dir)
            {
                var dirs = File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);
                for(var i in dirs)
                    dirs = dirs.concat(getSubdirs(FileInfo.joinPaths(dir, dirs[i])));
                return dirs;
            }

            function getDuplicateSubdirs(dir)
            {
                return getSubdirs(dir).filter(function(element, index, array) { return array.lastIndexOf(element) != index && array.indexOf(element) == index; });
            }

            function getDuplicateDirs(dir, ignored)
            {
                return getDuplicateSubdirs(dir).filter(function(element, index, array) { return !this.contains(element); }, ignored);
            }

            function getExtensionsRegexp(extensions)
            {
                var regexps = []
                for(var i in extensions)
                    regexps.push("\\." + extensions[i] + "$");
                return regexps.join("|");
            }

            var targetName = qbs.targetOS + "-" + qbs.architecture + "-" + qbs.toolchain.join("-");
            target = targetName;
            var projectHeaders = getExtensionsRegexp(headerExtensions);
            headers = projectHeaders;
            var projectSources = getExtensionsRegexp(sourceExtensions);
            sources = projectSources;
            var projectFiles = getExtensionsRegexp(headerExtensions.concat(sourceExtensions).concat(additionalFileEtensions));
            files = projectFiles;
            var filesToIgnore = getExtensionsRegexp(ignoreFiles.concat(["pro", "pri", "pro.user", "qbs.user"]));
            ignoredFiles = filesToIgnore;
            var dirsToIgnore = ignoreDirs.concat([autoprojectDir]);
            ignoredDirs = dirsToIgnore;
            var addedDirs = additionalProjectDirectories.concat(getDuplicateDirs(sourceDirectory, dirsToIgnore));
            additionalDirs = addedDirs;
        }
    }

    Probe
    {
        id: qtscanner
        property var modules: {}

        configure:
        {
            var qtModules = {};
            if(File.exists(qtIncludeRoot))
            {
                var subdirs = File.directoryEntries(qtIncludeRoot, File.Dirs | File.NoDotAndDotDot);
                for(var i in subdirs)
                    qtModules[subdirs[i].replace("Qt", "").toLowerCase()] = File.directoryEntries(FileInfo.joinPaths(qtIncludeRoot, subdirs[i]), File.Files)
            }
            modules = qtModules;
        }
    }

    Probe
    {
        id: projectscanner

        configure:
        {
//            console.info("TARGET BIN : " + config.target);
//            console.info("PROJECT HDR: " + config.headers);
//            console.info("PROJECT SRC: " + config.sources);
//            console.info("PROJECT FIL: " + config.files);
//            console.info("IGNORED FIL: " + config.ignoredFiles);
//            console.info("IGNORED DIR: " + config.ignoredDirs);
//            console.info("ADDITIONAL : " + config.additionalDirs);
//            console.info("DESTINATION: " + config.destination);
//            console.info("Qt Core: " + qtscanner.modules["core"]);
        }
    }
}
