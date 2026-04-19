import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val androidManifestPackage = Regex("""package\s*=\s*"([^"]+)"""")

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<LibraryExtension> {
            if (namespace == null) {
                val manifestFile = project.layout.projectDirectory.file("src/main/AndroidManifest.xml").asFile
                val manifestNamespace =
                    manifestFile
                        .takeIf { it.exists() }
                        ?.readText()
                        ?.let { androidManifestPackage.find(it)?.groupValues?.getOrNull(1) }

                if (!manifestNamespace.isNullOrBlank()) {
                    namespace = manifestNamespace
                }
            }
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
