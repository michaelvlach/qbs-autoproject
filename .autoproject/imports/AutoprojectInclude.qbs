import qbs
import qbs.FileInfo

Product
{
    property string path: ""
    
    Export
    {
        Depends { name: "cpp" }
    }
    
    Depends { name: "cpp" }    
}
