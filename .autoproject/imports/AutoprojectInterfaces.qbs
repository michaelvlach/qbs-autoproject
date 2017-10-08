import qbs

Product
{
    Export
    {
        Depends { name: "cpp" }
    }
    
    Depends { name: "cpp" }    
    name: project.name + "Interfaces"
}
