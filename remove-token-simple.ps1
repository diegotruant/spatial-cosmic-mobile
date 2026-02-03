# Script semplificato per rimuovere token GitHub dalla storia Git
# Usa BFG Repo-Cleaner (più veloce e sicuro) o git filter-branch

Write-Host "=== Rimozione Token GitHub dalla Storia Git ===" -ForegroundColor Cyan
Write-Host ""

# Metodo 1: Usa BFG Repo-Cleaner (consigliato, ma richiede installazione)
# Download: https://rtyley.github.io/bfg-repo-cleaner/
# java -jar bfg.jar --replace-text passwords.txt

# Metodo 2: Usa git filter-repo (più moderno di filter-branch)
# pip install git-filter-repo
# git filter-repo --path android/gradle.properties --invert-paths
# Poi ricrea il file corretto

# Metodo 3: Usa git filter-branch (funziona sempre, ma più lento)
Write-Host "Metodo: git filter-branch" -ForegroundColor Yellow
Write-Host ""

# Crea file temporaneo con il contenuto corretto
$correctContent = @"
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
"@

# Salva il contenuto corretto
$correctContent | Out-File -FilePath "gradle.properties.correct" -Encoding utf8

Write-Host "Eseguendo git filter-branch..." -ForegroundColor Cyan
Write-Host "Questo potrebbe richiedere alcuni minuti..." -ForegroundColor Yellow
Write-Host ""

# Usa git filter-branch per sostituire il file in tutti i commit
git filter-branch --force --tree-filter `
    "if [ -f android/gradle.properties ]; then cp gradle.properties.correct android/gradle.properties; fi" `
    --prune-empty --tag-name-filter cat -- --all

# Rimuovi il file temporaneo
Remove-Item "gradle.properties.correct" -ErrorAction SilentlyContinue

# Pulisci i riferimenti
git for-each-ref --format="%(refname)" refs/original/ | ForEach-Object { git update-ref -d $_ }

Write-Host ""
Write-Host "Completato! Verifica con:" -ForegroundColor Green
Write-Host "  git log --all -S 'ghp_' -- android/gradle.properties" -ForegroundColor Gray
Write-Host ""
Write-Host "Se non ci sono risultati, il token è stato rimosso." -ForegroundColor Green
Write-Host "Poi fai: git push origin --force --all" -ForegroundColor Yellow

