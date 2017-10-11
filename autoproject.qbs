import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    property string projectRoot: "examples"
    property string installDirectory: qbs.targetOS + "-" + qbs.toolchain.join("-")
    property string autoprojectDirectory: ".autoproject"
    property path qtIncludePath: "C:/Qt/5.10.0/msvc2017_64/include"
    property stringList ignoreList: []
    property string cppSourcesExtension: "cpp"
    property string cppHeadersExtension: "h"
    property string projectFormat: "tree" //tree(default)|flat
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

    name: "autoproject"
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
            function getSourcesInDir(dir) { return filterIgnoredFromArray(File.directoryEntries(dir, File.Files)).filter(filterNonCpp); }
            function createTreeProject(dir) { var proj = { name: FileInfo.baseName(dir), path: dir, product: getProduct(dir), projects: getSubProjects(dir) }; return proj["product"] || proj["projects"] ? proj : {}; }
            function createFlatProject(dir) { return { name: FileInfo.baseName(dir), path: dir, products: getProducts(dir) }; }
            function createProduct(item, dir, sources) { return { item: item, path: dir, sources: sources, dependencies: [], dependants: [] }; }
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
            function appendSubProject(subdir) { var proj = createTreeProject(subdir); if(proj) this.push(createTreeProject(subdir)); }
            function getSubProjects(dir) { var subProjects = []; getSubdirs(dir).forEach(appendSubProject, subProjects); return subProjects; }
            function appendProducts(subdir) { var products = getProducts(subdir); for(var i in products) this.push(products[i]) }
            function getProducts(dir) { var product = getProduct(dir); var products = product["item"] ? [product] : []; getSubdirs(dir).forEach(appendProducts, products); return products; }
            function getProductsFromProject(proj) { var products = []; if(proj["product"]["item"]) products.push(proj["product"]); for(var i in proj["projects"]) products = products.concat(getProductsFromProject(proj["projects"][i])); return products; }
            function createProductDependencies(product, products) { var includes = getIncludedFiles(product); for(var i in products) tryProductDependency(product, includes, products[i]); }
            function createDependencies(proj) { var products = getProductsFromProject(proj); for(var i in products) createProductDependencies(products[i], products); }
            function hasSourceFile(product, file) { return product["sources"].contains(file); }
            function addDependency(product, dependency) { if(!product["dependencies"].contains(dependency)) product["dependencies"].push(dependency); }
            function addDependant(product, dependant) { if(!product["dependants"].contains(dependant)) product["dependants"].push(dependant); }
            function dependProducts(product, dependency) { addDependency(product, dependency); addDependant(dependency, product); }
            function hasSourceExtension(file) { return element.endsWith("." + cppSourcesExtension); }
            function isProductHeaderOnly(product) { return !product["sources"].some(hasSourceExtension); }
            function getIncludedFiles(product)
            {
                var includedFiles = {};

                for(var i in product["sources"])
                {
                    var sourceFile = product["sources"][i];
                    var content = TextFile(makePath(product["path"], sourceFile)).readAll();
                    var regexp = /#include <|\"(.*)\"|>/g
                    var result = [];
                    while(result = regexp.exec(content))
                        includedFiles[result[1]] = true;
                }

                return Object.keys(includedFiles);
            }

            function tryProductDependency(product, includes, other)
            {
                for(var i in includes)
                {
                    if(hasSourceFile(other, includes[i]))
                    {
                        dependProducts(product, other);
                        break;
                    }
                }
            }

            function write(proj)
            {
                var file = TextFile(makePath(outPath, proj["name"] + ".qbs"), TextFile.WriteOnly);
                file.writeLine("import qbs");
                file.writeLine("");
                writeProject(file, proj, "");
                file.close();
            }

            function writeProject(file, proj, indent)
            {
                file.writeLine(indent + "Project");
                file.writeLine(indent + "{");
                file.writeLine(indent + "    name: \"" + proj["name"] + "\"");
                file.writeLine(indent + "    property string target: project.installDirectory");

                if(proj["product"])
                {
                    for(var i in proj["projects"])
                        writeProject(file, proj["projects"][i], indent + "    ");
                }
                else
                {
                    for(var i in proj["products"])
                    {
                        file.writeLine(indent + "    " + proj["products"][i]["item"]);
                        file.writeLine(indent + "    {");
                        file.writeLine(indent + "        path: \"" + proj["products"][i]["path"] + "\"");
                        file.writeLine(indent + "    }");
                    }
                }

                file.writeLine(indent + "}");
            }

            function print(proj, indent)
            {
                console.info("PROJECT: " + proj["name"] + " (" + proj["path"] + ")");
                if(proj["product"])
                {
                    if(proj["product"]["item"])
                        printProduct(proj["product"]);
                    for(var i in proj["projects"])
                        print(proj["projects"][i], indent + "  ");
                }
                else
                {
                    for(var i in proj["products"])
                        printProduct(proj["products"][i]);
                }
            }

            function printProduct(product)
            {
                console.info("product: " + product["item"] + " (" + product["path"] + "): " + product["sources"]);
                for(var i in product["dependencies"])
                    console.info("+" + product["dependencies"][i]["path"]);
                for(var i in product["dependants"])
                    console.info("-" + product["dependants"][i]["path"]);
            }

            var rootProject = (projectFormat == "tree" ? createTreeProject(rootPath) : createFlatProject(rootPath));
            createDependencies(rootProject);
            print(rootProject, "");
            write(rootProject);

            references = [ makePath(outPath, rootProject["name"] + ".qbs") ];
            console.info("Probe run");

        }
    }

    qbsSearchPaths: scanner.outPath
    references: scanner.references
}
