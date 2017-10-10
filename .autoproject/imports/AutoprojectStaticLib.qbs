import qbs
import qbs.FileInfo

StaticLibrary
{
    property string path: ""
    name:
    {
        var dir = FileInfo.baseName(path);
        if (dir == "lib" || dir == "Lib")
            return FileInfo.baseName(FileInfo.path(path)) + "Lib";
        else
            return dir + "Lib";
    }
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    
    Export
    {
        Depends { name: "cpp" }
        cpp.link: false
    }
    
    Depends { name: "cpp" }
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["staticlibrary"]
    }
}
