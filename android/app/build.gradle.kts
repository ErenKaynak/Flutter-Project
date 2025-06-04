plugins {
    id("com.android.application")
    kotlin("android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.engineering_project"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.example.engineering_project"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        
        manifestPlaceholders["onesignal_app_id"] = "bb5b6419-07c9-4b72-9d85-e2c121f05591"
        manifestPlaceholders["onesignal_google_project_number"] = "52042306180"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-functions-ktx")
    implementation("com.google.android.gms:play-services-basement:18.2.0")
    implementation("com.google.android.gms:play-services-safetynet:18.0.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("com.onesignal:OneSignal:5.0.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.20")
}