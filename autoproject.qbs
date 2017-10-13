import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    //CONFIGURATION
    property string projectRoot: "examples"
    property string installDirectory: qbs.targetOS + qbs.architecture + "-" + qbs.toolchain.join("-")
    property string autoprojectDirectory: ".autoproject"
    property path qtIncludePath: "C:/Qt/5.10.0/msvc2017_64/include"
    property string ignorePattern: "/\.autoproject$"
    property string cppSourcesExtension: "cpp"
    property string cppHeadersExtension: "h"
    property string projectFormat: "flat" //tree|flat
    property var items:
    {
        return {
            AutoprojectTest: { pattern: "\/([Tt]est|Test\.(cpp|h))$" },
            AutoprojectApp: { pattern: "\/[Mm]ain\.cpp$" },
            AutoprojectDynamicLib: { pattern: "\/.+\.h$", contentPattern: "[A-Z\d]+_SHARED " },
            AutoprojectPlugin: { pattern: "\/.+\.h$", contentPattern: "Q_INTERFACES\(([a-zA-Z\d]+(, |,|))+\)" },
            AutoprojectStaticLib: { pattern: "\/([Ll]ib|.+\.cpp)$" },
            AutoprojectInclude: { pattern: "\/([Ii]nclude|.+\.h)$" },
            AutoprojectDoc: { pattern: "\/([Dd]ocs?|.+\.qdoc(conf)?)$" }
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
//        condition: false
        property stringList references: []
        property path rootPath: FileInfo.joinPaths(sourceDirectory, projectRoot)
        property path outPath: FileInfo.joinPaths(sourceDirectory, autoprojectDirectory)
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

            function addDependant(product, dependant)
            {
                product.dependants.dependant = true;
            }

            function addDependency(product, dependency)
            {
                product.dependencies.dependency = true;
            }

            function appendPathElements(element, index, array)
            {
                array[index] = makePath(this, element);
            }

            function appendPathToArray(array, dir)
            {
                array.forEach(appendPathElements, dir);
                return array;
            }

            function appendProducts(subdir)
            {
                var products = getProducts(subdir);

                for(var i in products)
                    this.push(products[i])
            }

            function appendSubProject(subdir)
            {
                var proj = createTreeProject(subdir);

                if(proj)
                    this.push(createTreeProject(subdir));
            }

            function createDependencies(proj)
            {
                var products = getProductsFromProject(proj);

                for(var i in products)
                    createProductDependencies(products[i], products);
            }

            function createFlatProject(dir)
            {
                return {
                    name: FileInfo.baseName(dir),
                    path: dir,
                    products: getProducts(dir),
                    projects: []
                };
            }

            function getParentDirName(dir)
            {
                return FileInfo.baseName(FileInfo.path(dir));
            }

            function createNameFromParentDir(dir)
            {
                return getParentDirName(dir) + FileInfo.baseName(dir);
            }

            function createName(item, dir)
            {
                return matchPath(item, dir) ? createNameFromParentDir(dir) : FileInfo.baseName(dir);
            }

            function createProduct(item, dir, sources)
            {
                return {
                    name: createName(item, dir),
                    item: item,
                    path: dir,
                    sources: sources,
                    dependencies: [],
                    dependants: []
                };
            }

            function createProductDependencies(product, products)
            {
                var includes = getIncludedFiles(product);

                for(var i in products)
                    tryProductDependency(product, includes, products[i]);
            }

            function isProjectEmpty(proj)
            {
                return proj.products || proj.projects;
            }

            function createTreeProject(dir)
            {
                var proj = {
                    name: FileInfo.baseName(dir),
                    path: dir,
                    products: [getProduct(dir)],
                    projects: getSubProjects(dir)
                };

                return isProjectEmpty(proj) ? {} : proj;
            }

            function dependProducts(product, dependency)
            {
                addDependency(product, dependency);
                addDependant(dependency, product);
            }

            function isNotIgnored(element)
            {
                return !RegExp(ignorePattern).test(element);
            }

            function isSourceFile(element)
            {
                return RegExp(cppPattern).test(element);
            }

            function getFileContent(file)
            {
                return TextFile(file).readAll();
            }

            function getFiles(dir)
            {
                return File.directoryEntries(dir, File.Files);
            }

            function getFilesFiltered(dir)
            {
                return getFiles(dir).filter(isNotIgnored);
            }

            function getFilesInDir(dir)
            {
                return appendPathToArray(getFilesFiltered(dir), dir);
            }

            function getItem(dir)
            {
                var item = getItemFromDir(dir);
                return item ? item : getItemFromFiles(getFilesInDir(dir));
            }

            function getItemContentPattern(item)
            {
                return items[item].contentPattern;
            }

            function getItemFromDir(dir)
            {
                return Object.keys(items).find(matchDirToItem, dir);
            }

            function getItemFromFiles(files)
            {
                return Object.keys(items).find(matchFilesToItem, files);
            }

            function getItemPattern(item)
            {
                return items[item].pattern;
            }

            function getProduct(dir)
            {
                var item = getItem(dir);
                return item ? createProduct(item, dir, getSourcesInDir(dir)) : {}
            };

            function getProducts(dir)
            {
                var product = getProduct(dir);
                var products = product.item ? [product] : []; getSubdirs(dir).forEach(appendProducts, products);
                return products;
            }

            function getProductsFromProject(proj)
            {
                var products = [];

                if(proj.products[0].item)
                    products.push(proj.products[0]);

                for(var i in proj.projects)
                    products = products.concat(getProductsFromProject(proj.projects[i]));

                return products;
            }

            function getSourcesInDir(dir)
            {
                return getFilesFiltered(dir).filter(isSourceFile);
            }

            function getDirs(dir)
            {
                return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);
            }

            function getDirsFiltered(dir)
            {
                return getDirs(dir).filter(isNotIgnored);
            }

            function getSubdirs(dir)
            {
                return appendPathToArray(getDirsFiltered(dir), dir);
            }

            function getSubProject(subdir)
            {
                return createProject(subdir);
            }

            function getSubProjects(dir)
            {
                var subProjects = []; getSubdirs(dir).forEach(appendSubProject, subProjects); return subProjects;
            }

            function hasContentPattern(item)
            {
                return getItemContentPattern(item);
            }

            function hasSourceExtension(file)
            {
                return element.endsWith("." + cppSourcesExtension);
            }

            function hasSourceFile(product, file)
            {
                return product.sources.contains(file);
            }

            function isProductHeaderOnly(product)
            {
                return !product.sources.some(hasSourceExtension);
            }

            function makePath(dir, file)
            {
                return FileInfo.joinPaths(dir, file);
            }

            function matchContent(item, file)
            {
                return hasContentPattern(item) ? matchFileContent(item, file) : true;
            }

            function matchDirToItem(item)
            {
                return matchPath(item, this);
            }

            function matchFileContent(item, file)
            {
                return RegExp(getItemContentPattern(item)).test(getFileContent(file));
            }

            function matchFilesToItem(item)
            {
                return this.some(matchFileToItem, item);
            }

            function matchFileToItem(file)
            {
                return matchPath(this, file) && matchContent(this, file);
            }

            function matchPath(item, path)
            {
                return RegExp(getItemPattern(item)).test(path);
            }

            function getRootProject()
            {
                return projectFormat == "tree" ? createTreeProject(rootPath) : createFlatProject(rootPath);
            }

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
                var file = TextFile(makePath(outPath, proj.name + ".qbs"), TextFile.WriteOnly);
                file.writeLine("import qbs");
                file.writeLine("");
                writeProject(file, proj, "");
                file.close();
            }

            function writeProduct(file, product, indent)
            {
                file.writeLine(indent + "    " + product.item);
                file.writeLine(indent + "    {");
                file.writeLine(indent + "        name: \"" + product.name + "\"");
                file.writeLine(indent + "        path: \"" + product.path + "\"");
                file.writeLine(indent + "    }");
            }

            function writeProject(file, proj, indent)
            {
                file.writeLine(indent + "Project");
                file.writeLine(indent + "{");
                file.writeLine(indent + "    name: \"" + proj.name + "\"");
                file.writeLine(indent + "    property string target: project.installDirectory");

                for(var i in proj.products)
                    writeProduct(file, proj.products[i], indent)

                for(var i in proj.projects)
                    writeProject(file, proj.projects[i], indent + "    ");

                file.writeLine(indent + "}");
            }

            function print(proj, indent)
            {
                console.info("PROJECT: " + proj.name + " (" + proj.path + ")");

                if(projectFormat == "tree")
                {
                    for(var i in proj.projects)
                        print(proj.projects[i], indent + "  ");
                }

                for(var i in proj.products)
                    printProduct(proj.products[i]);
            }

            function printProduct(product)
            {
                console.info("product: " + product.name + "(" + product.item + ": " + product.path + ")");
                for(var i in product.dependencies)
                    console.info("+" + product.dependencies[i].path);
                for(var i in product.dependants)
                    console.info("-" + product.dependants[i].path);
            }

            var rootProject = getRootProject();
//            createDependencies(rootProject);
//            print(rootProject, "");
            write(rootProject);

            references = [ makePath(outPath, rootProject.name + ".qbs") ];
            console.info("Probe run");

        }
    }

    qbsSearchPaths: scanner.outPath
    references: scanner.references
}
