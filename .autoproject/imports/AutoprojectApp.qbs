import qbs
import qbs.FileInfo

CppApplication
{
    property string path: ""
    name:
    {
        var dir = FileInfo.baseName(path);
        if(dir == "src" || dir == "Src")
            return FileInfo.baseName(FileInfo.path(path)) + "App";
        else
            return dir + "App";
    }
    targetName: qbs.buildVariant == "debug" ? name + "d" : name

    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["application"]
    }
}
