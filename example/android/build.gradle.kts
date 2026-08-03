import java.net.URI

allprojects {
    repositories {
        google()
        mavenCentral()
        // TODO: Remove the snapshots repository once PowerAuth SDK 2.0.0 is released.
        maven { url = URI("https://central.sonatype.com/repository/maven-snapshots/") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
