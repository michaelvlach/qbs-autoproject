import qbs
import qbs.FileInfo

CppApplication
{
    property string path: ""
    name:
    {
        var dir = FileInfo.baseName(path);
        if (dir == "test" || dir == "Test" || dir == "Test" || dir == "Tests")
            return FileInfo.baseName(FileInfo.path(path)) + "Test";
        else
            return dir + "Test";
    }
    targetName: qbs.buildVariant == "debug" ? name + "d" : name

    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["application"]
    }
}
