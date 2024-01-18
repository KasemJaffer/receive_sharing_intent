plugins {
    id("com.android.application") version "7.4.2" apply false
    kotlin("android") version "1.8.10" apply false
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}
