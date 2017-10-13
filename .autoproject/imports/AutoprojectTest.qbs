import qbs
import qbs.FileInfo

CppApplication
{
    property string path: ""

    targetName: qbs.buildVariant == "debug" ? name + "d" : name

    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["application"]
    }
}
