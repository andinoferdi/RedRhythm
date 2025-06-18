# Script to add fontFamily: 'Gotham' to all TextStyle instances
Write-Host "Adding Gotham font family to all TextStyle instances..."

# Get all dart files in lib directory
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $dartFiles) {
    Write-Host "Processing: $($file.FullName)"
    
    # Read file content
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Simple replacements - add fontFamily to common patterns
    # Pattern 1: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w700,)
    $content = $content -replace "TextStyle\(\s*color:\s*Colors\.grey\[400\],\s*fontSize:\s*18,\s*fontWeight:\s*FontWeight\.w700,\s*\)", "TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Gotham',)"
    
    # Pattern 2: TextStyle(color: Colors.grey[600], fontSize: 14,)
    $content = $content -replace "TextStyle\(\s*color:\s*Colors\.grey\[600\],\s*fontSize:\s*14,\s*\)", "TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Gotham',)"
    
    # Pattern 3: TextStyle(color: Colors.white70)
    $content = $content -replace "TextStyle\(color:\s*Colors\.white70\)", "TextStyle(color: Colors.white70, fontFamily: 'Gotham')"
    
    # Pattern 4: TextStyle(color: Colors.white54)
    $content = $content -replace "TextStyle\(color:\s*Colors\.white54\)", "TextStyle(color: Colors.white54, fontFamily: 'Gotham')"
    
    # Pattern 5: TextStyle(color: AppColors.text)
    $content = $content -replace "TextStyle\(color:\s*AppColors\.text\)", "TextStyle(color: AppColors.text, fontFamily: 'Gotham')"
    
    # Pattern 6: TextStyle(fontWeight: FontWeight.bold)
    $content = $content -replace "TextStyle\(fontWeight:\s*FontWeight\.bold\)", "TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Gotham')"
    
    # Pattern 7: const TextStyle(fontSize: 14)
    $content = $content -replace "const TextStyle\(fontSize:\s*14\)", "const TextStyle(fontSize: 14, fontFamily: 'Gotham')"
    
    # Pattern 8: const TextStyle(color: Colors.red)
    $content = $content -replace "const TextStyle\(color:\s*Colors\.red\)", "const TextStyle(color: Colors.red, fontFamily: 'Gotham')"
    
    # Write back if changed
    if ($content -ne $originalContent) {
        Set-Content $file.FullName $content -Encoding UTF8
        Write-Host "  Updated $($file.Name)"
    } else {
        Write-Host "  No changes needed for $($file.Name)"
    }
}

Write-Host "Done! TextStyle instances updated with Gotham font." 