import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

//INTRODUCTION
//qbs-autoproject will generate projects with
//detected dependencies on Qt modules and each
//other based on the directory structure and
//source and header files contents.

Project
{
    //CONFIGURATION
    //Files with this extension will be used for dependencies detection and resolution
    property string headerExtension: "h"
    //Files with this extension will be used for dependencies detection
    property string sourceExtension: "cpp"
    //Additional Files to sources and headers to make part of the projects
    property stringList additionalFileExtensions: ["ui", "rc"]
    //Relative path to autoproject.qbs from the project root (empty if the file is in root)
    property string projectRoot: ""
    //Where autoproject should write the project files relative to its location (the directory will be ignored by the autproject for other purposes)
    property string autoprojectDirectory: "temp"
    //Directories for which to generate a test Product (the directory will be ignored by the autproject for other purposes)
    property string testDirectory: "test"
    //Directories for which to generate a documentation Product (the directory will be ignored by the autproject for other purposes)
    property string documentationDirectory: "doc"
    //Directories containing public/external headers for dependency resolution (the directory will be ignored by the autproject for other purposes)
    property string includeDirectory: "include"
    //Location of Qt headers for Qt module resolution
    property path qtIncludeRoot: "C:/Qt/5.10.0/msvc2017_64/include/"
    //Directories to consider part of the individual subproject
    property stringList additionalDirectories: ["private", "resources"]
    //Directories to explicitely ignore including any and all subdirectories
    property stringList ignoredDirectories: []
    //END OF CONFIGURATION

    name: FileInfo.baseName(sourceDirectory)

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
        property var projects: []

        configure:
        {
            var targetDirectory = [qbs.targetOS, qbs.architecture, qbs.toolchain.join("-")].join("-");
            var root = sourceDirectory.replace(projectRoot, "");
        }
    }
}
