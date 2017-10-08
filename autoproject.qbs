import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    name: "autoproject"
    property string projectRoot: "examples/ComplexProject"
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
        condition: false
        property string rootProjectName: ""
        property stringList references: []
        property string ignoreRegExp: "(\/|)" + autoprojectDir + "\Z|" + ignorePattern;

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
                return File.directoryEntries(dir, File.Files).filter(filterIgnored);
            }

            function getDirs(dir)
            {
                return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot).filter(filterIgnored);
            }

            function makePath(dir, file)
            {
                return FileInfo.joinPaths(dir, file);
            }

            function createProject(dir)
            {
                return { name: FileInfo.baseName(dir), path: dir, products: [], projects: [] };
            }

            function createProduct(dir)
            {
                return { item: "", path: dir, sources: [] }
            }

            function write(project)
            {
                var file = TextFile(makePath(autoprojectDir, FileInfo.baseName(project["path"]) + ".qbs"), TextFile.WriteOnly);
                file.writeLine("import qbs");
                file.writeLine("");
                writeProject(file, project);
                file.close();
            }

            function writeProject(file, project)
            {
                console.info(project["products"].length);
                console.info(project["projects"].length);

                file.writeLine("Project");
                file.writeLine("{");
                file.writeLine("    name: \"" + project["name"] + "\"");
                file.writeLine("    property string target: project.targetDir");

//                for(var i in project["products"])
//                {
//                    file.writeLine("    " + project["products"][i]["item"]);
//                    file.writeLine("    {");
//                    file.writeLine("        files: [\"" + project["products"][i]["files"].join("\", \"") + "\"]");
//                    file.writeLine("    }");
//                }

                file.writeLine("}");

            }

            function getProduct(dir)
            {
                var product = createProduct(dir);
                var files = getFiles(dir);

                for(var item in items)
                {
                    for(var i in files)
                    {
                        if(RegExp(items[item]["pattern"]).test(dir)
                            || (RegExp(items[item]["pattern"]).test(files[i])
                                && (!items[item]["contentPattern"]
                                    ||  RegExp(items[item]["contentPattern"].test(TextFile(makePath(dir, files[i])).readAll())))))
                        {
                            product["item"] = item;
                            product["sources"] = files.filter(filterSources);
                            return product;
                        }
                    }
                }
                return product;
            }

            function scan(dir)
            {
                var project = createProject(dir);
                var product = getProduct(dir);
                if(product["item"])
                    project["products"].push(product);
                var dirs = [dir].concat(getDirs(dir).forEach(appendPath, dir));

                for(var i in dirs)
                {
                    var subdir = dirs[i];
                    product = getProduct(subdir);
                    if(product["item"])
                        project["products"].push(product);
                    else
                        project["projects"].push(scan(dir));
                }
                return project;
            }

            var project = scan(makePath(sourceDirectory, projectRoot));
            write(project);
            rootProjectName = project["name"];
            references = [ FileInfo.joinPaths(sourceDirectory, autoprojectDir, rootProjectName + ".qbs") ];
            console.info("Probe run");
        }
    }

    qbsSearchPaths: FileInfo.joinPaths(sourceDirectory, autoprojectDir)
    references: scanner.references
}
