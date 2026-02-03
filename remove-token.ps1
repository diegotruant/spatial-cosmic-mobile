# Script per rimuovere token GitHub dalla storia Git
# ATTENZIONE: Questo riscrive la storia Git - fai backup prima!

Write-Host "Rimozione token GitHub dalla storia Git..." -ForegroundColor Yellow
Write-Host "ATTENZIONE: Questo riscriverà la storia Git!" -ForegroundColor Red
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

Write-Host "Backup del branch corrente..." -ForegroundColor Cyan
git branch backup-before-token-removal

Write-Host "Rimozione token dalla storia..." -ForegroundColor Cyan

# Usa git filter-branch per rimuovere il token
# Cerca pattern come: password = "ghp_..." e sostituisci con password = project.findProperty("GITHUB_TOKEN") ?: ""
git filter-branch --force --index-filter `
    "git update-index --remove android/gradle.properties 2>/dev/null || true && git checkout HEAD -- android/gradle.properties && (Get-Content android/gradle.properties) -replace 'password = `"ghp_[^`"]*`"', 'password = project.findProperty(\"GITHUB_TOKEN\") ?: \"\"' | Set-Content android/gradle.properties && git add android/gradle.properties" `
    --prune-empty --tag-name-filter cat -- --all

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Token rimosso con successo!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prossimi passi:" -ForegroundColor Yellow
    Write-Host "1. Verifica che il token sia stato rimosso:" -ForegroundColor White
    Write-Host "   git log --all -S 'ghp_' -- android/gradle.properties" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Se tutto è OK, forza il push:" -ForegroundColor White
    Write-Host "   git push origin --force --all" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Se qualcosa va storto, ripristina:" -ForegroundColor White
    Write-Host "   git reset --hard backup-before-token-removal" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "ERRORE durante la rimozione del token" -ForegroundColor Red
    Write-Host "Ripristina con: git reset --hard backup-before-token-removal" -ForegroundColor Yellow
}

