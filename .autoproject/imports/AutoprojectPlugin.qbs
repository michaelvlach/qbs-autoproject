import qbs
import qbs.FileInfo

DynamicLibrary
{
    property string path: ""
    name:
    {
        var dir = FileInfo.baseName(path);
        if (dir == "plugin" || dir == "Plugin")
            return FileInfo.baseName(FileInfo.path(path)) + "Plugin";
        else
            return dir + "Plugin";
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
        fileTagsFilter: ["dynamiclibrary"]
    }
}
