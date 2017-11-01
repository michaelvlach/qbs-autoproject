import qbs

DynamicLibrary
{
    property stringList paths: []
    Depends { name: "cpp" }
    cpp.defines: name.toUpperCase() + "_LIB"
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
    
    files:
    {
        var list = [];
        for(var i in paths)
            list.push(paths[i] + "/*");
        return list;
    }
        
    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["dynamiclibrary"]
    }
}
