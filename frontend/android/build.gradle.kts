allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// ── AGP 8.x namespace compatibility shim ─────────────────────────────────────
// Some older Flutter plugins (e.g. flutter_jailbreak_detection ≤ 1.10.0) were
// written before AGP required an explicit `namespace` in the library build file.
// This hook auto-derives one from the plugin's applicationId / package name so
// the build doesn't fail without us having to fork every affected plugin.
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            val ext = extensions.findByName("android")
            if (ext is com.android.build.gradle.LibraryExtension) {
                if (ext.namespace == null) {
                    val pkg = ext.defaultConfig.applicationId
                        ?: project.group.toString().takeIf { it.isNotBlank() }
                        ?: "com.plugin.${project.name.replace("-", "_").replace(".", "_")}"
                    ext.namespace = pkg
                }
            }
        }
    }
}
// ─────────────────────────────────────────────────────────────────────────────

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
