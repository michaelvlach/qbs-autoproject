import qbs
import qbs.FileInfo

CppApplication
{
    property stringList paths: []
    targetName: qbs.buildVariant == "debug" ? name + "d" : name

    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: ["application"]
    }
}
