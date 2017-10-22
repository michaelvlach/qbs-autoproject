import qbs
import qbs.FileInfo

DynamicLibrary
{
    Depends { name: "cpp" }
    property stringList paths: []
    property stringList includePaths: []
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
        Parameters
        {
            cpp.link: false
        }
    }
    
    
    
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["dynamiclibrary"]
    }
}
