import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    id: autoproject

    //Common functions
    property var makePath: (function(path, subpath) { return FileInfo.joinPaths(path, subpath); })
    property var getFilePath: (function(file) { return FileInfo.path(file); })
    property var getFileName: (function(file) { return FileInfo.baseName(file); })
    property var print: (function(message) { console.info(message); })
    property var getDirectories: (function(directory) { var dirs = File.directoryEntries(directory, File.Dirs | File.NoDotAndDotDot); dirs.forEach(prependPath, { path: directory }); return dirs; })
    property var getFiles: (function(directory) { var files = File.directoryEntries(directory, File.Files); files.forEach(prependPath, { path: directory }); return files; })
    property var getKeys: (function(object) { return Object.keys(object); })
    property var prependPath: (function(file, index, array) { array[index] = makePath(this.path, file); })
    property var forAll: (function(object, func, context) { context.object = object; context.func = func; getKeys(object).forEach(callByName, context); return object; })
    property var callByName: (function(name) { this.name = name; this.func.call(this, this.object[name]); })
    property var isValid: (function(object) { return object && getKeys(object).length > 0; })
    property var addFind: (function()
    {
        if(!Array.prototype.find)
        {
            Object.defineProperty(Array.prototype, 'find',
            {
                value: function(predicate)
                {
                    if(this == null) throw new TypeError('"this" is null or not defined');
                    if(typeof predicate !== 'function') throw new TypeError('predicate must be a function');
                    for(var k = 0; k < (Object(this).length >>> 0); k++) if(predicate.call(arguments[1], Object(this)[k], k, Object(this))) return Object(this)[k];
                    return undefined;
                }
            });
        }
    })
    //End of common functions

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
        property var DependencyMode:
        {
            return {
                Default: "Default",
                NoHeaderOnly: "NoHeaderOnly",
                Disabled: "Disabled"
            }
        }

        //-------------//
        //CONFIGURATION//
        //-------------//
        property string name: "Autoproject"
        property string autoprojectDirectory: ".autoproject"
        property string projectRoot: "Example"
        property string projectFormat: ProjectFormat.Flat
        property string dependencyMode: DependencyMode.NoHeaderOnly
        property bool dryRun: false
        property string installDirectory: qbs.targetOS + "-" + qbs.architecture + "-" + qbs.toolchain.join("-")

        property string ignorePattern: "\\/.autoproject$"
        property string additionalDirectoriesPattern: "\\/[Ii]ncludes?$"
        property string cppSourcesPattern: "\\.cpp$"
        property string cppHeadersPattern: "\\.h$"

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
        property bool runTests: false

        configure:
        {
            print(name + " @ " + Date());
            print(Array(39).join("-"));
            print("Running steps...");
            print("[1/11] Parsing configuration...");
            var start = Date.now();
            var root = makePath(sourceDirectory, projectRoot);
            var out = makePath(sourceDirectory, autoprojectDirectory);
            var cpp = cppSourcesPattern + "|" + cppHeadersPattern;
            rootPath = root;
            outPath = out;
            cppPattern = cpp;

            //Print configured variables
            print("    Project root: " + rootPath);
            print("    Output path: " + outPath);
            print("    Install path: " + makePath(qbs.installRoot, installDirectory));
            print("    Output format: " + projectFormat);
            print("    Dependency mode: " + dependencyMode);
            print("    Items: \n        " + getKeys(items).join("\n        "));
            print("    Modules: \n        " + getKeys(modules).join("\n        "));

            var time = Date.now() - start;
            print("[1/11] Done (" + time + "ms)");
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
            function getSubmoduleName(directory, moduleName)
            {
                return (directory.startsWith(moduleName) ? directory.slice(moduleName.length) : directory).toLowerCase();
            }

            function addSubmodule(directory)
            {
                this.submodules[getSubmoduleName(getFileName(directory), this.moduleName)] = { includePath: directory, files: getFiles(directory) };
            }

            function getModuleDirectory(moduleName)
            {
                return configurationModules[moduleName].includePath;
            }

            function getSubmodules(directories, moduleName)
            {
                var submodules = {};
                directories.forEach(addSubmodule, { submodules: submodules, moduleName: moduleName });
                return submodules;
            }

            function scanModule(module)
            {
                module.files = getFiles(module.includePath);
                module.submodules = getSubmodules(getDirectories(module.includePath), this.name);
                print("    " + this.name);
            }

            function scanModules(modules)
            {
                return forAll(modules, scanModule, {});
            }

            print("[2/11] Scanning modules...");
            var start = Date.now();
            var scannedModules = scanModules(configurationModules);
            modules = scannedModules;

            //TEST
            if(runTests)
            {
                print("    Running tests...");
                if(!modules.Qt) { print("    FAIL: 'Qt' module is missing"); return; }
                if(!modules.Qt.submodules) { print("    FAIL: 'Qt' module is missing 'submodules'"); return; }
                if(!modules.Qt.submodules.core) { print("    FAIL: 'Qt.core' submodule is missing"); return; }
                if(!modules.Qt.submodules.core.includePath) { print("    FAIL: 'Qt.core' submodule is missing 'includePath'"); return; }
                if(modules.Qt.submodules.core.includePath != makePath(modules.Qt.includePath, "QtCore")) { print("    FAIL: 'Qt.core' has incorrect 'includePath' --- EXPECTED: \"" + makePath(modules.Qt.includePath, "QtCore") + "\", ACTUAL: \"" + modules.Qt.submodules.core.includePath) + "\""; return; }
                if(!modules.Qt.submodules.core.files) { print("    FAIL: 'Qt.core' submodule is missing files"); return; }
                if(!modules.Qt.submodules.core.files.contains(makePath(modules.Qt.submodules.core.includePath, "QString"))) { print("    FAIL: 'Qt.core' is missing 'QString' file"); return; }
                print("    [Ok]");
            }

            var time = Date.now() - start;
            print("[2/11] Done (" + time + "ms)");
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
            function isNotIgnored(element)
            {
                return !RegExp(ignorePattern).test(element);
            }

            function appendSubproject(directory)
            {
                var project = getProject(directory);
                this.subprojects[project.name] = project;
            }

            function getSubprojects(directory)
            {
                var subprojects = {};
                getDirectories(directory).filter(isNotIgnored).forEach(appendSubproject, { subprojects: subprojects });
                return subprojects;
            }

            function getProject(directory)
            {
                print("    " + FileInfo.baseName(directory) + " (" + directory + ")");
                return {
                    name: FileInfo.baseName(directory),
                    product: {},
                    path: directory,
                    files: getFiles(directory).filter(isNotIgnored),
                    subprojects: getSubprojects(directory)
                };
            }

            print("[3/11] Creating projects...");
            var start = Date.now();
            var project = getProject(rootPath);
            rootProject = project;

            //TEST
            if(runTests)
            {
                print("    Running tests...");
                if(getKeys(rootProject).join(",") != "name,product,path,files,subprojects") { print("    FAIL: Failed to project values --- EXPECTED: \"name,product,path,files,subprojects\", ACTUAL: \"" + getKeys(rootProject) + "\""); return; }
                if(rootProject.path != rootPath) { print("    FAIL: Root project path is incorrect, EXPECTED: \"" + rootPath + "\", ACTUAL: \"" + rootProject.path + "\""); return; }
                if(rootProject.name != "Example") { print("    FAIL: Root project name is incorrect --- EXPECTED: \"Example\", ACTUAL: \"" + rootProject.name + "\""); return; }
                if(!rootProject.subprojects) { print("    FAIL: Root project is missing 'subprojects'"); return; }
                if(getKeys(rootProject.subprojects).join(",") != "Doc,Include,src") { print("    FAIL: Failed to detect subprojects --- EXPECTED: \"Doc,Include,src\", ACTUAL: \"" + getKeys(rootProject.subprojects) + "\""); return; }
                if(!rootProject.subprojects.Include.path) { print("    FAIL: Project 'rootProject.subprojects.Include' is missing 'path'"); return; }
                if(rootProject.subprojects.Include.path != makePath(rootProject.path, "Include")) { print("    FAIL: 'rootProject.subprojects.Include' project 'path' is incorrect --- EXPECTED: \"" + makePath(rootProject.path, "Include") + "\", ACTUAL: \"" + rootProject.subprojects.Include.path + "\""); return; }
                if(!rootProject.subprojects.Include.subprojects) { print("    FAIL: 'rootProject.subprojects.Include' is missing 'subprojects'"); return; }
                if(!getKeys(rootProject.subprojects.Include.subprojects).contains("MyLibrary")) { print("    FAIL: 'rootProject.subprojects.Include' is missing subproject 'MyLibrary'"); return; }
                if(!rootProject.subprojects.Include.subprojects.MyLibrary.files) { print("    FAIL: 'rootProject.subprojects.Include.subprojects.MyLibrary' is missing 'files'"); return; }
                if(!rootProject.subprojects.Include.subprojects.MyLibrary.files.contains(makePath(rootProject.subprojects.Include.subprojects.MyLibrary.path, "MyLibrary.h"))) { print("    FAIL: 'rootProject.subprojects.Include.subprojects.MyLibrary' is missing files 'MyLibrary.h'"); return; }
                print("    [Ok]");
            }

            var time = Date.now() - start;
            console.info("[3/11] Done (" + time + "ms)");
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
                return isPathItem.call({ path: this.path }, item) && isPathContentItem(item, this.files);
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
                return getKeys(items);
            }

            function getFileContent(file)
            {
                return TextFile(file).readAll();
            }

            function getItemFromProjectPath(project)
            {
                return getItemNames().find(isDirItem, { path: project.path, files: project.files });
            }

            function isFileContentItem(file)
            {
                return !getItemContentPattern(this.item) || isContentItem(getFileContent(file), this.item);
            }

            function isFileItem(file)
            {
                return isPathItem.call({ path: file }, this.item) && isFileContentItem.call({ item: this.item }, file);
            }

            function areFilesItem(item)
            {
                return this.files && this.files.some(isFileItem, { item: item });
            }

            function getItemFromProjectFiles(files)
            {
                return getItemNames().find(areFilesItem, { files: files });
            }

            function prependParentName(parent, name)
            {
                if(parent)
                    return parent.product.name ? (parent.product.name + name) : (getFileName(parent.path) + name);
                else
                    return name;
            }

            function getProduct(project, parent)
            {
                var name = project.name;
                var item = getItemFromProjectPath(project);

                if(!item)
                    item = getItemFromProjectFiles(project.files);
                else
                    name = prependParentName(parent, project.name);

                if(item)
                {
                    project.product.item = item;
                    project.product.name = name;
                    project.product.paths = [project.path];
                    project.product.files = project.files;
                    project.product.includes = {};
                    project.product.dependencies = {};
                    project.product.includePaths = {};
                    project.product.includedPaths = {};
                    project.product.headerOnly = false;
                    print("    " + project.product.name + " (" + project.product.item + "): " + project.path);
                }

                return project.product;
            }

            function scanSubprojects(project)
            {
                return forAll(project.subprojects, function(subproject) { scanProject(subproject, this.project) }, { project: project });
            }

            function scanProject(project, parent)
            {
                project.product = getProduct(project, parent);
                project.subprojects = scanSubprojects(project);
                return project;
            }

            print("[4/11] Creating products...");
            var start = Date.now();
            addFind();
            var project = scanProject(scannedRootProject, undefined);
            rootProject = project;

            //TEST
            if(runTests)
            {
                print("    Running tests...");
                if(getKeys(rootProject.subprojects.Include.product).join(",") != "item,name,paths,files,includes,dependencies,includePaths,includedPaths,headerOnly") { print("    FAIL: Failed to detect product values --- EXPECTED: \"item,name,paths,files,includes,dependencies,includePaths,includedPaths,headerOnly\", ACTUAL: \"" + getKeys(rootProject.subprojects.Include.product) + "\""); return; }
                if(rootProject.subprojects.Include.product.name != "ExampleInclude") { print("    FAIL: Incorrect name of product 'rootProject.subprojects.Include' --- EXPECTED: \"ExampleInclude\", ACTUAL: \"" + rootProject.subprojects.Include.product.name + "\""); return; }
                if(rootProject.subprojects.Include.product.item != "AutoprojectInclude") { print("    FAIL: Incorrect item of product 'rootProject.subprojects.Include' --- EXPECTED: \"AutoprojectInclude\", ACTUAL: \"" + rootProject.subprojects.Include.product.item + "\""); return; }
                if(!rootProject.subprojects.Include.product.files.contains(makePath(rootProject.subprojects.Include.path, "Common.h"))) { print("    FAIL: Project 'rootProject.subprojects.Include' is missing file 'Common.h'"); return; }
                if(rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.item != "AutoprojectApp") { print("    FAIL: Incorrect item of product 'rootProject.subprojects.src.subprojects.apps.subprojects.Application' --- EXPECTED: \"AutoprojectApp\", ACTUAL: \"" + rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.item + "\""); return; }
                if(rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.name != "Application") { print("    FAIL: Incorrect name of product 'rootProject.subprojects.src.subprojects.apps.subprojects.Application' --- EXPECTED: \"Application\", ACTUAL: \"" + rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.name + "\""); return; }
                if(rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.name != "Application") { print("    FAIL: Incorrect name of product 'rootProject.subprojects.src.subprojects.apps.subprojects.Application' --- EXPECTED: \"Application\", ACTUAL: \"" + rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.name + "\""); return; }
                if(rootProject.subprojects.src.subprojects.libs.subprojects.Library.product.item != "AutoprojectStaticLib") { print("    FAIL: Incorrect item of product 'rootProject.subprojects.src.subprojects.libs.subprojects.Library' --- EXPECTED: \"AutoprojectStaticLib\", ACTUAL: \"" + rootProject.subprojects.src.subprojects.libs.subprojects.Library.product.item + "\""); return; }
                print("    [Ok]");
            }

            var time = Date.now() - start;
            console.info("[4/11] Done (" + time + "ms)");
        }
    }

    Probe
    {
        id: productmerger

        property var scannedRootProject: productscanner.rootProject
        property var additionalDirectoriesPattern: configuration.additionalDirectoriesPattern
        property var items: configuration.items
        property var itemNames: getKeys(items)
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function getHigherItem(item, other)
            {
                return itemNames.indexOf(item) < itemNames.indexOf(other) ? item : other;
            }

            function mergeArrays(array, other)
            {
                return array.concat(other);
            }

            function mergeProduct(project)
            {
                if(isValid(project.product) && isAdditionalDirectory(project.path))
                {
                    this.product.item = getHigherItem(this.product.item, project.product.item);
                    this.product.paths = mergeArrays(this.product.paths, project.product.paths);
                    this.product.files = mergeArrays(this.product.files, project.product.files);
                    print("    '" + project.name + "' (" + project.path + ") ---> '" + this.product.name + "' (" + this.product.paths[0] + ")");
                    project.product = {};
                }
            }

            function isAdditionalDirectory(directory)
            {
                return RegExp(additionalDirectoriesPattern).test(directory);
            }

            function mergeProducts(project)
            {
                if(isValid(project.product))
                    forAll(project.subprojects, mergeProduct, { product: project.product })
            }

            function mergeProject(project)
            {
                forAll(project.subprojects, function(subproject) { mergeProject(subproject); }, {});
                mergeProducts(project);
                return project;
            }

            print("[5/11] Merging products...");
            var start = Date.now();
            var project = mergeProject(scannedRootProject);
            rootProject = project;

            //Test
            if(runTests)
            {
                print("    Running tests...");
                if(isValid(rootProject.subprojects.src.subprojects.libs.subprojects.Library.subprojects.include.product)) { print("    FAIL: Product 'rootProject.subprojects.src.subprojects.libs.subprojects.Library.subprojects.include' was not merged with its parent"); return; }
                if(rootProject.subprojects.src.subprojects.libs.subprojects.Library.product.item != "AutoprojectDynamicLib") { print("    FAIL: 'item' of product 'rootProject.subprojects.src.subprojects.libs.subprojects.Library' was not updated, EXPECTED: \"AutoprojectDynamicLib\", \"" + rootProject.subprojects.src.subprojects.libs.subprojects.Library.product.item + "\""); return; }
                if(!rootProject.subprojects.src.subprojects.libs.subprojects.Library.product.paths.contains(rootProject.subprojects.src.subprojects.libs.subprojects.Library.subprojects.include.path)) { print("    FAIL: Product 'rootProject.subprojects.src.subprojects.libs.subprojects.Library' is missing path of the merged directory 'include'"); return; }
                if(!rootProject.subprojects.src.subprojects.libs.subprojects.Library.product.files.contains(makePath(rootProject.subprojects.src.subprojects.libs.subprojects.Library.subprojects.include.path, "Library.h"))) { print("    FAIL: Product 'rootProject.subprojects.src.subprojects.libs.subprojects.Library' is missing file 'Library.h' from merged directory 'include'"); return; }
                print("    [Ok]");
            }

            var time = Date.now() - start;
            console.info("[5/11] Done (" + time + "ms)");
        }
    }

    Probe
    {
        id: productconsolidator
        property var mergedRootProject: productmerger.rootProject
        property var cppSourcesPattern: configuration.cppSourcesPattern
        property var items: configuration.items
        property var itemNames: getKeys(items)
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function isSourceFile(file)
            {
                return RegExp(cppSourcesPattern).test(file);
            }

            function hasSources(proj)
            {
                return proj.product.files.some(isSourceFile);
            }

            function getHigherItem(item, other)
            {
                return itemNames.indexOf(item) < itemNames.indexOf(other) ? item : other;
            }

            function mergeArrays(array, other)
            {
                return array.concat(other);
            }

            function mergeProducts(project, other)
            {
                project.product.item = getHigherItem(project.product.item, other.product.item);
                project.product.paths = mergeArrays(project.product.paths, other.product.paths);
                project.product.files = mergeArrays(project.product.files, other.product.files);
                print("    '" + other.product.name + "' (" + other.path + ") ---> '" + project.product.name + "' (" + project.path + ")");
                other.product = {};
            }

            function mergeLastTwoProjects(projects)
            {
                var leftProject = projects[projects.length - 2];
                var rightProject = projects[projects.length - 1];

                if(!hasSources(leftProject) && hasSources(rightProject))
                {
                    projects.splice(projects.length - 2, 1);
                    mergeProducts(rightProject, leftProject);
                }
                else
                {
                    projects.splice(projects.length - 1, 1);
                    mergeProducts(leftProject, rightProject);
                }
            }

            function mergeProjects(projects)
            {
                while(projects.length > 1)
                    mergeLastTwoProjects(projects);
            }

            function groupProjectsByProductName(project, projects)
            {
                if(isValid(project.product))
                {
                    if(!projects[project.product.name])
                        projects[project.product.name] = [];

                    projects[project.product.name].push(project);
                }

                forAll(project.subprojects, function(subproject) { groupProjectsByProductName(subproject, projects); }, {});
            }

            function consolidateProducts(project)
            {
                var projects = {};
                groupProjectsByProductName(project, projects);
                forAll(projects, mergeProjects, {});
                return project;

            }

            print("[6/11] Consolidating products...");
            var start = Date.now();
            var project = consolidateProducts(mergedRootProject);
            rootProject = project;

            if(runTests)
            {
                print("    Running tests...");
                if(isValid(rootProject.subprojects.Include.subprojects.MyLibrary.product)) { print("    FAIL: Product 'rootProject.subprojects.Include.subprojects.MyLibrary' was not merged with its namesake"); return; }
                if(rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary.product.item != "AutoprojectDynamicLib") { print("    FAIL: 'item' of product 'rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary' was not updated, EXPECTED: \"AutoprojectDynamicLib\", \"" + rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary.product.item + "\""); return; }
                if(!rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary.product.paths.contains(rootProject.subprojects.Include.subprojects.MyLibrary.path)) { print("    FAIL: Product 'rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary' is missing path of the merged directory"); return; }
                if(!rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary.product.files.contains(makePath(rootProject.subprojects.Include.subprojects.MyLibrary.path, "MyLibrary.h"))) { print("    FAIL: Product 'rootProject.subprojects.src.subprojects.libs.subprojects.MyLibrary' is missing file 'MyLibrary.h'"); return; }
                print("    [Ok]");
            }

            var time = Date.now() - start;
            console.info("[6/11] Done (" + time + "ms)");
        }
    }

    Probe
    {
        id: projectcleaner
        property var mergedRootProject: productconsolidator.rootProject
        property var runTests: configuration.runTests
        property var rootProject: {}

        configure:
        {
            function filterProject(project)
            {
                cleanProject(project);

                if(!isValid(project.product) && !isValid(project.subprojects))
                {
                    print("    Removed empty project '" + project.name + "' (" + project.path + ")");
                    delete this.object[this.name];
                }
            }

            function cleanProject(project)
            {
                forAll(project.subprojects, filterProject, {});
                return project;
            }

            print("[7/11] Cleaning projects...");
            var start = Date.now();
            var project = cleanProject(mergedRootProject);
            rootProject = project;

            if(runTests)
            {
                print("    Running tests...");
                if(rootProject.subprojects.Include.subprojects.MyLibrary) { print("    FAIL: Empty project 'rootProject.subprojects.Include.subprojects.MyLibrary' was not removed"); return; }
                if(rootProject.subprojects.src.subprojects.libs.subprojects.Library.subprojects.include) { print("    FAIL: Empty project 'rootProject.subprojects.src.subprojects.libs.subprojects.Library.subprojects.include' was not removed"); return; }
                print("    [Ok]");
            }

            var time = Date.now() - start;
            console.info("[7/11] Done (" + time + "ms)");
        }
    }

    Probe
    {
        id: dependencyscanner
        property var cleanedRootProject: projectcleaner.rootProject
        property var cppPattern: configuration.cppPattern
        property var cppSourcesPattern: configuration.cppSourcesPattern
        property var runTests: configuration.runTests
        property var modules: configuration.modules
        property var dependencyMode: configuration.dependencyMode
        property var rootProject: {}
        property var includedFiles: {}

        configure:
        {
            function isCppFile(file)
            {
                return RegExp(cppPattern).test(file);
            }

            function isSourceFile(file)
            {
                return RegExp(cppSourcesPattern).test(file);
            }

            function scanFile(file)
            {
                var content = TextFile(file).readAll();
                var regex = /#include\s*[<|\"]([a-zA-Z\/\.]+)[>|\"]/g;
                var result = [];
                while(result = regex.exec(content))
                {
                    this.includes[result[1]] = true;
                    includes[result[1]] = {};
                }
            }

            function scanProductFiles(project)
            {
                if(isValid(project.product))
                {
                    project.product.files.filter(isCppFile).forEach(scanFile, { includes: project.product.includes });
                    project.product.headerOnly = !project.product.files.some(isSourceFile);
                }

                if(isValid(project.product.includes))
                    print("    " + project.product.name + " [" + getKeys(project.product.includes).join(", ") + "]");
            }

            function scanDependencies(project)
            {
                forAll(project.subprojects, scanDependencies, {});
                scanProductFiles(project);
                return project;
            }

            print("[8/11] Scanning dependencies...");
            var start = Date.now();

            if(dependencyMode == configuration.DependencyMode.Disabled)
                print("Dependencies disabled --- skipping");
            else
            {
                var includes = {};
                var project = scanDependencies(cleanedRootProject);
                rootProject = project;
                includedFiles = includes;

                if(runTests)
                {
                    print("    Running tests...");
                    if(getKeys(rootProject.subprojects.Include.product.includes).join(",") != "QtPlugin,QString") { print("    FAIL: Failed to extract includes from 'rootProject.subprojects.Include' project files --- EXPECTED: \"QtPlugin,QString\", ACTUAL: \"" + getKeys(rootProject.subprojects.Include.product.includes).join(",") + "\""); return; }
                    if(getKeys(rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.includes).join(",") != "PrintMessage.h,PluginInterface.h,QPluginLoader,QDebug") { print("    FAIL: Failed to extract includes from 'rootProject.subprojects.src.subprojects.apps.subprojects.Application' project files --- EXPECTED: \"PrintMessage.h,PluginInterface.h,QPluginLoader,QDebug\", ACTUAL: \"" + getKeys(rootProject.subprojects.Include.product.includes).join(",") + "\""); return; }
                    if(!getKeys(includedFiles).contains("QString")) { print("    FAIL: Include 'QString' not found in 'includedFiles'"); return; }
                    if(!getKeys(includedFiles).contains("PrintMessage.h")) { print("    FAIL: Include 'PrintMessage.h' not found in 'includedFiles'"); return; }
                    print("    [Ok]");
                }
            }
            var time = Date.now() - start;
            console.info("[8/11] Done (" + time + "ms)");
        }
    }

    Probe
    {
        id: includefinder
        property var scannedRootProject: dependencyscanner.rootProject
        property var includedFiles: dependencyscanner.includedFiles
        property var runTests: configuration.runTests
        property var dependencyMode: configuration.dependencyMode
        property var modules: modulescanner.modules
        property var includeMap: {}
        property var rootProject: {}

        configure:
        {
            function findIncludeInModules(includeName)
            {
                for(var moduleName in modules)
                {
                    var file = modules[moduleName].files.find(isInclude, { includeName: includeName });

                    if(file)
                        return { name: moduleName };
                    else
                    {
                        for(var submoduleName in modules[moduleName].submodules)
                        {
                            if(file = modules[moduleName].submodules[submoduleName].files.find(isInclude, { includeName: includeName }))
                                return { name: moduleName + "." + submoduleName };
                        }
                    }
                }

                return undefined;
            }

            function isInclude(file)
            {
                return this.includeName.contains("/") ? file.endsWith(this.includeName) : file.endsWith("/" + this.includeName);
            }

            function findIncludeInProject(project, includeName)
            {
                if(isValid(project.product))
                {
                    var file = project.product.files.find(isInclude, { includeName: includeName });

                    if(file)
                    {
                        project.product.includedPaths[getFilePath(file)] = true;
                        return { path: getFilePath(file), product: project.product, name: project.product.name };
                    }
                }

                return findIncludeInProjects(project.subprojects, includeName);
            }

            function findIncludeInProjects(projects, includeName)
            {
                var result = undefined;

                for(var projectName in projects)
                {
                     if(result = findIncludeInProject(projects[projectName], includeName))
                         break;
                }

                return result;
            }

            function isStandardHeader(includeName)
            {
                return !RegExp("[A-Z\d\.]").test(includeName);
            }

            function findInclude(includeName)
            {
                if(isStandardHeader(includeName))
                    delete this.includes[includeName];
                else
                {
                    this.includes[includeName] = findIncludeInProject(scannedRootProject, includeName);

                    if(!isValid(this.includes[includeName]))
                        this.includes[includeName] = findIncludeInModules(includeName);

                    if(isValid(this.includes[includeName]))
                        print("    '" + includeName + "' found in '" + this.includes[includeName].name);
                    else
                        print("    WARNING: Dependency '" + includeName + "' not found in any project or module");
                }
            }

            function findIncludes(includes)
            {
                getKeys(includes).forEach(findInclude, { includes: includes });
                return includes;
            }

            print("[9/11] Finding includes...");
            var start = Date.now();

            if(dependencyMode == configuration.DependencyMode.Disabled)
                print("Dependencies disabled --- skipping");
            else
            {
                addFind();
                var includes = findIncludes(includedFiles);
                includeMap = includes;
                rootProject = scannedRootProject;

                if(runTests)
                {
                    print("    Running tests...");
                    if(includeMap.QString.name != "Qt.core") { print("    FAIL: Dependency for include 'QString' not found"); return; }
                    if(includeMap["PrintMessage.h"].name != "ApplicationLib") { print("    FAIL: Dependency for include 'PrintMessage.h' not found"); return; }
                    if(includeMap["PrintMessage.h"].path != rootProject.subprojects.src.subprojects.apps.subprojects.Application.subprojects.Lib.path) { print("    FAIL: Path for include 'PrintMessage.h' incorrect --- EXPECTED: \"" + rootProject.subprojects.src.subprojects.apps.subprojects.Application.subprojects.Lib.path + "\", ACTUAL: \"" + includeMap["PrintMessage.h"].path + "\""); return; }
                    if(!rootProject.subprojects.src.subprojects.apps.subprojects.Application.subprojects.Lib.product.includedPaths[rootProject.subprojects.src.subprojects.apps.subprojects.Application.subprojects.Lib.path]) { print("    FAIL: 'includedPath' for include 'PrintMessage.h' not set"); return; }
                    print("    [Ok]");
                }
            }

            var time = Date.now() - start;
            console.info("[9/11] Done (" + time + "ms)");
        }
    }

    Probe
    {
        id: dependencysetter
        property var dependencyScanRootProject: includefinder.rootProject
        property var includes: includefinder.includeMap
        property var runTests: configuration.runTests
        property var dependencyMode: configuration.dependencyMode
        property var rootProject: {}

        configure:
        {
            function setProductDependencies(project)
            {
                for(var include in project.product.includes)
                {
                    var dependency = includes[include];

                    if(isValid(dependency))
                    {
                        if(dependencyMode == configuration.DependencyMode.NoHeaderOnly && dependency.product && dependency.product.headerOnly)
                            project.product.includePaths[dependency.path] = true;
                        else
                            project.product.dependencies[dependency.name] = true;
                    }
                }

                delete project.product.dependencies[project.product.name];
            }

            function setDependencies(project)
            {
                if(isValid(project.product))
                {
                    setProductDependencies(project);
                    print("    " + project.product.name);
                    print("        Include: " + getKeys(project.product.includePaths).join(", "));
                    print("        Export: " + getKeys(project.product.includedPaths).join(", "));
                }

                forAll(project.subprojects, setDependencies, {});
                return project;
            }

            print("[10/11] Setting dependencies...");
            var start = Date.now();

            if(dependencyMode == configuration.DependencyMode.Disabled)
                print("Dependencies disabled --- skipping");
            else
            {
                var project = setDependencies(dependencyScanRootProject);
                rootProject = project;

                if(runTests)
                {
                    print("    Running tests...");
                    if(!rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.dependencies["Qt.core"]) { print("    FAIL: Missing dependency 'Qt.core' in 'Application' product"); return; }
                    if(!rootProject.subprojects.src.subprojects.apps.subprojects.Application.product.dependencies["ApplicationLib"]) { print("    FAIL: Missing dependency 'ApplicationLib' in 'Application' product"); return; }
                    print("    [Ok]");
                }
            }
            var time = Date.now() - start;
            console.info("[10/11] Done (" + time + "ms)");

        }
    }

    Probe
    {
        id: projectwriter
        property var rootProject: dependencysetter.rootProject
        property var outPath: configuration.outPath
        property var projectFormat: configuration.projectFormat
        property bool dryRun: configuration.dryRun
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

                if(isValid(proj.product))
                    writeProduct(file, proj.product, isProjectFormatFlat() ? indent : (indent + "    "));

                for(var subproject in proj.subprojects)
                    writeProject(file, proj.subprojects[subproject], isProjectFormatFlat() ? indent : (indent + "    "));

                if(projectFormat == configuration.ProjectFormat.Tree)
                {
                    file.writeLine(indent + "}");
                }
            }

            function writeIncludePaths(file, includedPaths, includePaths, indent)
            {
                if(includedPaths.length > 0 || includePaths.length > 0)
                {
                    file.writeLine(indent + "    Depends { name: \"cpp\" }")
                    file.writeLine(indent + "    cpp.includePaths: [\"" + includedPaths.concat(includePaths).join("\", \"") + "\"]");
                }
            }

            function writeExport(file, includedPaths, includePaths, dependencies, indent)
            {
                if(includePaths.length > 0 || includedPaths.length > 0 || dependencies.length > 0)
                {
                    file.writeLine(indent + "Export");
                    file.writeLine(indent + "{");

                    if(includePaths.length > 0 || includedPaths.length > 0)
                    {
                        file.writeLine(indent + "    Depends { name: \"cpp\" }")
                        file.writeLine(indent + "    cpp.includePaths: [\"" + includedPaths.concat(includePaths).join("\", \"") + "\"]");
                    }

                    if(dependencies.length > 0)
                        dependencies.forEach(writeDependency, { file: file, indent: indent + "    " });

                    file.writeLine(indent + "}");
                }
            }

            function writeProduct(file, product, indent)
            {
                file.writeLine(indent + product.item);
                file.writeLine(indent + "{");
                file.writeLine(indent + "    name: \"" + product.name + "\"");
                file.writeLine(indent + "    paths: [\"" + product.paths.join("\", \"") + "\"]");
                writeExport(file, getKeys(product.includedPaths), getKeys(product.includePaths), getKeys(product.dependencies), indent + "    ");

                if(!product.headerOnly)
                    writeIncludePaths(file, getKeys(product.includedPaths), getKeys(product.includePaths), indent);

                getKeys(product.dependencies).forEach(writeDependency, {file: file, indent: indent + "    "});
                file.writeLine(indent + "}");
                print("    " + product.name);
            }

            function writeDependency(dependency)
            {
                this.file.writeLine(this.indent + "Depends { name: \"" + dependency + "\" }");
            }

            print("[11/11] Writing project...");
            var start = Date.now();

            if(dryRun)
                print("Dependencies disabled --- skipping");
            else
            {
                var refs = write(rootProject);
                references = refs;
            }

            var time = Date.now() - start;
            console.info("[11/11] Done (" + time + "ms)");
        }
    }

    qbsSearchPaths: configuration.autoprojectDirectory
    references: projectwriter.references
}
