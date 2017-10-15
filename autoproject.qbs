import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: "autoproject"
    id: autoproject

    Probe
    {
        id: configuration

        property var ProjectFormat:
        {
            return {
                Tree: "Tree",
                Flat: "Flat"
            }
        }

        //-------------//
        //CONFIGURATION//
        //-------------//
        property string autoprojectDirectory: ".autoproject"
        property string projectRoot: "examples"
        property string projectFormat: ProjectFormat.Flat
        property string installDirectory: qbs.targetOS + qbs.architecture + "-" + qbs.toolchain.join("-")

        property string ignorePattern: "\/.autoproject$"
        property string additionalDirectoriesPattern: "\/[Ii]nclude$"
        property string cppSourcesPattern: "\.cpp$"
        property string cppHeadersPattern: "\.h$"

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
                Qt: { includePath: "C:/Qt/5.10.0/msvc2017_64/include" }
            }
        }
        //--------------------//
        //END OF CONFIGURATION//
        //--------------------//

        property path rootPath: ""
        property path outPath: ""
        property string cppPattern: ""

        configure:
        {
            var root = FileInfo.joinPaths(sourceDirectory, projectRoot);
            var out = FileInfo.joinPaths(sourceDirectory, autoprojectDirectory);
            var cpp = cppSourcesPattern + "|" + cppHeadersPattern;

            rootPath = root;
            outPath = out;
            cppPattern = cpp;

            console.info("Autoproject configured");
        }
    }

    Probe
    {
        id: modulescanner

        property var modules: configuration.modules

        configure:
        {
            function getSubmodules(moduleName)
            {
                var submodules = [];
                var dir = modules[moduleName].includePath;
                File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot).forEach(function(subdir)
                {
                    submodules.push({
                        name: subdir,
                        files: File.directoryEntries(FileInfo.joinPaths(dir, subdir), File.Files)
                    });
                });
            }

            var scannedModules = {};

            Object.keys(modules).forEach(function(moduleName)
            {
                scannedModules[moduleName] = {
                    files: File.directoryEntries(modules[moduleName].includePath, File.Files),
                    submodules: getSubmodules(moduleName)
                };
            });

            modules = scannedModules;
        }
    }

    Probe
    {
        id: projectscanner

        property var rootPath: configuration.rootPath
        property var ignorePattern: configuration.ignorePattern
        property var rootProject: {}

        configure:
        {
            function appendPath(array, path)
            {
                array.forEach(function(element, index, array)
                {
                    array[index] = FileInfo.joinPaths(path, element);
                });
                return array;
            }

            function isNotIgnored(element)
            {
                return !RegExp(ignorePattern).test(element);
            }

            function getSubdirs(dir)
            {
                return appendPath(File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot).filter(isNotIgnored), dir);
            }

            function getFiles(dir)
            {
                return appendPath(File.directoryEntries(dir, File.Files).filter(isNotIgnored), dir);
            }

            function getSubprojects(dir)
            {
                var subprojects = [];

                getSubdirs(dir).forEach(function(subdir)
                {
                    subprojects.push(getProject(FileInfo.joinPaths(dir, subdir)));
                });

                return subprojects;
            }

            function getProject(dir)
            {
                return {
                    name: FileInfo.baseName(dir),
                    path: dir,
                    files: getFiles(dir),
                    subprojects: getSubprojects(dir)
                };
            }

            var proj = getProject(rootPath);
            rootProject = proj;
        }
    }

    Probe
    {
        id: productscanner

        property var scannedRootProject: projectscanner.rootProject
        property var items: configuration.items
        property var cppPattern: configuration.cppPattern
        property var rootProject: {}

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

            function getItemFromPath(path)
            {
                return Object.keys(items).find(function(item)
                {
                    return RegExp(items[item].pattern).test(path);
                });
            }

            function getItemFromFiles(files)
            {
                return Object.keys(items).find(function(item)
                {
                    return files.some(function(file)
                    {
                        return RegExp(items[item].pattern).test(file) && (!items[item].contentPattern || RegExp(items[item].contentPattern).test(TextFile(file).readAll()));
                    });
                });
            }

            function getProduct(proj)
            {
                var item = getItemFromPath(proj.path);
                var name = proj.name;

                if(item)
                    name = FileInfo.baseName(FileInfo.path(proj.path)) + proj.name;
                else
                    item = getItemFromFiles(proj.files);

                return item ? {
                    name: name,
                    item: item,
                    path: proj.path
                } : {};
            }

            function scanSubprojects(subprojects)
            {
                var subprojectsList = [];

                subprojects.forEach(function(subproject)
                {
                    subprojectsList.push(scanProject(subproject));
                });

                return subprojectsList;
            }

            function scanProject(proj)
            {
                return {
                    name: proj.name,
                    path: proj.path,
                    product: getProduct(proj),
                    subprojects: proj.subprojects ? scanSubprojects(proj.subprojects) : []
                };
            }

            var proj = scanProject(scannedRootProject);
            rootProject = proj;
        }
    }

    Probe
    {
        id: projectbuilder

        property var scannedRootProject: productscanner.rootProject
        property var additionalDirectoriesPattern: configuration.additionalDirectoriesPattern
        property var cppSourcesPattern: configuration.cppSourcesPattern
        property var sppHeadersPattern: configuration.cppHeadersPattern
        property var rootProject: {}

        configure:
        {
            function buildProject(proj)
            {

            }

            var proj = buildProject(proj);
            rootProject = proj;
        }
    }


//    Probe
//    {
//        id: scanner
//        condition: true
//        property stringList references: []


//        configure:
//        {


//            function addDependant(product, dependant)
//            {
//                product.dependants.dependant = true;
//            }

//            function addDependency(product, dependency)
//            {
//                product.dependencies.dependency = true;
//            }

//            function appendPathElements(element, index, array)
//            {
//                array[index] = makePath(this, element);
//            }

//            function appendPathToArray(array, dir)
//            {
//                array.forEach(appendPathElements, dir);
//                return array;
//            }

//            function appendSubProject(subdir)
//            {
//                this.push(createProject(subdir));
//            }

//            function createDependencies(proj)
//            {
//                var products = getProductsFromProject(proj);

//                for(var i in products)
//                    createProductDependencies(products[i], products);
//            }

//            function getParentDirName(dir)
//            {
//                return FileInfo.baseName(FileInfo.path(dir));
//            }

//            function createNameFromParentDir(dir)
//            {
//                return getParentDirName(dir) + FileInfo.baseName(dir);
//            }

//            function createName(item, dir)
//            {
//                return matchPath(item, dir) ? createNameFromParentDir(dir) : FileInfo.baseName(dir);
//            }

//            function createProduct(item, dir, sources)
//            {
//                return {
//                    name: createName(item, dir),
//                    item: item,
//                    path: dir,
//                    sources: sources,
//                    dependencies: [],
//                    dependants: []
//                };
//            }

//            function createProductDependencies(product, products)
//            {
//                var includes = getIncludedFiles(product);

//                for(var i in products)
//                    tryProductDependency(product, includes, products[i]);
//            }

//            function isProjectEmpty(proj)
//            {
//                return !proj.products && !proj.projects;
//            }

//            function createProject(dir)
//            {
//                var product = getProduct(dir);

//                var proj = {
//                    name: FileInfo.baseName(dir),
//                    path: dir,
//                    products: product.item ? [product] : [],
//                    projects: getSubProjects(dir)
//                };

//                return proj;
//            }

//            function dependProducts(product, dependency)
//            {
//                addDependency(product, dependency);
//                addDependant(dependency, product);
//            }

//            function isNotIgnored(element)
//            {
//                return !RegExp(ignorePattern).test(element);
//            }

//            function isSourceFile(element)
//            {
//                return RegExp(cppPattern).test(element);
//            }

//            function getFileContent(file)
//            {
//                return TextFile(file).readAll();
//            }

//            function getFiles(dir)
//            {
//                return File.directoryEntries(dir, File.Files);
//            }

//            function getFilesFiltered(dir)
//            {
//                return getFiles(dir).filter(isNotIgnored);
//            }

//            function getFilesInDir(dir)
//            {
//                return appendPathToArray(getFilesFiltered(dir), dir);
//            }

//            function getItem(dir)
//            {
//                var item = getItemFromDir(dir);
//                return item ? item : getItemFromFiles(getFilesInDir(dir));
//            }

//            function getItemContentPattern(item)
//            {
//                return items[item].contentPattern;
//            }

//            function getItemFromDir(dir)
//            {
//                return Object.keys(items).find(matchDirToItem, dir);
//            }

//            function getItemFromFiles(files)
//            {
//                return Object.keys(items).find(matchFilesToItem, files);
//            }

//            function getItemPattern(item)
//            {
//                return items[item].pattern;
//            }

//            function getProduct(dir)
//            {
//                var item = getItem(dir);
//                return item ? createProduct(item, dir, getSourcesInDir(dir)) : {};
//            };

//            function getProductsFromProject(proj)
//            {
//                var products = [];

//                if(proj.products[0].item)
//                    products.push(proj.products[0]);

//                for(var i in proj.projects)
//                    products = products.concat(getProductsFromProject(proj.projects[i]));

//                return products;
//            }

//            function getSourcesInDir(dir)
//            {
//                return getFilesFiltered(dir).filter(isSourceFile);
//            }

//            function getDirs(dir)
//            {
//                return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);
//            }

//            function getDirsFiltered(dir)
//            {
//                return getDirs(dir).filter(isNotIgnored);
//            }

//            function getSubdirs(dir)
//            {
//                return appendPathToArray(getDirsFiltered(dir), dir);
//            }

//            function getSubProject(subdir)
//            {
//                return createProject(subdir);
//            }

//            function getSubProjects(dir)
//            {
//                var subProjects = [];
//                getSubdirs(dir).forEach(appendSubProject, subProjects);
//                return subProjects;
//            }

//            function hasContentPattern(item)
//            {
//                return getItemContentPattern(item);
//            }

//            function hasSourceExtension(file)
//            {
//                return element.endsWith("." + cppSourcesExtension);
//            }

//            function hasSourceFile(product, file)
//            {
//                return product.sources.contains(file);
//            }

//            function isProductHeaderOnly(product)
//            {
//                return !product.sources.some(hasSourceExtension);
//            }

//            function makePath(dir, file)
//            {
//                return FileInfo.joinPaths(dir, file);
//            }

//            function matchContent(item, file)
//            {
//                return hasContentPattern(item) ? matchFileContent(item, file) : true;
//            }

//            function matchDirToItem(item)
//            {
//                return matchPath(item, this);
//            }

//            function matchFileContent(item, file)
//            {
//                return RegExp(getItemContentPattern(item)).test(getFileContent(file));
//            }

//            function matchFilesToItem(item)
//            {
//                return this.some(matchFileToItem, item);
//            }

//            function matchFileToItem(file)
//            {
//                return matchPath(this, file) && matchContent(this, file);
//            }

//            function matchPath(item, path)
//            {
//                return RegExp(getItemPattern(item)).test(path);
//            }

//            function getIncludedFiles(product)
//            {
//                var includedFiles = {};

//                for(var i in product["sources"])
//                {
//                    var sourceFile = product["sources"][i];
//                    var content = TextFile(makePath(product["path"], sourceFile)).readAll();
//                    var regexp = /#include <|\"(.*)\"|>/g
//                    var result = [];
//                    while(result = regexp.exec(content))
//                        includedFiles[result[1]] = true;
//                }

//                return Object.keys(includedFiles);
//            }

//            function tryProductDependency(product, includes, other)
//            {
//                for(var i in includes)
//                {
//                    if(hasSourceFile(other, includes[i]))
//                    {
//                        dependProducts(product, other);
//                        break;
//                    }
//                }
//            }

//            function write(proj)
//            {
//                var file = TextFile(makePath(outPath, proj.name + ".qbs"), TextFile.WriteOnly);
//                file.writeLine("import qbs");
//                file.writeLine("");
//                writeProject(file, proj, "");
//                file.close();
//            }

//            function writeProduct(file, product, indent)
//            {
//                file.writeLine(indent + "    " + product.item);
//                file.writeLine(indent + "    {");
//                file.writeLine(indent + "        name: \"" + product.name + "\"");
//                file.writeLine(indent + "        path: \"" + product.path + "\"");
//                file.writeLine(indent + "    }");
//            }

//            function writeProject(file, proj, indent)
//            {
//                file.writeLine(indent + "Project");
//                file.writeLine(indent + "{");
//                file.writeLine(indent + "    name: \"" + proj.name + "\"");
//                file.writeLine(indent + "    property string target: project.installDirectory");

//                for(var i in proj.products)
//                    writeProduct(file, proj.products[i], indent)

//                for(var i in proj.projects)
//                    writeProject(file, proj.projects[i], indent + "    ");

//                file.writeLine(indent + "}");
//            }

//            function print(proj, indent)
//            {
//                console.info("PROJECT: " + proj.name + " (" + proj.path + ")");

//                if(projectFormat == ProjectFormat.Tree)
//                {
//                    for(var i in proj.projects)
//                        print(proj.projects[i], indent + "  ");
//                }

//                for(var i in proj.products)
//                    printProduct(proj.products[i]);
//            }

//            function printProduct(product)
//            {
//                console.info(product.item + "(" + product.name + ": " + product.path + ")");
//                for(var i in product.dependencies)
//                    console.info("+" + product.dependencies[i].path);
//                for(var i in product.dependants)
//                    console.info("-" + product.dependants[i].path);
//            }

//            function isAdditionalDir(dir)
//            {
//                return RegExp(additionalDirectoriesPattern).test(dir);
//            }

//            function getHigherItem(item, other)
//            {
//                var keys = Object.keys(items);
//                return keys.indexOf(item) > keys.indexOf(other) ? item : other;
//            }

//            function tryMergeProjectInAdditionalDir(proj)
//            {
//                return consolidateProjectsInAdditionalDirs(proj);
//            }

//            function mergeSubProductToProduct(product, subproduct)
//            {
//                product.item = getHigherItem(product.item, subproduct.item);
//                product.sources = product.sources.concat(subproduct.sources);
//                return true;
//            }

//            function tryMergeSubProductToProduct(product, subproduct)
//            {
//                return isAdditionalDir(subproduct.path) ? mergeSubProductToProduct(product, subproduct) : false;
//            }

//            function tryMergeSubProjectToProduct(product, subproject)
//            {
//                return subproject.products ? tryMergeSubProductToProduct(product, subproject.products) : false;
//            }

//            function mergeSubProjectToProduct(product, subproject)
//            {
//                if(tryMergeSubProjectToProduct(product, subproject))
//                    subproject[products] = [];
//            }

//            function mergeSubProjectsToProduct(product, subprojects)
//            {
//                for(var i in subprojects)
//                    mergeSubProjectToProduct(product, subprojects[i]);
//            }

//            function consolidateProjectsInAdditionalDirs(proj)
//            {
//                proj.projects = proj.projects.filter(tryMergeProjectInAdditionalDir);

//                if(proj.products)
//                    mergeSubProjectsToProduct(proj.products[0], proj.projects);

//                return proj.products || proj.projects;
//            }

//            function tryMergeProductsByName(product, products)
//            {
//                if(proj.products)
//                {
//                    var other = products.find(function(element)
//                    {
//                        if(product.name = element.name)
//                            return true;
//                    });

//                    if(other)
//                    {

//                    }
//                }
//            }

//            function consolidatProjectsByName(proj)
//            {
//                tryMergeProjectsByName(proj, getProductsFromProject(proj));
//            }

//            function consolidateProject(proj)
//            {
//                consolidateProjectsInAdditionalDirs(proj);
//                consolidatProjectsByName(proj);
//            }

//            //getProductsFromProject

//            var rootProject = createProject(rootPath);
//            consolidateProject(rootProject);
////            createDependencies(rootProject);
//            print(rootProject, "");
//            write(rootProject);

//            references = [ makePath(outPath, rootProject.name + ".qbs") ];
//            console.info("Probe run");

//        }
//    }

//    qbsSearchPaths: scanner.outPath
//    references: scanner.references
}
