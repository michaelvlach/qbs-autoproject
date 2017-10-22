import qbs
import qbs.FileInfo

CppApplication
{
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
    cpp.includePaths: paths
    
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
        fileTagsFilter: ["application"]
    }
}
