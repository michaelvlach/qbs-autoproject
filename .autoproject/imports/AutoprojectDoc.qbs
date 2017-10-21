import qbs
import qbs.FileInfo

Product
{
    property stringList paths: []
   
    Depends { name: "Qt"; submodules: [ "core" ]; }
    
    builtByDefault: false
    type: "qch"

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
