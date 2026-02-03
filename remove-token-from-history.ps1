# Script to remove GitHub token from git history
$file = "android/gradle.properties"
$oldPattern = 'password = "ghp_[^"]*"'
$newPattern = 'password = project.findProperty("GITHUB_TOKEN") ?: ""'

# Get all commits that touched the file
$commits = git log --all --format="%H" -- $file

foreach ($commit in $commits) {
    Write-Host "Processing commit $commit"
    
    # Checkout the commit
    git checkout $commit -- $file 2>$null
    
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match $oldPattern) {
            $content = $content -replace $oldPattern, $newPattern
            Set-Content $file -Value $content -NoNewline
            git add $file
            git commit --amend --no-edit
            Write-Host "Fixed commit $commit"
        }
    }
}

Write-Host "Done! Now run: git push --force"

