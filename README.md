# Mirror Maven packages for Artifactory

## Usage

1. List your package requirements in a .txt (e.g. `packages.txt`) file, using the Gradle `<groupId>:<artifactId>:<version>` syntax. Each package declaration should occupy one line. For example:

   ```txt
   org.springframework.boot:spring-boot-starter:2.3.4.RELEASE
   org.springframework.boot:spring-boot-starter-web:latest.release
   org.springframework.data:spring-data-jpa:2.3.4.RELEASE
   com.fasterxml.jackson.core:jackson-core:2.11.2
   ```

   > Mount this file inside directory `/opt/java-pipeline/pkglists`.

   > If you do not wish to define a specific version, then you will have to define it using `latest.release` e.g `org.springframework.boot:spring-boot-starter:latest.release`

1. List your plugin requirements (if any) in a .txt (e.g. `plugins.txt`) file, using the Gradle plugin syntax. Each plugin declaration should occupy one line. For example:

   ```txt
   com.diffplug.gradle.spotless:3.18.0
   org.springframework.boot:2.3.4.RELEASE
   ```

   > Mount this file inside directory `/opt/java-pipeline/pluginlists`.

   > java, java-library and eclipse are added by default, hence, it is not required to declare these plugins

1. If there are additional Maven repositories to be included in addition to the default list below, list them inside a .txt file (e.g. `repo.txt`). Each URL should occupy one line with **TRAILING NEW LINE**. For example:

   ```txt
   https://repo1.example.com/releases
   https://repo2.example.org/libs-releases

   ```

   Note that you will need to explicitly list the URLs for the usual repositories such as jCenter or Maven Central.

   > Mount this file inside directory `/opt/java-pipeline/repolists`.

   The default Maven repositories included are:

   ```txt
   https://repo1.maven.org/maven2/
   https://oss.sonatype.org/content/repositories/releases/
   https://plugins.gradle.org/m2/
   https://jcenter.bintray.com/
   https://maven.google.com/
   https://jitpack.io/
   https://repo.spring.io/milestone
   ```

1. Run the download script:

   ```sh
   # For Windows
   docker run -it --name java-pipeline ^
      -v %cd%\packages.txt:/opt/java-pipeline/pkglists/packages.txt ^
      -v %cd%\plugins.txt:/opt/java-pipeline/pluginlists/plugins.txt ^
      -v %cd%\download:/opt/java-pipeline/target ^
      deskoh/gradle-pipeline

   # For Linux / WSL
   docker run -it --name java-pipeline \
      -v ./packages.txt:/opt/java-pipeline/pkglists/packages.txt \
      -v ./plugins.txt:/opt/java-pipeline/pluginlists/plugins.txt \
      -v ./download:/opt/java-pipeline/target \
      deskoh/gradle-pipeline bash

   # Subsequent download (update .txt files)
   docker start java-pipeline
   ```

1. When the download script completes, collect the .zip file from the `download` directory. The name of the .zip file will conform to this pattern:

   ```txt
   jars-<yyyymmdd>-<hhmm>.zip
   ```

   Where `<yyyymmdd>-<hhmm>` is the date and time you executed the download.

IMPORTANT NOTES

 - Note that the tool clears your local Gradle cache as part of its normal
   operation, and there is no way to disable this behaviour. This is done in
   order to ensure that the output .zip file does not contain any packages
   you do not need.