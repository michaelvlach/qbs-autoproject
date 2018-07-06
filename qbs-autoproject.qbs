import qbs
import ".autoproject/autoproject.qbs" as AutoProject

AutoProject
{
    property string root: "Example"
    property string format: "Tree" //Tree, Flat, Shallow
    property string dependencyMode: "Default" //Default, NoHeaderOnly, Disabled
    property string ignore: "\\/(\\.autoproject|\\.git|tools)$"
    property string sources: "\\.cpp$"
    property string headers: "\\.h$"
    property string squashDirs: "\\/(include|src)?$"
    property string standardHeadersPath: ""
    property bool dryRun: false

    property var items:
    {
        return {
            AutoprojectGuiApp: {
                pattern: "\\/(.+\\.ui)$"
            },
            AutoprojectApp: {
                pattern: "\\/((Test|Benchmark)|.+(Test|Benchmark)\\.(cpp|h)|[Mm]ain\\.cpp)$"
            },
            AutoprojectDynamicLib: {
                pattern: "\\/(.+\\.h)$",
                contentPattern: "[A-Z\d_]+SHARED "
            },
            AutoprojectPlugin:
            {
                pattern: "\\/.+\\.h$",
                contentPattern: "Q_INTERFACES\\(([a-zA-Z\d]+(, |,|))+\\)"
            },
            AutoprojectStaticLib: {
                pattern: "\\/(.+\\.cpp)$"
            },
            AutoprojectInclude: {
                pattern: "\\/(.+\\.h)$"
            },
            AutoprojectDoc: {
                pattern: "\\/(doc|.+\\.qdoc(conf)?)$"
            },
            AutoprojectBase: {
                pattern: "\\/README$"
            }
        };
    }

    property var modules:
    {
        return {
            Qt: {
                includePath: "" //fill this to override Qt auto detection or with other modules
            }
        };
    }
}
