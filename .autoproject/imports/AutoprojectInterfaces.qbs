import qbs
import qbs.FileInfo

Product
{
    property string path: ""
    name:
    {
        var dir = FileInfo.baseName(path);
        if (dir == "include" || dir == "Include" || dir == "interfaces" || dir == "Interfaces")
            return FileInfo.baseName(FileInfo.path(path)) + "Interfaces";
        else
            return dir + "Interfaces";
    }
    
    Export
    {
        Depends { name: "cpp" }
    }
    
    Depends { name: "cpp" }    
}
