# qbs-autoproject
https://github.com/Resurr3ction/qbs-autoproject/

[Qbs](https://github.com/qbs/qbs) project file that automatically detects your projects and products.

## Table of Contents

* Prerequisites
* Quick Start
* Summary
* Configuration
* Explanation
* Performance Tips
* Example
* Limitations
* FAQ
* License
* Requests & Bug Reports
* Contact

## Prerequisites

* [Qt Creator](http://doc.qt.io/qtcreator/) (recommended) -OR- [Qbs](https://github.com/qbs/qbs)

* Qt 5 (optional)

## Quick Start

1. Put **qbs-autoproject.qbs** file (you can rename it) and **.autoproject** directory from this repository to the root of your project.
2. Open **qbs-autoproject.qbs** amd change the **root** to suit your project or leave it empty.
3. Run **qbs build qbs-autoproject.qbs** from the command line or open it in Qt Creator.

## Summary

While build systems such as Qbs, Cmake, Automake or qmake are powerful tools, working with them is often complex and difficult task particularly when dealing with large projects. The goal of the qbs-autoproject is to automate and streamline the project writing and project editing by eliminating the need to do so almost entirely. Projects for qbs-autoproject are defined by the directories and source code files reducing the project maintanance to just physically moving files and directories around.

qbs-autoproject project file detects projects and products recursively within a given root directory based on the configurable settings. For C/C++ projects it will additionally detect dependencies between the projects and external modules (e.g. [Qt](https://www.qt.io/)). The project file will be automatically created and set as a subproject of the qbs-autoproject file that will act as your project root.

## Configuration

Configurable settings of qbs-autoproject are located in the root file **qbs-autoproject.qbs**. You may (and probably should) rename it to reflect your project.

* **root**: Relative path from the **autoproject.qbs** file to the desired project root. If the **autoproject.qbs** is placed in the project root its value should be `""` or `"."`. Default value: ""

* **format**: Style of the resulting project file. Default value: "Tree"

*Flat* will generate flat structure of one project with all found products under it. 

*Tree* will generate nested structure reflecting the actual file system hierarchy of products as they were discovered. If a detected project contains one or more products new sub-project is created. 

*Shallow* is similar to tree but allows only one sub-project level. It is useful for complicated projects where you might not care about structure of individual sub-projects.

* **dependencyMode**: (C/C++ projects only!) Mode to use to create dependencies between products. In **Default** mode all dependencies will be created as *Depends* items. In **NoHeaderOnly** mode the products with only header files in them will not be depended upon through *Depends* items but instead the appropriate include paths will be added to each product that depends on them. For discussion about these two modes see *Exaplantion* section. If your product is not C/C++ use **Disabled** mode that will skip all steps related to dependencies. Default value: "Default"

* **ignorePattern**: Regular expression to ignore directories and/or files. The pattern will be applied to the full paths of all directories and files. Use this to exclude certain parts (or files) of your project from the scan (e.g. /bin/, /build/ etc.). Default value: `"\\/(\\.autoproject|\\.git|tools)$"` (NOTE: The backslahs '\' needs to be escaped)

* **sources**: Regular expression to match C/C++ source files. When merging products the products with source files (as opposed to only header files) will be merged to. Default value: `"\\.cpp$"` (NOTE: The backslahs '\' needs to be escaped)

* **headers**: Regular expression to match C/C++ source files. When merging products the products with source files (as opposed to only header files) will be merged to. Default value: `"\\.h$"` (NOTE: The backslahs '\' needs to be escaped)

* **squashDirs**: This regular expression pattern allows you to merge products in child directories to the product in the parent directory recursively. While generally you should have one product per directory sometimes it makes sense to put part of the product in separate directory (e.g. public headers into the *include* directory within the product directory). For example if you have a library product in directory `Example/libs/Library` you may place its public headers into the `Example/libs/Library/include` directory and set the **squashDirs** to `"\\/[Ii]ncludes?$"` to merge the *include* directory into the *Library* product. Default value: `"\\/(include|src)?$` (NOTE: The backslahs '\' needs to be escaped)

* **standardHeadersPath**: Absolute path to your C++ compiler's include directory. If you are compiling for different platforms, one of the compilers you use should suffice. It is used to determine which of your includes are standard headers to ignore them when resolving dependencies. This setting is optional and will be autodetected if left empty. When cross compiling or if the autodetection fails you may want to set it manually. Default value: ""

* **dryRun**: Scans for the projects and products but does not output any project file. Use this for debugging or for observing the results of the performed steps in the log. Default value: "false"

* **items**: Qbs lets you define reusable template products in form of [custom items](http://doc.qt.io/qbs/custom-modules.html). They will serve as base for the kind of products you wish to detect. By default there is a standard palette of C++ items defined: *GuiApplication, ConsoleApplication, DynamicLibrary, Plugin, StaticLibrary, Includes, Documentation*. You may create your own, modify the default ones or remove those that you do not use (e.g. Documentation or StaticLibrary). Each item file needs to be placed in the **.autoproject/imports**. All directories and files (absolute paths) will then be tested against the regular expression in **pattern** and if a directory (or file within a directory) will match the corresponding **item** will be created for it. Optionally you may specify **contentPattern** that will apply only to files and the **item** will only be matched if a file within given directory matches the **contentPattern** as well. The items are mutually exclusive and are tested in order of their definition so your items should be organized with most specialized at the top while the most generic are at the bottom (e.g. Application with pattern matching only main.cpp file should be higher than StaticLibrary that matches all \*.cpp files that did not match any of the previous items). For further details refer to *Exaplanation*  section.

* **modules**: (C/C++ projects only!) While items are your internal products, modules are your external dependencies. Qbs lets you define [custom modules](http://doc.qt.io/qbs/custom-modules.html) in much the same way as custom items. They should be placed in the **.autoprojectDirectory/modules/<module-name>** to be accessible. In qbs-autoproject configuration you should specify only the name and **includePath** that is the root of the header files of your module. By default there is only *Qt* as a module and for that you do not need to specify your own custom module(s) or give it an include path. Qt will be detected automatically if installed to default location. If Qt cannot be detected or you want to use specific version or you used custom install location you need to specify path to its include directory. For further information on how the modules are detected refer to *Exaplanation* section. 

## Explanation

qbs-autproject consists of 11 probes each consuming results of the previous.

1) **Configuration**

This probe simply collects and outputs the used configuartion and serves as basis for all following probes. It also attempts to detect C++ standard headers for Windows and Linux unless specified by the user, and it also tries to detect Qt module unless it is not present in modules or user provided the includePath already.

2) **Module Scanner**

This probe scans each module's include path and loads all file names found in them. It will also add submodules for each subdirectory found in the module's include root. The results of the scanner are used by the dependency finder. It is only used for C/C++ based projects as its results are used for dependency lookup.

3) **Project Scanner**

This probe scans the **root** recursively ignoring anything that matches **ignorePattern**. It will create a project for each directory (including the root) and gather some basic information about them like the list of files and their name.

4) **Product Scanner**

This probe will scan each *Project* found by *Project Scanner* trying to match an **item** in them by applying the items's pattern and contentPattern to their directory and files. If a match is found a *Product* with given item will be created initially having the same properties as its *Project*. The name of the product will be either the same as the *Project's* if **files** matched the item or compounded with the parent's *Product*'s name if the **directory** matched the item. E.g. Using the default settings *Example/App* would result in a product named `App` while `Example/App/Test` would result in product named `App/Test`. Similarly *Example/Include* would produce product `ExampleInclude` but *Example/Include/MyLibrary* would produce `MyLibrary` product.

5) **Product Merger**

This probe will merge products to their parent's project product recursively if the product's path matches **additionalDirectoriesPattern** and the parent has a product. The merge will be recursive, E.g. With default settings *Example/App/include/Include* with products being created for each directory the merge would first occur between `Include` and `include` and then between `App` and `include`. The merge will move all paths and files to the parent product. The item of the parent product will become the higher of the two as defined in the **items**.

6) **Product Consolidator**

This probe will merge products if they have the same name. Since there cannot be two projects of the same name this probe will merge them together regardless of their position in the hierarchy. The product that will server as the base of the merge is determined by detecting source files - the product with source files will be the base of the merge if the other product has only header files. If both products contain source files the one lower in the hierarchy of projects will become the base. The merge will occur for all products of the same name even if there are more than two. The item of the parent product will become the higher of the two as defined in the **items**. For example if you separate header files of a project into the global include directory like *Example/Include/MyLibrary* but the product sources are in *Example/src/libs/MyLibrary* the *Product Scanner* will create two products of the same name. Since only the latter contains source files (former has only header files) it will server as merge base and the files, paths etc. will be merged to it. The item will be updated to whichever is higher.

7) **Project Cleaner**

After the merging of the products it is likely that some projects will have neither sub-projects or a product. This probe will remove any such projects recursively so that only valid projects that contain a product or contain another project (that has a product) are preserved. The results of this probe are only observable when using **projectFormat** set to **Tree**.

8) **Dependency Scanner**

Each product's files will be scanned for `#include <...>` and `#include "..."` directives and the names of these includes will be extracted.

9) **Include Finder**

This probe will create the dependency map mapping each unique include to either another product or an external module based on the information from previous probes (particularly **Module Scanner** and product related probes). Standard headers includes are ignored. The probe will also add an include path to be exported to each matched product to dynamically create the Export item within each product that will correctly export the include paths as they are used. If any depednency is not resolved or ignored a warning is printed to the console as it indicates a potential error. 

10) **Dependency Setter**

This probe will use the dependency map from **Include Finder** and assign dependencies to all products based on their previously extracted includes. The **dependencyMode** setting will influence this process so that if a dependency is to be created on a product that contains only header files and the **dependencyMode** is set to **NoHeadersOnly** its include paths will be added to the product instead of the standard *Depends* item. This might be necessary if your project contains cyclic dependencies between headers, e.g. Header file `Lib.h` in product `ExampleInclude` includes header from product `ExampleIncludeExtra` that in turn include another header from `ExampleInclude`. This would obviously create a cyclic dependency between the two products and Qbs would disable them because of it. This sort of cyclic dependency between the header files is common in manually created projects and the solution to this problem is to specify the include paths only where necessary - the include directory would normally not be considered a separate product. **NoHeadersOnly** mode simulates this behaviour by embedding the include paths rather than dependency on the header-only products. However this mode should only be used for existing projects as this issue is a design issue that significantly limits the ability of headers to act as interfaces and you should consider fixing the problem and using **Default** mode whenever possible.

11) **Project Writer**

Writes the project file to **.utoproject** named as the **\<root\>.autoproject.qbs** containing all the projects and products that resulted from the previous steps. When **format** is **Flat** the projects are omitted except for the root and all products are placed in the single project. Each item will be set **paths** property that it should use to add files to the product typically by using wild-cards with appropriate extensions or so. The dependencies as they were detected will also be written to the items so tere is no need to export the include paths or dependencies on other modules from the items by yourself. What you might need to export however are additional depends parameters such as `cpp.link: false` to prevent linking to the products that should not be linked to (e.g. plugins). Now if your items are correct and all dependencies were resolved during the scan your project should be buildable (or any part of it).

## Performance Tips

Being QML/JavaScript and using lots of file system I/O the performance of various steps might become an issue for large projects. To increase the performance you may consider:

* **Disabling dependencies**: Unless your project is C/C++ you may see significant performance gains by disabling the dependencies by setting **dependencyMode** to *Disabled* as that will entirely skip several steps in the auto-detection process.

* **Remove unused items and modules**: If you are not using all of the items or modules you have defined in the Configuration consider removing them as that will save many redundant checks for matches that can never happen.

* **Do not use contentPattern**: While certainly a powerful and flexible feature it requires the scanner to read every file (sometimes repeatedly) to find a possible match. However if you can do without them you may see significant performance increase of detection.

* **Make use of the ignorePattern**: Every project contains directories and files that are simply not relevant to building the project or detecting the project and items. All the bin, build or temp directories should be ignored by adding them to the **ignorePattern** to skip them being unnecessarily examined.

* **Use dryRun to measure each step**: Upon complection of each step the time it took will be output to console. You may use dryRun to test various settings and observe the time it took to perform each step without worrying about the project file being written over and over needlessly.

## Example

There is an example project included that demonstrates various features of the qbs-autoproject project and product detection including name composition, product merging, complex dependencies etc. It is often easier to understand a feature when seen in practice rather than from its description. In order to build the Example project using qbs-autoproject you will also need Qt installed and its **includePath** set correctly in **modules** configuration option.

## Limitations

There are certain limitations that you should keep in mind when using qbs-autoproject.

1) **No exceptions to the rules** While the build-systems including Qbs rely on flexiblity and allow you to do almost anything (including this project) qbs-autoproject rely primarily on regularity. In experience it is the regularity that is most desired when working with projects because it dramatically decreases maintanance costs and increases the ability to develop the project further. Any exception or any deviation from existing pattern(s) is undesirable as it only increases the future maintanance costs that are always much higher than the initial development. For that reason qbs-autoproject is quite hostile to anything that is specific to only one project or even a file or directory. It still can be done by abusing the **items** by adding ones that only match single specific product but you should rather reconsider your design or update your design patterns instead of creating exceptions in your projects or indeed keeping them alive.

2) **Logical dependencies are not supported** While symbolic dependencies are clearly defined in files and code (with the common pitfall of circular header dependencies mentioned above) the logical dependencies are simply not. The fact that project A should depend on project B because of the runtime dependency even though they have nothing in common during build cannot be deduced or detected. For simple cases like plugins that should be built before their tests this can be solved by placing the interface in the product itself (provided it is the only implementation which is most often the case). For more complicated cases the only solution is to build the whole project before running your program(s).

3) **Includes come first** Traditionally you would define dependency on a module or project and then use it in your project. IDE would offer you the auto-completion and the real-time static-analyzer would tell if you it was not part of your includes. With qbs-autoproject you need to first make your include and once you rerun the probes the dependency will be created automatically. It is not as convenient as say C# but as close to it as we can get with C++ now.

## FAQ

**Running qbs-autoproject fails**

There are plenty of common issues when using qbs-autoproject that has more to do with Qbs or C++ in general rather than qbs-autoproject itself. Couple of tips:

1) Double check your configuration. While there are not many settings chances are there is something not quite right. Is your **root** correct (and relative path)?

2) Make sure you use latest Qbs and or up-to-date Qt Creator. The latter simplifies use of the former but sometimes it might not be detected correctly or there might be some issue in your Qbs profile that is being used.

**Running qbs-autoproject produces project that is not as expected**

This is most likely caused by either incorrectly defined **items** and their detection patterns or by the issues in your project structure (if you are sure your patterns are correct). Either update the patterns to closely represent how you want your projects to be detected or change the structure of your projects. Don't forget you can use **dryRun** to examine the output without actually writing any project files.

**I have changed project structure but the change did not take effect**

The build-graph is cached and the results of probes are as well. In order to re-do the scan and detect your new structure the probes need to be forced to run. Typically by running Qbs with --force-probes flag. In Qt Creator this can be done by ticking the option in the Project tab.

**Running qbs-autoproject produces dependency warnings**

Some warnings like those of unresolved \*.moc files (sometimes included by QTests) might be ignored but others usually mean that the file was not detected in any of your projects or modules (or you have a typo in the name?).

**My resulting project has lots of cyclic dependency warnings**

See *Explanation* section for information of the source of these warnings and how to fix them (**10) Dependency Setter**). If you cannot or do not want to fix them set the **dependencyMode** to **NoHeadersOnly**.

**I believe I found a bug**

Please submit an issue: https://github.com/Resurr3ction/qbs-autoproject/issues

**I would like to ask for a new/modified feature**

Submit an issue: https://github.com/Resurr3ction/qbs-autoproject/issues or send me an e-mail (see *Contact* below) and I will see what I can do.

**Why automatic project?**

I have grown sick over the years from writing the similar projects over and over either in qmake or Cmake or even in Qbs. First I have noticed a pattern to my projects and started to 'templatize' them to save on writing them but it was still the pain if I wanted to move things around, rename stuff etc. Not to mention the dependency hell that all large projects eventually slide into with dependencies that are no longer relevant still being there years later. And then I found Qbs and figured that I could actually make the projects entirely automatic using it. First I made few prototypes and used them and then I generalized it to qbs-autoproject for anyone to use.

**Ok, but beside saving me writing project files what are some other benefits?**

Well if not writing project files anymore is not enough, there are quite a few perks to using qbs-autproject as well.

1) Your projects can be small and many, large and plenty or just single directory of files. Since you do not need to write project file for each one and you can create and remove projects/products by creating/removing/renaming/moving files and directories it costs very little to change these patterns (as long as you follow them after) and to add new projects. Humans are better when dealing with smaller pieces rather than huge incoherent projects that nobody dares to split. In my experience with large projects adding more projects is always cumbersome and one does think twice (or indeed thrice) before doing it. Not with qbs-autoproject - just make a directory and start churning out those source files!

2) qbs-autoproject will force you to follow your patterns. Setting up patterns is easy. Following them is hard. Especially if what you need right now is just this quick fix here or easy hack there, right? And before you know it your project is a mess nobody understands, not even you, making it painful to work with. The patterns will save you. If you could just reliably know that **every** directory named *Test* is a product of type *Application* named `<parent-product-name>Test` or that **every** directory *include* is part of the product in which it is found or that all dependencies are correctly resolved... qbs-autoproject gives you that and if something is not quite right you might spot the problem right away because in 9 cases out of 10 a pattern will be broken somewhere.

3) You do not need to worry about dependencies. Adding includes and dependencies is easy. Removing them however is hard and is hardly ever done. If you are editing a source file and you remove some headers not only you have no idea where they came from but even if you did you cannot just remove the dependency on the module they come from because you cannot be sure it is not still being used elsewhere in the product. So you just leave it there. Eventually your projets are full of dead dependencies and links that are no longer valid. This has real implications because build-graphs generated from such projects are not as efficient as they could be. When building only certain project you may be needlessly rebuilding lots of declared dependencies that are never actually used. qbs-autproject will always keep your dependencies correct, up-to-date and exactly the way they need to be set.

And last but not least but I firmly believe that you will find not writing projects anymore really enjoyable. :-)

**And what about the downsides?**

As with everything in the (programming) world everything comes at a price. See *Limitations* above for some of the downsides.

## Requests & Bug Reports

Both requests and especially bug reports should be submitted as [issues on GitHub](https://github.com/Resurr3ction/qbs-autoproject/issues).


## Contact

You can contact me via e-mail at resurrection\[at]centrum.cz

## License

[MIT](https://github.com/Resurr3ction/qbs-autoproject/blob/master/LICENSE)
