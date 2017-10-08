import qbs

StaticLibrary
{
    Export
    {
        Depends { name: "cpp" }
        cpp.link: false
    }
    
    Depends { name: "cpp" }

    name: project.name
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["staticlibrary"]
    }
}
