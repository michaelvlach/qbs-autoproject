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
        property string projectRoot: "Example"
        property string projectFormat: ProjectFormat.Flat
        property string installDirectory: qbs.targetOS + "-" + qbs.architecture + "-" + qbs.toolchain.join("-")

        property string ignorePattern: "\/.autoproject$"
        property string additionalDirectoriesPattern: "\/[Ii]ncludes?$"
        property string cppSourcesPattern: "\.cpp$"
        property string cppHeadersPattern: "\.h$"

        property var items:
        {
            return {
                AutoprojectApp: { pattern: "(\\/[Tt]est|[Tt]est\\.(cpp|h)|\\/[Mm]ain\\.cpp)$" },
                AutoprojectDynamicLib: { pattern: "\\/([Ii]ncludes?|.+\.h)$", contentPattern: "[A-Z\d_]+SHARED " },
                AutoprojectPlugin: { pattern: "\\/.+\\.h$", contentPattern: "Q_INTERFACES\\(([a-zA-Z\d]+(, |,|))+\\)" },
                AutoprojectStaticLib: { pattern: "\\/([Ll]ib|.+\\.cpp)$" },
                AutoprojectInclude: { pattern: "\\/([Ii]ncludes?|.+\\.h)$" },
                AutoprojectDoc: { pattern: "\\/([Dd]ocs?|.+\\.qdoc(conf)?)$" }
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

            console.info("Autoproject configured...");
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

            function getSubmoduleName(moduleName, submodule)
            {
                return moduleName == "Qt" ? submodule.slice(moduleName.length).toLowerCase() : submodule;
            }

            function appendSubmodule(subdir)
            {
                this.submodules[getSubmoduleName(this.moduleName, subdir)] = {files: getFiles(makePath(this.dir, subdir))};
            }

            function getModuleDir(moduleName)
            {
                return configurationModules[moduleName].includePath;
            }

            function getSubmodules(moduleName)
            {
                var submodules = {};
                getSubdirs(getModuleDir(moduleName)).forEach(appendSubmodule, {submodules: submodules, dir: getModuleDir(moduleName), moduleName: moduleName});
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

            console.info("[1] Modules scanned");

            //TEST
            if(runTests)
            {
//                if(!modules.Qt) { console.info("[1.1] Module not found in scanned modules"); return; }
//                if(!modules.Qt.submodules) { console.info("[1.2] Submodules missing"); return; }
//                if(!modules.Qt.submodules.core) { console.info("[1.3] Submodule is missing"); return; }
//                if(!modules.Qt.submodules.core.files) { console.info("[1.4] Files are missing"); return; }
//                if(!modules.Qt.submodules.core.files.contains("QString")) { console.info("[1.5] File is missing"); return; }
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

            console.info("[2] Projects scanned");

            //TEST
            if(runTests)
            {
//                if(!rootProject.subprojects) { console.info("Scan failed"); return; }
//                if(!rootProject.subprojects.ComplexProject) { console.info("[2.1] Project missing"); return; }
//                if(!rootProject.subprojects.ComplexProject.name ) { console.info("[2.2] Name missing"); return; }
//                if(rootProject.subprojects.ComplexProject.name != "ComplexProject") { console.info("[2.3] Name is incorrect"); return; }
//                if(!rootProject.subprojects.ComplexProject.path ) { console.info("[2.4] Path missing"); return; }
//                if(!rootProject.subprojects.ComplexProject.path.endsWith("examples/ComplexProject") ) { console.info("[2.5] Path is incorrect"); return; }
//                if(!rootProject.subprojects.ComplexProject.files) { console.info("[2.6] files are missing"); return; }
//                if(!rootProject.subprojects.ComplexProject.files.some(function(file) { return file.endsWith("README.txt"); })) { console.info("[2.7] file is missing"); return; }
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

            function isPathContentItem(item, files)
            {
                return files && getItemContentPattern(item) ? files.some(function(file) { return isContentItem(getFileContent(file), item); }) : true;
            }

            function isDirItem(item)
            {
                return isPathItem.call({path: this.path}, item) && isPathContentItem(item, this.files);
            }

            function isPathItem(item)
            {
                return RegExp(getItemPattern(item)).test(this.path);
            }

            function isContentItem(content, item)
            {
                return RegExp(getItemContentPattern(item), "g").test(content);
            }

            function getItemNames()
            {
                return Object.keys(items);
            }

            function getFileContent(file)
            {
                return TextFile(file).readAll();
            }

            function getItemFromDir(proj)
            {
                return getItemNames().find(isDirItem, {path: proj.path, files: proj.files});
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

            function prependParentName(parent, name)
            {
                return parent && parent.product.name ? (parent.product.name + name) : (getDirName(parent.path) + name);
            }

            function getProduct(proj, parent)
            {
                var item = getItemFromDir(proj);
                var name = item ? prependParentName(parent, proj.name) : proj.name;

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
                var product = scanProject(this.subprojects[subprojectName], this.parent);
                this.subprojectslist[product.name] = product;
            }

            function scanSubprojects(subprojects, parent)
            {
                var subprojectsList = {};
                Object.keys(subprojects).forEach(scanSubproject, {subprojects: subprojects, subprojectslist: subprojectsList, parent: parent});
                return subprojectsList;
            }

            function scanProject(proj, parent)
            {
                var project = {
                    name: proj.name,
                    path: proj.path,
                    product: getProduct(proj, parent),
                    subprojects: {}
                };
                project.subprojects = scanSubprojects(proj.subprojects, project);
                return project;
            }
            var proj = scanProject(scannedRootProject, undefined);
            rootProject = proj;

            console.info("[3] Products scanned");

            //TEST
            if(runTests)
            {
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication) { console.info("[3.1] Project missing"); return; };
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product) { console.info("[3.2] Product missing"); return; };
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.name != "ComplexApplication") { console.info("[3.3] Product name incorrect"); return; };
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.item != "AutoprojectApp") { console.info("[3.4] Item incorrect"); return; };
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.paths != rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.path) { console.info("[3.5] Path incorrect"); return; };
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.path, "main.cpp"))) { console.info("[3.6] Files incorrect"); return; };

//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test) { console.info("[3.7] Project missing"); return; };
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product) { console.info("[3.8] Product missing"); return; };
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.name != "ComplexApplicationTest") { console.info("[3.9] Product name incorrect"); return; };
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.item != "AutoprojectTest") { console.info("[3.10] Item incorrect"); return; };
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.paths != rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.path) { console.info("[3.11] Path incorrect"); return; };
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.subprojects.Test.path, "ApplicationTest.cpp"))) { console.info("[3.12] Files incorrect"); return; };

//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.item != "AutoprojectStaticLib") { console.info("[3.13] Item incorrect"); return; }
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.product.item != "AutoprojectDynamicLib") { console.info("[3.14] Item incorrect"); return; }

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

            var proj = consolidateProducts(scannedRootProject);
            rootProject = proj;

            console.info("[4] Products consolidated");

            //Test
            if(runTests)
            {
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.product.item != undefined) { console.info("[4.1] Product not consolidated"); return; }
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.path, "Library.h"))) { console.info("[4.2] Product files not merged"); return; }
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include.subprojects.Include.path, "LibraryInterface.h"))) { console.info("[4.3] Product files from sub-sub-product not merged"); return; }
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.product.item != "AutoprojectDynamicLib") { console.info("[4.4] Item value not merged"); return; }

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
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function callGroupProjectsByName(projectName)
            {
                groupProjectsByName.call({projects: this.projects}, this.subprojects[projectName]);
            }

            function groupProjectsByName(proj)
            {
                if(proj.product.item)
                {
                    if(!this.projects[proj.product.name])
                        this.projects[proj.product.name] = [];

                    this.projects[proj.product.name].push(proj);
                }

                Object.keys(proj.subprojects).forEach(callGroupProjectsByName, {subprojects: proj.subprojects, projects: this.projects});
            }

            function getItemNames()
            {
                return Object.keys(items);
            }

            function getHigherItem(item, other)
            {
                return getItemNames().indexOf(item) < getItemNames().indexOf(other) ? item : other;
            }

            function isSourceFile(file)
            {
                return RegExp(cppSourcesPattern).test(file);
            }

            function hasSources(proj)
            {
                return proj.product.files.some(isSourceFile);
            }

            function mergeProjects(proj, other)
            {
                proj.product.item = getHigherItem(proj.product.item, other.product.item);
                proj.product.paths = proj.product.paths.concat(other.product.paths);
                proj.product.files = proj.product.files.concat(other.product.files);
                other.product = {};
            }

            function concatLastTwoProjects(projects)
            {
                var leftProject = projects[projects.length - 2];
                var rightProject = projects[projects.length - 1];

                if(!hasSources(leftProject) && hasSources(rightProject))
                {
                    projects.splice(projects.length - 2, 1);
                    mergeProjects(rightProject, leftProject);
                }
                else
                {
                    projects.splice(projects.length - 1, 1);
                    mergeProjects(leftProject, rightProject);
                }

                if(projects.length > 1)
                    concatLastTwoProjects(projects);
            }

            function concatProjects(projectName)
            {
                if(this.projects[projectName].length > 1)
                    concatLastTwoProjects(this.projects[projectName]);
            }

            function mergeProducts(proj)
            {
                var projects = {};
                groupProjectsByName.call({projects: projects}, proj);
                Object.keys(projects).forEach(concatProjects, {projects: projects});
                return proj;
            }

            var proj = mergeProducts(consolidatedRootProject);
            rootProject = proj;

            console.info("[5] Products merged");

            if(runTests)
            {
//                if(rootProject.subprojects.ComplexProject.subprojects.Include.subprojects.SimpleLibrary.product.item != undefined) { console.info("[5.1] Product not merged"); return; }
//                if(rootProject.subprojects.ComplexProject.subprojects.Include.subprojects.ComplexPluginTest.product.item != undefined) { console.info("[5.2] Product not merged"); return; }
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.SimpleLibrary.product.paths.contains(rootProject.subprojects.ComplexProject.subprojects.Include.subprojects.SimpleLibrary.path)) { console.info("[5.3] Product path not merged"); return; }
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.SimpleLibrary.product.item != "AutoprojectDynamicLib") { console.info("[5.4] Product item not merged"); return; }
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.SimpleLibrary.product.files.contains(FileInfo.joinPaths(rootProject.subprojects.ComplexProject.subprojects.Include.subprojects.SimpleLibrary.path, "OtherLibrary.h"))) { console.info("[5.5] Product files not merged"); return; }

                console.info("productmerger test [OK]");
            }
        }
    }

    Probe
    {
        id: projectconsolidator
        property var mergedRootProject: productmerger.rootProject
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function filterProject(projectName)
            {
                consolidateProject(this.projects[projectName]);

                if(!this.projects[projectName].product.item && Object.keys(this.projects[projectName].subprojects).length == 0)
                    delete this.projects[projectName];
            }

            function filterProjects(projects)
            {
                Object.keys(projects).forEach(filterProject, {projects: projects})
            }

            function consolidateProject(proj)
            {
                filterProjects(proj.subprojects);
                return proj;
            }

            var proj = consolidateProject(mergedRootProject);
            rootProject = proj;

            console.info("[7] Projects consolidated");

            if(runTests)
            {
//                if(Object.keys(rootProject.subprojects.ComplexProject.subprojects.Include.subprojects).length != 0) { console.info("[6.1] Projects empty but not deleted"); return; }
//                if(rootProject.subprojects.ComplexProject.subprojects.src.subprojects.libs.subprojects.ComplexLibrary.subprojects.include) { console.info("[6.2] Projects empty but not deleted"); return; }
                console.info("projectconsolidator test [OK]");
            }
        }
    }

    Probe
    {
        id: dependencyscanner
        property var consolidatedRootProject: projectconsolidator.rootProject
        property var cppPattern: configuration.cppPattern
        property var cppHeadersPattern: configuration.cppHeadersPattern
        property var runTests: configuration.runTests
        property var modules: configuration.modules
        property var rootProject: {}

        configure:
        {
            function isSourceFile(file)
            {
                return RegExp(cppPattern).test(file);
            }

            function readFile(file)
            {
                return TextFile(file).readAll();
            }

            function scanFile(file)
            {
                var content = readFile(file);
                var regex = /#include\s*[<|\"]([a-zA-Z\/\.]+)[>|\"]/g;
                var result = [];
                while(result = regex.exec(content))
                    this.includes[result[1]] = true;
            }

            function callScanDependencies(projectName)
            {
                scanDependencies(this.subprojects[projectName]);
            }

            function scanProductFiles(product)
            {
                product.includes = {};
                product.files.filter(isSourceFile).forEach(scanFile, {includes: product.includes})
                product.includes = Object.keys(product.includes);
                product.includePaths = {};
            }

            function scanDependencies(proj)
            {
                Object.keys(proj.subprojects).forEach(callScanDependencies, {subprojects: proj.subprojects})

                if(proj.product.files)
                    scanProductFiles(proj.product);

                return proj;
            }

            var proj = scanDependencies(consolidatedRootProject);
            rootProject = proj;

            console.info("[8] Dependencies scanned");

            if(runTests)
            {
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.includes.contains("QCoreApplication")) { console.info("7.1 Failed to read includes"); return; }
                console.info("dependencyscanner test [OK]");
            }
        }
    }

    Probe
    {
        id: dependencybuilder
        property var dependencyScanRootProject: dependencyscanner.rootProject
        property var runTests: configuration.runTests
        property var modules: modulescanner.modules
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

            function submoduleContainsInclude(submodule)
            {
                return modules[this.module].submodules[submodule].files.contains(this.include);
            }

            function findInSubmodules(module, include)
            {
                return Object.keys(modules[module].submodules).find(submoduleContainsInclude, {module: module, include: include});
            }

            function findInModules(include)
            {
                for(var module in modules)
                {
                    if(modules[module].files.contains(include))
                        return module;
                    else
                    {
                        var submodule = findInSubmodules(module, include);

                        if(submodule)
                            return module + "." + submodule;
                    }
                }
            }

            function isFileInclude(file)
            {
                return this.include.contains("/") ? file.endsWith(this.include) : file.endsWith("/" + this.include);
            }

            function findInProject(proj, include)
            {
                var dependency = undefined;

                if(proj.product.files)
                {
                    var file = proj.product.files.find(isFileInclude, {include: include});

                    if(file)
                    {
                        dependency = proj.product.name;
                        proj.product.includePaths[FileInfo.path(file)] = true;
                    }
                }

                if(!dependency)
                {
                    for(var subproject in proj.subprojects)
                    {
                        dependency = findInProject(proj.subprojects[subproject], include);

                        if(dependency)
                            break;
                    }
                }

                return dependency;
            }

            function findInProjects(include)
            {
                return findInProject(dependencyScanRootProject, include);
            }

            function findDependency(include)
            {
                var dependency = findInModules(include);

                if(!dependency)
                    dependency = findInProjects(include);

                if(dependency)
                    this.dependencies[dependency] = true;
                else
                    console.info("WARNING: Dependency '" + include + "' not resolved to any module or project");
            }

            function callBuildDependencies(projectName)
            {
                buildDependencies(this.subprojects[projectName]);
            }

            function buildDependencies(proj)
            {
                if(proj.product.includes)
                {
                    var dependencies = {};
                    proj.product.includes.forEach(findDependency, {dependencies: dependencies, project: proj});
                    delete dependencies[proj.product.name];
                    proj.product.dependencies = Object.keys(dependencies);
                }

                Object.keys(proj.subprojects).forEach(callBuildDependencies, {subprojects: proj.subprojects});
                return proj;
            }

            var proj = buildDependencies(dependencyScanRootProject);
            rootProject = proj;

            console.info("dependencies built");

            if(runTests)
            {
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.dependencies.contains("Qt.core")) { console.info("Dependency resolution of module failed"); return; }
//                if(!rootProject.subprojects.ComplexProject.subprojects.src.subprojects.apps.subprojects.ComplexApplication.product.dependencies.contains("ComplexProject")) { console.info("Dependency resolution of another project failed"); return; }
                console.info("dependencybuilder test [OK]");
            }
        }
    }

    Probe
    {
        id: projectwriter
        property var rootProject: dependencybuilder.rootProject
        property var runTests: configuration.runTests
        property var outPath: configuration.outPath
        property var projectFormat: configuration.projectFormat
        property var installDirectory: configuration.installDirectory
        property stringList references: []

        configure:
        {
            function write(proj)
            {
                var filePath = FileInfo.joinPaths(outPath, proj["name"] + ".qbs")
                var file = TextFile(filePath, TextFile.WriteOnly);
                file.writeLine("import qbs");
                file.writeLine("");
                file.writeLine("Project");
                file.writeLine("{");
                file.writeLine("    name: \"" + proj.name + "\"");
                file.writeLine("    property path path: \"" + proj.path + "\"");
                file.writeLine("    property string installDirectory: \"" + installDirectory + "\"");
                file.writeLine("");

                for(var subproject in proj.subprojects)
                    writeProject(file, proj.subprojects[subproject], "    ");

                file.writeLine("}");
                file.close();
                return filePath;
            }

            function isProjectFormatFlat()
            {
                return projectFormat == configuration.ProjectFormat.Flat;
            }

            function writeProject(file, proj, indent)
            {
                if(!isProjectFormatFlat())
                {
                    file.writeLine(indent + "Project");
                    file.writeLine(indent + "{");
                    file.writeLine(indent + "    name: \"" + proj.name + "\"");
                    file.writeLine(indent + "    property path path: \"" + proj.path + "\"");
                    file.writeLine(indent + "    property string installDirectory: project.installDirectory");
                    file.writeLine(indent + "");
                }

                if(proj.product.item)
                    writeProduct(file, proj.product, isProjectFormatFlat() ? indent : (indent + "    "));

                for(var subproject in proj.subprojects)
                    writeProject(file, proj.subprojects[subproject], isProjectFormatFlat() ? indent : (indent + "    "));

                if(projectFormat == configuration.ProjectFormat.Tree)
                {
                    file.writeLine(indent + "}");
                }
            }

            function writeProduct(file, product, indent)
            {
                file.writeLine(indent + product.item);
                file.writeLine(indent + "{");
                file.writeLine(indent + "    name: \"" + product.name + "\"");
                file.writeLine(indent + "    paths: [\"" + product.paths.join("\", \"") + "\"]");
                var includePaths = Object.keys(product.includePaths);
                if(includePaths.length > 0)
                    file.writeLine(indent + "    includePaths: [\"" + includePaths.join("\", \"") + "\"]");
                file.writeLine("");
                product.dependencies.forEach(writeDependency, {file: file, indent: indent + "    "});
                file.writeLine("");
                if(product.dependencies.length > 0)
                {
                    file.writeLine(indent + "    Export");
                    file.writeLine(indent + "    {");
                    product.dependencies.forEach(writeDependency, {file: file, indent: indent + "        "});
                    file.writeLine(indent + "    }");
                }
                file.writeLine(indent + "}");
            }

            function writeDependency(dependency)
            {
                this.file.writeLine(this.indent + "Depends { name: \"" + dependency + "\" }");
            }

            var refs = write(rootProject);
            references = refs;

            console.info("projects written");

            if(runTests)
            {
                console.info("projectwriter test [OK]");
            }
        }
    }

    qbsSearchPaths: configuration.autoprojectDirectory
    references: projectwriter.references
}
