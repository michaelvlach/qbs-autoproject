import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    property stringList headers: ["\\.h$"]
    property stringList sources: ["\\.cpp$"]
    property stringList additionalDirectories: ["config", "style", "reference"]
    property stringList whiteFileList: ["\\.ui$", "\\.qrc$", "\\.qdoc$"]
    property stringList ignoreDirlist: ["autoproject"]
    //END OF CONFIGURATION

    Probe
    {
        id: autoscanner

        configure:
        {

            var targetName = qbs.targetOS + "-" + qbs.architecture + "-" + qbs.toolchain.join("-");
            var whiteListRegex = whiteFileList.join('|');
            var ignoreListRegex = ignoreDirlist.join('|');
            var sourceRegex = sources.join('|');
            var headerRegex = headers.join('|');
            var additionalDirs = additionalDirectories.concat(getDuplicateDirNames(sourceDirectory)).concat(getEmptyDirNames(sourceDirectory));
            var additionalDirsRegex = getAdditionalDirsRegex(additionalDirs);
            var rootProject = getProjectTree(sourceDirectory);
            printProject(rootProject, "");

            function printProject(project, indent)
            {
                console.info(indent + project["name"] + " " + project["path"])
                for(var i in project["projects"])
                    printProject(project["projects"][i], indent + "+");
            }

            //Utility
            function getAdditionalDirsRegex(dirs) { dirs.forEach(function(element, index, array) { array[index] = "^" + element + "$"; }); return dirs.join("|"); }
            function getFilesInDir(dir) { return File.directoryEntries(dir, File.Files); }
            function getFilesInDirFiltered(dir) { return getFilesInDir(dir).filter(function(element) { return element.match(whiteListRegex); }); }
            function getDirsInDir(dir) { return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot); }
            function getDirsInDirFiltered(dir) { return getDirsInDir(dir).filter(function(element) { return !element.match(ignoreListRegex); }); }
            function getDuplicateDirNames(dir) { return getDirNamesRecursive(dir).filter(function(element, index, array) { return array.lastIndexOf(element) != index; }); }
            function getDirNamesRecursive(dir)
            {
                var dirs = getDirsInDirFiltered(dir);
                for(var i in dirs)
                    dirs = dirs.concat(getDirNamesRecursive(FileInfo.joinPaths(dir, dirs[i])));
                return dirs;
            }
            function getEmptyDirNames(dir)
            {
                var dirs = getDirsInDirFiltered(dir).filter(function(element) { return getFilesInDirFiltered(FileInfo.joinPaths(this, element)).length == 0; }, dir);
                for(var i in dirs)
                    dirs = dirs.concat(getDirNamesRecursive(FileInfo.joinPaths(dir, dirs[i])));
                return dirs;
            }

            //Scanner
            function getProjectDirs(dir, filter)
            {
                var dirs = getDirsInDirFiltered(dir).filter(function(element) { return element.match(filter); });
                dirs.forEach(function(element, index, array) { array[index] = FileInfo.joinPaths(this, element); }, dir)
                for(var i in dirs)
                    dirs = dirs.concat(getProjectDirs(FileInfo.joinPaths(dir, dirs[i]), filter));
                return dirs;
            }

            function getProjectFiles(dir, filter)
            {
                var files = getFilesInDirFiltered(dir).filter(function(element) { return element.match(filter); });
                files.forEach(function(element, index, array) { array[index] = FileInfo.joinPaths(this, element); }, dir)
                var dirs = getDirsInDirFiltered(dir).filter(function(element) { return additionalDirs.contains(element); });
                for(var i in dirs)
                    files = files.concat(getProjectFiles(FileInfo.joinPaths(dir, dirs[i]), filter));
                return files;
            }

            function getSubProjectsDirs(dir)
            {
                return getProjectDirs(dir, ".*").filter(function(element) { return !FileInfo.baseName(element).match(additionalDirsRegex); });
            }

            function getSubProjects(dirs)
            {
                var projects = [];
                for(var i in dirs)
                    projects.push(getProjectTree(dirs[i]));
                return projects;
            }

            function getProjectTree(dir)
            {
                var project = {};
                project["name"] = FileInfo.baseName(dir);
                project["path"] = dir;
                project["dirs"] = getProjectDirs(dir, additionalDirsRegex);
                project["headers"] = getProjectFiles(dir, headerRegex);
                project["sources"] = getProjectFiles(dir, sourceRegex);
                project["projects"] = getSubProjects(getSubProjectsDirs(dir));
                return project;
            }
        }
    }
}
