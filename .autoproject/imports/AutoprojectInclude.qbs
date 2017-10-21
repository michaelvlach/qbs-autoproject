import qbs
import qbs.FileInfo

Product
{
    property stringList paths: []
    
    Export
    {
        Depends { name: "cpp" }
    }
    
    Depends { name: "cpp" }    
}
