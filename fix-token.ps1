# Script per sostituire il token GitHub nella storia Git
$env:FILTER_BRANCH_SQUELCH_WARNING=1

# Contenuto corretto del file
$correctContent = @'
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
repositories {
    google()
    mavenCentral()
    maven {
        url = uri("https://maven.pkg.github.com/hammerheadnav/karoo-ext")
        credentials {
            username = project.findProperty("GITHUB_USERNAME") ?: "Diego DDTraining"
            password = project.findProperty("GITHUB_TOKEN") ?: ""
        }
    }
}
'@

# Salva il contenuto corretto
$correctContent | Out-File -FilePath "gradle-correct.txt" -Encoding utf8 -NoNewline

# Usa git filter-branch per sostituire il file
git filter-branch --force --tree-filter `
    "if [ -f android/gradle.properties ]; then cp gradle-correct.txt android/gradle.properties; fi" `
    --prune-empty --tag-name-filter cat -- --all

# Rimuovi file temporaneo
Remove-Item "gradle-correct.txt" -ErrorAction SilentlyContinue

# Pulisci riferimenti
git for-each-ref --format="%(refname)" refs/original/ | ForEach-Object { git update-ref -d $_ }

# Garbage collection
git reflog expire --expire=now --all
git gc --prune=now --aggressive

Write-Host "Completato! Verifica con: git log --all -S 'ghp_' -- android/gradle.properties"

