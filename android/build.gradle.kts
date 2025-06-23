buildscript {
    // Define versions using Kotlin DSL syntax
    val agpVersion by extra("8.3.0")  // Updated to 8.3.0
    val kotlinVersion by extra("1.8.10")  // Downgraded to match plugin version
    
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:${agpVersion}")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${kotlinVersion}")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
