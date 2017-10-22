import qbs
import qbs.FileInfo

DynamicLibrary
{
    Depends { name: "cpp" }
    property stringList paths: []
    targetName: qbs.buildVariant == "debug" ? name + "d" : name
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
        cpp.includePaths:
        {
            var list = [];
            for(var i in paths)
            {
                var files = File.directoryEntries(paths[i], File.Files);
                if(files.some(function(file) { return RegExp(".+\.h"); }) && !files.some(function(file) { return RegExp(".+\.cpp"); }))
                    list.push(paths[i]);
            }
            return list;
        }
        Parameters
        {
            cpp.link: false
        }
    }
    
    
    
    
    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["dynamiclibrary"]
    }
}
