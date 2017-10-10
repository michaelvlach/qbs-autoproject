import qbs
import qbs.FileInfo

DynamicLibrary
{
    property string path: ""
    name: FileInfo.baseName(path)
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    
    Export
    {
        Depends { name: "cpp" }
    }
    
    Depends { name: "cpp" }    
    cpp.defines: project.name.toUpperCase() + "_LIB"
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["dynamiclibrary"]
    }
}
