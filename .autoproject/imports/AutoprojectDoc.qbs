import qbs
import qbs.FileInfo

Product
{
    Depends { name: "Qt"; submodules: [ "core" ]; }
    property stringList paths: []
    builtByDefault: false
    type: "qch"
    files:
    {
        var list = [];
        for(var i in paths)
            list.push(paths[i] + "/*");
        return list;
    }

    Group
    {
        files: "*.qdocconf"
        fileTags: "qdocconf-main"
    }

    Group
    {
        fileTagsFilter: ["qdoc-output"]
        qbs.install: true
        qbs.installDir: FileInfo.joinPaths(project.installDirectory, "doc")
        qbs.installSourceBase: Qt.core.qdocOutputDir
    }

    Group
    {
        fileTagsFilter: ["qch"]
        qbs.install: true
        qbs.installDir: FileInfo.joinPaths(project.installDirectory, "doc")
    }
}
