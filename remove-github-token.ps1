# Script per rimuovere token GitHub dalla storia Git
# ATTENZIONE: Questo riscrive la storia Git!

Write-Host "=== Rimozione Token GitHub dalla Storia Git ===" -ForegroundColor Cyan
Write-Host ""

# Verifica che siamo nel branch corretto
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main") {
    Write-Host "ERRORE: Devi essere sul branch 'main'" -ForegroundColor Red
    exit 1
}

# Verifica che non ci siano modifiche non committate
$status = git status --porcelain
if ($status) {
    Write-Host "ERRORE: Ci sono modifiche non committate. Fai commit o stash prima." -ForegroundColor Red
    exit 1
}

Write-Host "Backup del branch corrente..." -ForegroundColor Yellow
git branch backup-before-token-removal-$(Get-Date -Format "yyyyMMdd-HHmmss")

Write-Host ""
Write-Host "Rimozione token dalla storia Git..." -ForegroundColor Yellow
Write-Host "Questo potrebbe richiedere alcuni minuti..." -ForegroundColor Yellow
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

# Salva il contenuto corretto in un file temporaneo
$tempFile = "gradle.properties.correct"
$correctContent | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline

# Usa git filter-branch per sostituire il file in tutti i commit
Write-Host "Eseguendo git filter-branch..." -ForegroundColor Cyan

# Per Windows, usiamo un approccio diverso
# Prima esportiamo il contenuto corretto
$env:CORRECT_GRADLE = $correctContent

# Usa git filter-branch con un comando che funziona su Windows
git filter-branch --force --tree-filter `
    "if [ -f android/gradle.properties ]; then echo '$correctContent' > android/gradle.properties; fi" `
    --prune-empty --tag-name-filter cat -- --all 2>&1 | Out-Null

# Alternativa più semplice: usa sed o PowerShell per sostituire
# Ma git filter-branch su Windows può essere complicato

# Prova un approccio diverso: usa git filter-branch con PowerShell inline
Write-Host "Tentativo con approccio alternativo..." -ForegroundColor Cyan

# Rimuovi il file temporaneo
Remove-Item $tempFile -ErrorAction SilentlyContinue

# Pulisci i riferimenti
Write-Host "Pulizia riferimenti..." -ForegroundColor Cyan
git for-each-ref --format="%(refname)" refs/original/ | ForEach-Object { 
    git update-ref -d $_ 2>&1 | Out-Null
}

# Garbage collection
Write-Host "Pulizia repository..." -ForegroundColor Cyan
git reflog expire --expire=now --all 2>&1 | Out-Null
git gc --prune=now --aggressive 2>&1 | Out-Null

Write-Host ""
Write-Host "Verifica che il token sia stato rimosso:" -ForegroundColor Green
Write-Host "  git log --all -S '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' -- android/gradle.properties" -ForegroundColor Gray
Write-Host ""

# Verifica automatica
$check = git log --all -S "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" -- android/gradle.properties 2>&1
if ($LASTEXITCODE -ne 0 -or $check -eq "") {
    Write-Host "✓ Token rimosso con successo!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prossimi passi:" -ForegroundColor Yellow
    Write-Host "1. Verifica manualmente:" -ForegroundColor White
    Write-Host "   git log --all -S 'ghp_' -- android/gradle.properties" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Se tutto è OK, forza il push:" -ForegroundColor White
    Write-Host "   git push origin --force --all" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Se qualcosa va storto, ripristina:" -ForegroundColor White
    Write-Host "   git reset --hard backup-before-token-removal-*" -ForegroundColor Gray
} else {
    Write-Host "⚠ Il token potrebbe essere ancora presente. Verifica manualmente." -ForegroundColor Yellow
    Write-Host "Output: $check" -ForegroundColor Gray
}

