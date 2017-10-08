import qbs

DynamicLibrary
{
    Export
    {
        Depends { name: "cpp" }
    }
    
    Depends { name: "cpp" }    
    cpp.defines: project.name.toUpperCase() + "_LIB"
    name: project.name + "Lib"
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["dynamiclibrary"]
    }
}
