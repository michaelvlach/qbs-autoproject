import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Project
{
    name: FileInfo.baseName(sourceDirectory)
    id: autoproject
    
    property var rules:
    {
        //regexp = "pattern"
        //command = "ignore|project|product"
        //[named command parameters]
        return {
            ignore:     { regexp: "^(.autoproject|.git)$",                  command: "ignore" },
            project:    { regexp: "^[A-Zd].*$",                      command: "project" },
            product:    { regexp: "^(private|src|resources)$",       command: "product" },
            test:       { regexp: "[Tt]est\.(cpp|h)$",               command: "product", item: "AutoprojectTest" },
            app:        { regexp: "^main.cpp$",                      command: "product", item: "AutoprojectApp" },
            shared:     { regexp: ".h$", content: "[A-Zd]+SHARED ",  command: "product", item: "AutoprojectShared" },
            plugin:     { regexp: ".h$", content: "QINTERFACES(.*)", command: "product", item: "AutoprojectPlugin" },
            static:     { regexp: ".cpp$",                           command: "product", item: "AutoprojectStatic" },
            interfaces: { regexp: ".h$",                             command: "product", item: "AutoprojectInterfaces" },
            docgen:     { regexp: ".qdocconf$",                      command: "product", item: "AutoprojectDocGen" },
            doc:        { regexp: ".qdoc$",                          command: "product", item: "AutoprojectDoc" }
        };
    }

    property var projects:
    {
        function createItemHierarchy()
        {
            var hierarchy = {};
            var priority = 1;

            for(var rule in rules)
            {
                if(rules[rule]["item"])
                    itemHierarchy[rules[rule]["item"]] = priority++;
            }

            return hierarchy;
        }

        function doProjectCommand(dir)
        {
            return { name: FileInfo.baseName(dir), path: dir, products: [getProduct(dir)], projects: [] };
        }

        function doProductCommand(dir)
        {
            return { name: FileInfo.baseName(dir), path: dir, item: "", files: [] };
        }

        function getProduct(dir)
        {
            var product = doProductCommand(dir);
            var files = File.directoryEntries(dir, File.Files);

            for(var i in files)
            {
                for(var rule in rules)
                {
                    var regexp = new RegExp(rules[rule]["regexp"]);

                    if(regexp.test(files[i]) && rules[rule]["command"] == "product")
                    {
                        product["files"].push(FileInfo.joinPaths(dir, files[i]));
                        if(!product["item"] || itemHierarchy[product["item"]] > itemHierarchy[rules[rule]["item"]])
                            product["item"] = rules[rule]["item"];
                    }
                }
            }
        }

        function getProject(dir)
        {
            var project = doProjectCommand(dir);
            var dirs = File.directoryEntries(dir, File.Dirs | File.NoDotAndDotDot);

            for(var i in dirs)
            {
                for(var rule in rules)
                {
                    if(RegExp(rules[rule]["regexp"]).test(dirs[i]))
                    {
                        if(rules[rule]["command"] == "project")
                            project["projects"].push(getProject(FileInfo.joinPaths(dir, dirs[i])));
                        else if(rules[rule]["command"] == "product" && !rules[rule]["item"])
                            project["products"][0][files] = project["products"][0][files].concat(File.directoryEntries(FileInfo.joinPaths(dir, dirs[i], File.Files)));

                        break;
                    }
                    else
                        project["products"].push(getProduct(FileInfo.joinPaths(dir, dirs[i])));
                }
            }



            return project;
        }

        var itemHierarchy = createItemHierarchy;
        var rootProject = getProject(sourceDirectory);
        var rootProjects = [rootProject];

        if(!rootProject["products"])
            rootProjects = rootProject["projects"];

        return rootProjects;
    }
}
