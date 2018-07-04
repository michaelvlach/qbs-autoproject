import qbs

AutoprojectApp
{
    consoleApplication: false

    Depends
    {
        name: "Qt"
        submodules: "gui"
    }

    Depends
    {
        condition: /static/i.test(project.profile);
        name: "Qt"
        submodules: Qt.gui.defaultQpaPlugin
    }
}
