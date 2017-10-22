import qbs
import qbs.File
import qbs.FileInfo

DynamicLibrary
{
    Depends { name: "cpp" }
    property stringList paths: []
    property stringList includePaths: []
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
        cpp.includePaths: product.includePaths
    }
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["dynamiclibrary"]
    }
}
