import qbs
import qbs.FileInfo

Product
{
    property string path: ""
   
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
        qbs.installDir: "/doc"
        qbs.installSourceBase: Qt.core.qdocOutputDir
    }

    Group
    {
        fileTagsFilter: ["qch"]
        qbs.install: true
        qbs.installDir: "/doc"
    }
}
