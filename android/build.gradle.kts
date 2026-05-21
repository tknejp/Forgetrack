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
    // Many Flutter plugins pin compileSdk to an old API level (e.g. isar_flutter_libs
    // -> 31), which makes their per-library verifyReleaseResources task fail on
    // resources from newer androidx artifacts (e.g. android:attr/lStar from API 31).
    // Overriding compileSdk fights AGP 8's "too late to set" guard, so we disable
    // the per-library check instead — the same linking is re-verified when the app
    // module assembles with its own (modern) compileSdk.
    afterEvaluate {
        tasks.matching { it.name == "verifyReleaseResources" }.configureEach {
            enabled = false
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
