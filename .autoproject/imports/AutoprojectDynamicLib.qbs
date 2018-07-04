import qbs

AutoprojectCppProduct
{
    type: cpp.driverFlags.contains("-static") ? "staticlibrary" : "dynamiclibrary"
    cpp.defines: base.concat(name.toUpperCase() + "_LIB")
}
