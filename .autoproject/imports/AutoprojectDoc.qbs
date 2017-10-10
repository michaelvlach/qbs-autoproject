import qbs
import qbs.FileInfo

Product
{
    property string path: ""
    name:
    {
        var dir = FileInfo.baseName(path);
        if(dir == "doc" || dir == "Doc" || dir == "documentation" || dir == "Documentation")
            return FileInfo.baseName(FileInfo.path(path)) + "Doc";
        else
            return dir + "Doc";
    }
    
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
