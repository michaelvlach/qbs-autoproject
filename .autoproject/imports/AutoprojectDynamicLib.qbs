import qbs
import qbs.FileInfo

DynamicLibrary
{
    property stringList paths: []
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
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["dynamiclibrary"]
    }
}
