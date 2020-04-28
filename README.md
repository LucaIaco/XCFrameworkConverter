# XCFrameworkConverter
A bash script which can easily convert an existing compiled **framework** into the new **xcframework** packing standard

**Preconditions** : 
- MacOS running Xcode 11 or greater
- The source framework was built and distributed with the project build option `Build Libraries for Distribution` **enabled** ( without this, the script might generate the xcframwork successfully but this might not work once linked in your project )

**How to use**

The script takes as input the path to the existing framework folder, as shown below:

```bash
User@Domain TempFolder> sh xcframework_converter.sh /Users/JhonDoe/Downloads/MyFramework.framework
```

If successful the new xcframework `MyFramework.xcframework` will be created in the script folder under the path `<SCRIPT_PATH>/OutputFramework/MyFramework.xcframework`
