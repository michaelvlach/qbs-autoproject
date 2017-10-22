import qbs
import qbs.FileInfo

StaticLibrary
{
    Depends { name: "cpp" }
    property stringList paths: []
    property stringList includePaths: []
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
        fileTagsFilter: ["staticlibrary"]
    }
}
