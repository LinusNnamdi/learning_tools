import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // The Flutter Gradle Plugin must be applied after
    // the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/*
 * Load the release signing credentials from:
 *
 * android/key.properties
 *
 * This keeps passwords and the keystore location
 * outside this build.gradle.kts file.
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {
    namespace = "com.earndeeltd.animate"
    compileSdk = 37
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.earndeeltd.animate"

        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = 5
        versionName = "1.9.9"
    }

    /*
     * RELEASE SIGNING
     *
     * This configuration reads your OLD/CORRECT
     * Google Play upload key information from
     * android/key.properties.
     */
    signingConfigs {
        create("release") {
            keyAlias =
                keystoreProperties.getProperty("keyAlias")

            keyPassword =
                keystoreProperties.getProperty("keyPassword")

            storeFile =
                keystoreProperties
                    .getProperty("storeFile")
                    ?.let { file(it) }

            storePassword =
                keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            /*
             * IMPORTANT:
             *
             * Previously this was:
             *
             * signingConfig = signingConfigs.getByName("debug")
             *
             * Now release builds use your actual
             * release/upload keystore.
             */
            signingConfig =
                signingConfigs.getByName("release")

            // Diagnostic: completely disable R8 shrinking/obfuscation.
            isMinifyEnabled = false

            // Resource shrinking requires code shrinking, so disable this too.
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

//Added by me
dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.19.0"))


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}