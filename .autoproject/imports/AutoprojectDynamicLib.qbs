import qbs
import qbs.File
import qbs.FileInfo

DynamicLibrary
{
    Depends { name: "cpp" }
    property stringList paths: []
    cpp.defines: project.name.toUpperCase() + "_LIB"
    cpp.includePaths: paths
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    files:
    {
        var list = [];
        for(var i in paths)
            list.push(paths[i] + "/*");
        return list;
    }
    
    Export
    {
        Depends { name: "cpp" }
        cpp.includePaths:
        {
            var list = [];
            for(var i in product.paths)
            {
                var files = File.directoryEntries(product.paths[i], File.Files);
                if(files.some(function(file) { return RegExp(".+\\.h").test(file); }) && !files.some(function(file) { return RegExp(".+\\.cpp").test(file); }))
                    list.push(product.paths[i]);
            }
            console.info("DYNAMIC INCLUDES: " + list);
            return list;
        }
    }
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["dynamiclibrary"]
    }
}
