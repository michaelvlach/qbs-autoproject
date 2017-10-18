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
            };
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
                AutoprojectDynamicLib: { pattern: "\/.+\.h$", contentPattern: "[A-Z\d]+SHARED " },
                AutoprojectPlugin: { pattern: "\/.+\.h$", contentPattern: "Q_INTERFACES\(([a-zA-Z\d]+(, |,|))+\)" },
                AutoprojectStaticLib: { pattern: "\/([Ll]ib|.+\.cpp)$" },
                AutoprojectInclude: { pattern: "\/.+\.h$" },
                AutoprojectDoc: { pattern: "\/([Dd]ocs?|.+\.qdoc(conf)?)$" }
            };
        }

        property var modules:
        {
            return {
                Qt: { includePath: "C:/Qt/5.10.0/msvc2017_64/include" }
            };
        }
        //--------------------//
        //END OF CONFIGURATION//
        //--------------------//

        property path rootPath: ""
        property path outPath: ""
        property string cppPattern: ""
        property bool runTests: true

        configure:
        {
            function makePath(path, subpath)
            {
                return FileInfo.joinPaths(path, subpath);
            }

            var root = makePath(sourceDirectory, projectRoot);
            var out = makePath(sourceDirectory, autoprojectDirectory);
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

        property var configurationModules: configuration.modules
        property var runTests: configuration.runTests
        property var modules: {}

        configure:
        {
            function makePath(path, subpath)
            {
                return FileInfo.joinPaths(path, subpath);
            }

            function getSubdirs(dir)
            {
                return File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);
            }

            function getFiles(dir)
            {
                return File.directoryEntries(dir, File.Files);
            }

            function appendSubmodule(subdir)
            {
                this.submodules[subdir] = {files: getFiles(makePath(this.dir, subdir))};
            }

            function getModuleDir(moduleName)
            {
                return configurationModules[moduleName].includePath;
            }

            function getSubmodules(moduleName)
            {
                var submodules = {};
                getSubdirs(getModuleDir(moduleName)).forEach(appendSubmodule, {submodules: submodules, dir: getModuleDir(moduleName)});
                return submodules;
            }

            function getModuleNames()
            {
                return Object.keys(configuration.modules);
            }

            function scanModule(moduleName)
            {
                this[moduleName] = {files: getFiles(getModuleDir(moduleName)), submodules: getSubmodules(moduleName)};
            }

            var scannedModules = {};
            getModuleNames().forEach(scanModule, scannedModules);
            modules = scannedModules;

            console.info("Modules scanned");

            //TEST
            if(runTests)
            {
                if(!modules.Qt) { console.info("[1.1] Module not found in scanned modules"); return; }
                if(!modules.Qt.submodules) { console.info("[1.2] Submodules missing"); return; }
                if(!modules.Qt.submodules.QtCore) { console.info("[1.3] Submodule is missing"); return; }
                if(!modules.Qt.submodules.QtCore.files) { console.info("[1.4] Files are missing"); return; }
                if(!modules.Qt.submodules.QtCore.files.contains("QString")) { console.info("[1.5] File is missing"); return; }
                console.info("modulescanner test [OK]");
            }
        }
    }

    Probe
    {
        id: projectscanner

        property var rootPath: configuration.rootPath
        property var ignorePattern: configuration.ignorePattern
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function makePath(path, subpath)
            {
                return FileInfo.joinPaths(path, subpath);
            }

            function appendPath(element, index, array)
            {
                array[index] = makePath(this.path, element);
            }

            function appendPathToAll(array, path)
            {
                array.forEach(appendPath, {path: path});
                return array;
            }

            function isNotIgnored(element)
            {
                return !RegExp(ignorePattern).test(element);
            }

            function getSubdirs(dir)
            {
                return appendPathToAll(File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot).filter(isNotIgnored), dir);
            }

            function getFiles(dir)
            {
                return appendPathToAll(File.directoryEntries(dir, File.Files).filter(isNotIgnored), dir);
            }

            function appendSubproject(subdir)
            {
                var proj = getProject(subdir);
                this.subprojects[proj.name] = proj;
            }

            function getSubprojects(dir)
            {
                var subprojects = {};
                getSubdirs(dir).forEach(appendSubproject, {subprojects: subprojects});
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

            console.info("Projects scanned");

            //TEST
            if(runTests)
            {
                if(!rootProject.subprojects) { console.info("Scan failed"); return; }
                if(!rootProject.subprojects.ComplexProject) { console.info("[2.1] Project missing"); return; }
                if(!rootProject.subprojects.ComplexProject.name ) { console.info("[2.2] Name missing"); return; }
                if(rootProject.subprojects.ComplexProject.name != "ComplexProject") { console.info("[2.3] Name is incorrect"); return; }
                if(!rootProject.subprojects.ComplexProject.path ) { console.info("[2.4] Path missing"); return; }
                if(!rootProject.subprojects.ComplexProject.path.endsWith("examples/ComplexProject") ) { console.info("[2.5] Path is incorrect"); return; }
                if(!rootProject.subprojects.ComplexProject.files) { console.info("[2.6] files are missing"); return; }
                if(!rootProject.subprojects.ComplexProject.files.some(function(file) { return file.endsWith("README.txt"); })) { console.info("[2.7] file is missing"); return; }
                console.info("projectscanner test [OK]");
            }
        }
    }

    Probe
    {
        id: productscanner

        property var scannedRootProject: projectscanner.rootProject
        property var items: configuration.items
        property var cppPattern: configuration.cppPattern
        property var runTests: configuration.runTests
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

            function getItemPattern(item)
            {
                return items[item].pattern;
            }

            function getItemContentPattern(item)
            {
                return items[item].contentPattern;
            }

            function isPathItem(item)
            {
                return RegExp(getItemPattern(item)).test(this.path);
            }

            function isContentItem(content, item)
            {
                return RegExp(getItemContentPattern(item)).test(content);
            }

            function getItemNames()
            {
                return Object.keys(items);
            }

            function getFileContent(file)
            {
                return TextFile(file).readAll();
            }

            function getItemFromDir(dir)
            {
                return getItemNames().find(isPathItem, {path: dir});
            }

            function isFileContentItem(file)
            {
                return !getItemContentPattern(this.item) || isContentItem(getFileContent(file), this.item);
            }

            function isFileItem(file)
            {
                return isPathItem.call({path: file}, this.item) && isFileContentItem.call({item: this.item}, file);
            }

            function areFilesItem(item)
            {
                return this.files.some(isFileItem, {item: item});
            }

            function getItemFromFiles(files)
            {
                return getItemNames().find(areFilesItem, {files: files});
            }

            function getParentDir(dir)
            {
                return FileInfo.path(dir);
            }

            function getDirName(dir)
            {
                return FileInfo.baseName(dir);
            }

            function getParentDirName(dir)
            {
                return getDirName(getParentDir(dir));
            }

            function prependParentName(path, name)
            {
                return getParentDirName(path) + name;
            }

            function getProductName(proj, item)
            {
                return !item ? proj.name : prependParentName(proj.path, proj.name);
            }

            function getProduct(proj)
            {
                var item = getItemFromDir(proj.path);
                var name = getProductName(proj, item);

                if(!item)
                    item = getItemFromFiles(proj.files);

                return item ? {
                    item: item,
                    name: name,
                    paths: [proj.path],
                    files: proj.files
                } : {};
            }

            function scanSubproject(subprojectName)
            {
                var product = scanProject(this.subprojects[subprojectName]);
                this.subprojectslist[product.name] = product;
            }

            function scanSubprojects(subprojects)
            {
                var subprojectsList = {};
                Object.keys(subprojects).forEach(scanSubproject, {subprojects: subprojects, subprojectslist: subprojectsList});
                return subprojectsList;
            }

            function scanProject(proj)
            {
                return {
                    name: proj.name,
                    path: proj.path,
                    product: getProduct(proj),
                    subprojects: scanSubprojects(proj.subprojects)
                };
            }
            var proj = scanProject(scannedRootProject);
            rootProject = proj;

            console.info("Products scanned");

            //TEST
            if(runTests)
            {
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication) { console.info("[3.1] Project missing"); return; };
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product) { console.info("[3.2] Product missing"); return; };
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.name != "ComplexApplication") { console.info("[3.3] Product name incorrect"); return; };
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.item != "AutoprojectApp") { console.info("[3.4] Item incorrect"); return; };
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.paths != rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.path) { console.info("[3.5] Path incorrect"); return; };
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.path, "main.cpp"))) { console.info("[3.6] Files incorrect"); return; };

                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test) { console.info("[3.7] Project missing"); return; };
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product) { console.info("[3.8] Product missing"); return; };
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.name != "ComplexApplicationTest") { console.info("[3.9] Product name incorrect"); return; };
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.item != "AutoprojectTest") { console.info("[3.10] Item incorrect"); return; };
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.paths != rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.path) { console.info("[3.11] Path incorrect"); return; };
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.path, "ApplicationTest.cpp"))) { console.info("[3.12] Files incorrect"); return; };

                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.item != "AutoprojectStaticLib") { console.info("[3.13] Item incorrect"); return; }
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.product.item != "AutoprojectDynamicLib") { console.info("[3.14] Item incorrect"); return; }

                console.info("productscanner test [OK]");
            }
        }
    }

    Probe
    {
        id: productconsolidator

        property var scannedRootProject: productscanner.rootProject
        property var additionalDirectoriesPattern: configuration.additionalDirectoriesPattern
        property var items: configuration.items
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function getItemNames()
            {
                return Object.keys(items);
            }

            function getHigherItem(item, other)
            {
                return getItemNames().indexOf(item) < getItemNames().indexOf(other) ? item : other;
            }

            function mergeArrays(array, other)
            {
                return array.concat(other);
            }

            function isValid(product)
            {
                return product.item != undefined;
            }

            function mergeProduct(projectName)
            {
                if(isValid(this.product) && isValid(this.subprojects[projectName].product))
                {
                    this.product.item = getHigherItem(this.product.item, this.subprojects[projectName].product.item);
                    this.product.paths = mergeArrays(this.product.paths, this.subprojects[projectName].product.paths);
                    this.product.files = mergeArrays(this.product.files, this.subprojects[projectName].product.files);
                    this.subprojects[projectName].product = {};
                }
            }

            function isAdditionalProject(projectName)
            {
                return RegExp(additionalDirectoriesPattern).test(this.subprojects[projectName].path);
            }

            function consolidateProduct(proj)
            {
                if(proj.product)
                    Object.keys(proj.subprojects).filter(isAdditionalProject, {subprojects: proj.subprojects}).forEach(mergeProduct, {subprojects: proj.subprojects, product: proj.product})
            }

            function callConsolidateProducts(projectName)
            {
                consolidateProducts(this.subprojects[projectName]);
            }

            function consolidateProducts(proj)
            {
                Object.keys(proj.subprojects).forEach(callConsolidateProducts, {subprojects: proj.subprojects});
                consolidateProduct(proj);
                return proj;
            }

            console.info(scannedRootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.item);
            console.info(scannedRootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.product.item);

            var proj = consolidateProducts(scannedRootProject);
            rootProject = proj;

            console.info("Products consolidated");

            //Test
            if(runTests)
            {
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.product.item != undefined) { console.info("[4.1] Product not consolidated"); return; }
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.path, "Library.h"))) { console.info("[4.2] Product files not merged"); return; }
                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.subprojects.Include.path, "LibraryInterface.h"))) { console.info("[4.3] Product files from sub-sub-product not merged"); return; }
                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.item != "AutoprojectDynamicLib") { console.info("[4.4] Item value not merged"); return; }

                console.info("productconsolidator test [OK]");
            }
        }
    }

    Probe
    {
        id: productmerger
        property var consolidatedRootProject: productconsolidator.rootProject
        property var cppSourcesPattern: configuration.cppSourcesPattern
        property var items: configuration.items
        property var rootProject: {}

        configure:
        {
            function mergeProducts(proj)
            {

            }

            var proj = mergeProducts(consolidatedRootProject);
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
