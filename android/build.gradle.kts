group = "com.kasem.receive_sharing_intent"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library") version "7.4.2"
    kotlin("android") version "1.8.10"
}

android {
    compileSdk = 33

    defaultConfig {
        minSdk = 16
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    lintOptions {
        disable += "InvalidPackage"
    }
}
