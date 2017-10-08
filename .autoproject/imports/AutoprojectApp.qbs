import qbs

CppApplication
{
    name: project.name + "App"
    targetName: qbs.buildVariant == "debug" ? name + "d" : name

    Group
    {
        qbs.install: true
        qbs.installDir: project.target
        fileTagsFilter: ["application"]
    }
}
