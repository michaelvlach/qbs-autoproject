import qbs

DynamicLibrary
{
    Export
    {
        Depends { name: "cpp" }
        cpp.link: false
    }
    
    Depends { name: "cpp" }
    name: project.name + "Plugin"
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["dynamiclibrary"]
    }
}
