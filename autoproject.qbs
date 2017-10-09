import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    name: "autoproject"
    property string projectRoot: "examples"
    property string installDirectory: qbs.targetOS + "-" + qbs.toolchain.join("-")
    property string autoprojectDirectory: ".autoproject"
    property path qtIncludePath: "C:/Qt/5.10.0/msvc2017_64/include"
    property stringList ignoreList: []
    property string cppSourcesExtension: "cpp"
    property string cppHeadersExtension: "h"
    property var items:
    {
        return {
            AutoprojectTest: { pattern: "[Tt]est(\.(cpp|h)|)$" },
            AutoprojectApp: { pattern: "^(Win|.*)[Mm]ain\.cpp$" },
            AutoprojectDynamicLib: { pattern: "\.h$", contentPattern: "[A-Z\d]+_SHARED " },
            AutoprojectPlugin: { pattern: "\.h$", contentPattern: "Q_INTERFACES\(([a-zA-Z\d]+(, |,|))+\)" },
            AutoprojectStaticLib: { pattern: "\.cpp$" },
            AutoprojectInterfaces: { pattern: "(\/include|\.h)$" },
            AutoprojectDoc: { pattern: "(\/doc(s|)|\.(qdocconf|qdoc))$" }
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
        property stringList references: []
        property path rootPath: FileInfo.joinPaths(sourceDirectory, projectRoot)
        property path outPath: FileInfo.joinPaths(sourceDirectory, autoprojectDirectory)
        property string ignorePattern: [outPath].concat(ignoreList).join("|");
        property string cppPattern: "\.(" + cppSourcesExtension + "|" + cppHeadersExtension + ")$"

        configure:
        {
            if(!Array.prototype.find)
            {
                Object.defineProperty(Array.prototype, 'find',
                { value: function(predicate)
                    {
                        if(this == null) throw new TypeError('"this" is null or not defined');
                        if(typeof predicate !== 'function') throw new TypeError('predicate must be a function');
                        for(var k = 0; k < (Object(this).length >>> 0); k++) if(predicate.call(arguments[1], Object(this)[k], k, Object(this))) return Object(this)[k];
                        return undefined;
                    }
                });
            }

            function filterIgnored(element) { return !RegExp(ignorePattern).test(element); }
            function filterNonCpp(element) { return RegExp(cppPattern).test(element); }
            function appendPathElements(element, index, array) { array[index] = makePath(this, element); }
            function makePath(dir, file) { return FileInfo.joinPaths(dir, file); }
            function getSourcesInDir(dir) { return getFilesInDir(dir).filter(filterNonCpp); }
            function createProject(dir) { return { name: FileInfo.baseName(dir), path: dir, product: getProduct(dir), projects: getSubProjects(dir) }; }
            function createProduct(item, dir, sources) { return { item: item, path: dir, sources: sources }; }
            function appendPathToArray(array, dir) { array.forEach(appendPathElements, dir); return array; }
            function filterIgnoredFromArray(array) { return array.filter(filterIgnored); }
            function getFilesInDir(dir) { return appendPathToArray(filterIgnoredFromArray(File.directoryEntries(dir, File.Files)), dir); }
            function getSubdirs(dir) { return appendPathToArray(filterIgnoredFromArray(File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot)), dir); }
            function getFileContent(file) { return TextFile(file).readAll(); }
            function getItemPattern(item) { return items[item]["pattern"]; }
            function getItemContentPattern(item) { return items[item]["contentPattern"]; }
            function hasContentPattern(item) { return getItemContentPattern(item); }
            function matchFileContent(item, file) { return RegExp(getItemContentPattern(item)).test(getFileContent(file)); }
            function matchContent(item, file) { return hasContentPattern(item) ? matchFileContent(item, file) : true; }
            function matchName(item, path) { return RegExp(getItemPattern(item)).test(path); }
            function matchFileToItem(file) {  return matchName(this, file) && matchContent(this, file); }
            function matchDirToItem(item) { return matchName(item, this); }
            function matchFilesToItem(item) { return this.some(matchFileToItem, item); }
            function getItemFromFiles(files) { return Object.keys(items).find(matchFilesToItem, files); }
            function getItemFromDir(dir) { return Object.keys(items).find(matchDirToItem, dir); }
            function getItem(dir) { var item = getItemFromDir(dir); return item ? item : getItemFromFiles(getFilesInDir(dir)); }
            function getProduct(dir) { var item = getItem(dir); return item ? createProduct(item, dir, getSourcesInDir(dir)) : {} };
            function getSubProject(subdir) { return createProject(subdir); }
            function appendSubProject(subdir) { this.push(createProject(subdir)); }
            function getSubProjects(dir) { var subProjects = []; getSubdirs(dir).forEach(appendSubProject, subProjects); return subProjects; }


            function write(proj)
            {
                var file = TextFile(makePath(outPath, proj["name"] + ".qbs"), TextFile.WriteOnly);
                file.writeLine("import qbs");
                file.writeLine("");
                writeProject(file, proj, "");
                file.close();
            }

            function writeProject(file, project, indent)
            {
                file.writeLine(indent + "Project");
                file.writeLine(indent + "{");
                file.writeLine(indent + "    name: \"" + project["name"] + "\"");
                file.writeLine(indent + "    property string target: project.installDirectory");

                if(indent == "")
                    file.writeLine(indent + "    property string parent: name");
                else
                    file.writeLine(indent + "    property string parent: project.name");

                if(project["product"]["item"])
                {
                    file.writeLine(indent + "    " + project["product"]["item"]);
                    file.writeLine(indent + "    {");
                    file.writeLine(indent + "        files: [\"" + project["product"]["sources"].join("\", \"") + "\"]");
                    file.writeLine(indent + "    }");
                }

                for(var i in project["projects"])
                    writeProject(file, project["projects"][i], indent + "    ");

                file.writeLine(indent + "}");
            }

            function print(proj, indent)
            {
                console.info("PROJECT: " + proj["name"] + " (" + proj["path"] + ")");
                if(proj["product"]["item"])
                    console.info("product: " + proj["product"]["item"] + " (" + proj["product"]["path"] + "): " + proj["product"]["sources"]);
                for(var i in proj["projects"])
                    print(proj["projects"][i], indent + "  ");
            }

            var rootProject = createProject(rootPath);
            print(rootProject, "");
            write(rootProject);

            references = [ makePath(outPath, rootProject["name"] + ".qbs") ];
            console.info("Probe run");

        }
    }

    qbsSearchPaths: scanner.outPath
    references: scanner.references
}
