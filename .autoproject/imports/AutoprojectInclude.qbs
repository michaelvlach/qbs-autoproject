import qbs
import qbs.FileInfo

Product
{
    Depends { name: "cpp" }
    property stringList paths: []
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
        cpp.includePaths: paths
        Parameters
        {
            cpp.link: false
        }
    }
}
