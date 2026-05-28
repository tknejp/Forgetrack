import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // Kotlin is brought in by the Flutter gradle plugin (Built-in Kotlin).
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.knejp.forgetrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.knejp.forgetrack"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Health Connect vyžaduje min. API 26 (Android 8.0)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Forgetrack DEV")
            // Route to the FAD plugin's `production` flavor (stub artifact only).
            missingDimensionStrategy("default", "production")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Forgetrack")
            // Play Store flavor: stub FAD artifact, no install-packages permission.
            missingDimensionStrategy("default", "production")
        }
        create("internal") {
            dimension = "environment"
            // Intentionally NO applicationIdSuffix — shares `com.knejp.forgetrack`
            // with `prod` so the existing Firebase app + FAD distribution group
            // continue to apply, and testers upgrade in-place from prod→internal
            // (or vice versa) without losing local data.
            resValue("string", "app_name", "Forgetrack Internal")
            // Pull the full firebase-appdistribution SDK via the FAD plugin's
            // `staging` flavor. Pairs with the manifest split under
            // android/app/src/internal/AndroidManifest.xml (REQUEST_INSTALL_PACKAGES).
            missingDimensionStrategy("default", "staging")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Use the release signing config when android/key.properties is present;
            // otherwise fall back to debug so `flutter run --release` keeps working
            // on machines / CI without the upload keystore.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}