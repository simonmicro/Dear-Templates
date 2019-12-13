# 0. Compile any sources to ".class"-files #
`javac *.java [ANY OTHER PATH WHICH CONTAINS USED SOURCES]`

# 1. Create a manifest file (here called manifest.txt) #
`nano manifest.txt`

# 1.1 Insert "Main-Class: [PACKAGENAME.CLASSNAME]" where the main function is located #
```
Main-Class: ExampleClass
```

# 2. Pack anything to a ".jar"-archive #
`jar -cvfm [.JAR NAME] [MANIFESTFILENAME] [PATH TO ANY .CLASS FILE] [PATH TO ANY FOLDER STRUCTURE]`

# 3. Run the archive #
`java -jar [.JAR NAME]`

# Just in case of curiosity #
The .jar file contains a virtual directory with all packages in their own subfolders and any .class files from the default one in the root folder. Additionally there should be an folder called "META-INF" containing a copy of the manifest file, so the jvm can find the main class directly. This folder CAN BE DELETED, so the jvm has to search for the correct main class (this may not work on newer java versions).
