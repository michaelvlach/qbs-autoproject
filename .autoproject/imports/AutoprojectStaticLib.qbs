import qbs
import qbs.FileInfo

StaticLibrary
{
    property string path: ""

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
