import java.io.FileInputStream 
import java.util.Properties
import kotlin.collections.setOf // <--- Explicitly importing setOf() fix
import com.android.build.gradle.internal.cxx.configure.JsonGenerationAccess.file

// --- START: SIGNING KEY CONFIGURATION ---
// Load signing properties from the key.properties file
val signingProperties = Properties() 
val signingPropertiesFile = file("../key.properties")

if (signingPropertiesFile.exists()) {
    signingProperties.load(FileInputStream(signingPropertiesFile))
}
// --- END: SIGNING KEY CONFIGURATION ---

android {
    namespace = "com.rentease.app"
    compileSdk = 34 // Use the highest available SDK
    ndkVersion = "25.2.8937393" 

    defaultConfig {
        applicationId = "com.rentease.app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file(signingProperties.getProperty("storeFile") ?: "")
            storePassword = signingProperties.getProperty("storePassword")
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true 
        }
        debug {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    // --- THIS IS THE FIX for Line 62 (setOf) ---
    source setOf("..") 
}