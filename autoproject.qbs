import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //-------------//
    //CONFIGURATION//
    //-------------//

    //Name to be displayd in IDEs
    name: "Autoproject"
    //Path to the autoproject.qbs from project's root
    property string pathFromRootToAutoproject: ""
    //Path to installation root from project's root
    property string pathFromRootToInstallRoot: "bin"
    //Path to lib destination from project's root
    property string pathFromRootToLib: "lib"
    //Path to sources from project's root
    property string pathFromRootToSourceRoot: "src"
    //Path to pubic headers from project's root
    property string pathFromRootToIncludeRoot: "include"

    //ADVANCED
    property string qtRoot: "C:/Qt/5.9.1/msvc2017_64/" //property is set by Qbs but is inaccessible from Project or Probe items
    property string testDir: "test" //subdirectory of this name will generate test product
    property string docDir: "doc" //subdirectory of this name will generate documentation product
    property string resourceDir: "resources" //subdirectory of this name will be added to the project as resources

    //-------------//
    //END OF CONFIG//
    //-------------//

    id: autoproject
    property path root: sourceDirectory.replace(pathFromRootToAutoproject, "")

    Probe
    {
        id: qtscanner
        condition: autoproject.qtRoot != ""
        property var qtmodules: {}

        configure:
        {
            var qtIncludePath = FileInfo.joinPaths(autoproject.qtRoot, "include");
            var qtModules = {};
            var modules = File.directoryEntries(qtIncludePath, File.Dirs | File.NoDotAndDotDot);

            for(var i in modules)
            {
                var module = modules[i];
                var headers = File.directoryEntries(FileInfo.joinPaths(qtIncludePath, module), File.Files);
                var moduleName = module.replace("Qt", "").toLowerCase();
                qtModules[moduleName] = headers;
            }

            qtmodules = qtModules;
        }
    }

    Probe
    {
        id: includescanner
        condition: autoproject.pathFromRootToIncludeRoot != ""
        property var includes: {}

        configure:
        {
            function scanIncludes(dir, scanned)
            {
                var files = File.directoryEntries(dir, File.Files);

                for(var i in files)
                {
                    var file = files[i];
                    scanned[file] = dir;
                }

                var dirs = File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);

                for(var i in dirs)
                {
                    var subdir = dirs[i];
                    scanIncludes(FileInfo.joinPaths(dir, subdir), scanned);
                }
            }

            var headers = {};
            var includeDir = FileInfo.joinPaths(autoproject.root, autoproject.pathFromRootToIncludeRoot);
            scanIncludes(includeDir, headers);
            includes = headers;
        }
    }

    Probe
    {
        id: projectscanner
        condition: autoproject.pathFromRootToSourceRoot != ""
        property var projects: {}

        configure:
        {
            function scanProjects(dir, project)
            {
                var dirs = File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);

                for(var i in dirs)
                {
                    var subdir = dirs[i];
                    var subdirpath = FIleInfo.joinPaths(dir, subdir);

                    if(subdir == "test")
                    {
                        project["test"] = {};
                        project["test"]["path"] = subdirpath;
                    }
                    else if(subdir == "doc")
                    {
                        project["doc"] = {}
                        project["doc"]["path"] = subdirpath;
                    }
                    else if(subdir == "resources")
                    {
                        project["resources"] = {}
                        project["resources"]["path"] = subdirpath;
                    }
                    else
                    {
                        project[subdir] = {}
                        project[subdir]["path"] = subdirpath;
                        scannedProjects(subdirpath, project[subdir]);
                    }
                }
            }

            var scannedProjects = {};
            var sourceDir = FileInfo.joinPaths(autoproject.root, autoproject.pathFromRootToSourceRoot);
            scanProjects(sourceDir, scannedProjects);
            projects = scannedProjects;
        }
    }

    references:
    {

    }
}
