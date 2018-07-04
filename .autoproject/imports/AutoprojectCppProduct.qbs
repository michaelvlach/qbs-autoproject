import qbs

Product
{
    property var paths: []

    Depends
    {
        name: "cpp"
    }

    cpp.cxxLanguageVersion: "c++17"

    Export
    {
        Depends
        {
            name: "cpp"
        }

        cpp.cxxLanguageVersion: "c++17"
    }

    files:
    {
        var list = [];
        for(var i in paths)
            list.push(paths[i] + "/*");
        return list;
    }

    Properties
    {
        condition: /static/i.test(project.profile)
        cpp.driverFlags: "-static"
    }
    Properties
    {
        condition: qbs.targetOS.contains("windows")
        cpp.defines: ["_SCL_SECURE_NO_WARNINGS"]
    }
    Properties
    {
        condition: cpp.compilerName.contains("clang")
        cpp.driverLinkerFlags: outer.concat("-fuse-ld=lld")
    }
    Properties
    {
        condition: cpp.compilerName.contains("clang") && (qbs.buildVariant == "debug" || qbs.buildVariant == "profile")
        cpp.driverFlags: outer.concat(["-fprofile-instr-generate", "-fcoverage-mapping"])
    }
    Properties
    {
        condition: !qbs.targetOS.contains("windows") && cpp.compilerName.contains("gcc") && (qbs.buildVariant == "release" || qbs.buildVariant == "profile")
        cpp.cxxFlags: outer.concat(["-g", "-O2"])
    }

    targetName: qbs.buildVariant == "debug" ? (name + "d") : name

    Group
    {
        qbs.install: true
        qbs.installDir: project.installDirectory
        fileTagsFilter: type
    }
}
