import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    name: "autoproject"
    property string projectRoot: "examples"
    property string installDir: qbs.targetOS + "-" + qbs.toolchain.join("-")
    property string autoprojectDir: ".autoproject"
    property string qtIncludeDir: "C:/Qt/5.10.0/msvc2017_64/include"
    property string ignorePattern: ".\A"
    property string sourcePattern: "\.(cpp|h)$"
    property var items:
    {
        return {
            AutoprojectTest: { pattern: "[Tt]est(\.(cpp|h)|)$" },
            AutoprojectApp: { pattern: "^(Win|)[Mm]ain\.cpp$" },
            AutoprojectDynamicLib: { pattern: "\.h$", contentPattern: "[A-Z\d]+_SHARED " },
            AutoprojectPlugin: { pattern: "\.h$", contentPattern: "Q_INTERFACES\(([a-zA-Z\d]+(, |,|))+\)" },
            AutoprojectStaticLib: { pattern: "\.cpp$" },
            AutoprojectInterfaces: { pattern: "(^include|\.h)$" },
            AutoprojectDoc: { pattern: "(^doc(s|)|\.(qdocconf|qdoc))$" }
        };
    }
    property var modules:
    {
        return {
            cinject: { includes: "" },
            cppbdd: { includes: "" }
        }
    }
    //END OF CONFIGURATION

    id: autoproject

    Probe
    {
        id: scanner
//        condition: false
        property string rootProjectName: ""
        property stringList references: []
        property string ignoreRegExp: "(\/|)" + autoprojectDir + "\Z|" + ignorePattern
        property path root: FileInfo.joinPaths(sourceDirectory, projectRoot)

        configure:
        {
            function filterIgnored(element)
            {
                return !RegExp(ignoreRegExp).test(element);
            }

            function filterSources(element)
            {
                return RegExp(sourcePattern).test(element);
            }

            function appendPath(element, index, array)
            {
                array[index] = makePath(this, element);
            }

            function getFiles(dir)
            {
                var files = File.directoryEntries(dir, File.Files).filter(filterIgnored);
                files.forEach(appendPath, dir);
                return files;
            }

            function getDirs(dir)
            {
                var dirs = File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot).filter(filterIgnored);
                dirs.forEach(appendPath, dir);
                return dirs;
            }

            function makePath(dir, file)
            {
                return FileInfo.joinPaths(dir, file);
            }

            function createProject(dir)
            {
                return { name: FileInfo.baseName(dir), path: dir, products: [], projects: [] };
            }

            function createProduct(item, dir)
            {
                return { item: item, path: dir, sources: getFiles(dir).filter(filterSources) };
            }

            function scan(project, dir)
            {
                var currentProject = project;
                var item = itemFromDir(dir);
                if(item)
                    currentProject["products"].push(createProduct(item, dir));
                else
                {
                    if(project["path"] != dir)
                    {
                        currentProject = createProject(dir);
                        project["projects"].push(currentProject);
                    }

                    item = findItemInFiles(getFiles(dir));
                    if(item)
                        currentProject["products"].push(createProduct(item, dir));
                }

                var dirs = getDirs(dir);
                for(var i in dirs)
                    scan(currentProject, dirs[i]);
            }

            function itemFromDir(dir)
            {
                for(var item in items)
                {
                    if(testName(item, dir))
                        return item;
                }

                return "";
            }

            function testFileContent(item, file)
            {
                return RegExp(items[item]["contentPattern"]).test(TextFile(file).readAll());
            }

            function testContent(item, file)
            {
                return items[item]["contentPattern"] ? testFileContent(item, file) : false;
            }

            function testName(item, file)
            {
                return RegExp(items[item]["pattern"]).test(file)
            }

            function testFileForItem(item, file)
            {
                return testName(item, file) && testContent(item, file);
            }

            function testFilesForItem(item, files)
            {
                for(var i in files)
                {
                    if(testFileForItem(item, files[i]))
                        return true;
                }

                return false;
            }

            function findItemInFiles(files)
            {
                for(var item in items)
                {
                    if(testFilesForItem(item, files))
                        return item;
                }

                return "";
            }

            function write(project)
            {
                var file = TextFile(FileInfo.joinPaths(sourceDirectory, autoprojectDir, FileInfo.baseName(project["path"]) + ".qbs"), TextFile.WriteOnly);
                file.writeLine("import qbs");
                file.writeLine("");
                writeProject(file, project, "");
                file.close();
            }

            function writeProject(file, project, indent)
            {
                file.writeLine(indent + "Project");
                file.writeLine(indent + "{");
                file.writeLine(indent + "    name: \"" + project["name"] + "\"");
                file.writeLine(indent + "    property string target: project.targetDir");

                for(var i in project["products"])
                {
                    file.writeLine(indent + "    " + project["products"][i]["item"]);
                    file.writeLine(indent + "    {");
                    file.writeLine(indent + "        files: [\"" + project["products"][i]["sources"].join("\", \"") + "\"]");
                    file.writeLine(indent + "    }");
                }

                for(var i in project["projects"])
                    writeProject(file, project["projects"][i], indent + "    ");



                file.writeLine(indent + "}");

            }

            function print(project, indent)
            {
                console.info("PROJECT: " + project["name"]);
                console.info("products:");
                for(var i in project["products"])
                    console.info(indent + project["products"][i]["item"] + " (" + project["products"][i]["path"] + "): " + project["products"][i]["sources"].join(", "));
                for(var i in project["projects"])
                    print(project["projects"][i], indent + "  ");
            }

            var project = createProject(root);
            scan(project, root);
            print(project, "");
            write(project);

            rootProjectName = project["name"];
            references = [ FileInfo.joinPaths(sourceDirectory, autoprojectDir, rootProjectName + ".qbs") ];
            console.info("Probe run");
        }
    }

    qbsSearchPaths: FileInfo.joinPaths(sourceDirectory, autoprojectDir)
    references: scanner.references
}
