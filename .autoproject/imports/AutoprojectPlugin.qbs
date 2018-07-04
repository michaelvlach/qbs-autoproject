import qbs

AutoprojectCppProduct
{
    type: "dynamiclibrary"
    
    Export
    {
        Parameters
        {
            cpp.link: false
        }
    }
}
