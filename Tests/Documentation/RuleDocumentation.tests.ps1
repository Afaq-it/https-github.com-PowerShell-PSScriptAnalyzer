$directory = Split-Path -Parent $MyInvocation.MyCommand.Path
$testRootDirectory = Split-Path -Parent $directory
$repoRootDirectory = Split-Path -Parent $testRootDirectory
$ruleDocDirectory = Join-Path $repoRootDirectory RuleDocumentation

Import-Module (Join-Path $testRootDirectory "PSScriptAnalyzerTestHelper.psm1")

Describe "Validate rule documentation files" {
    BeforeAll {
        $docs = Get-ChildItem $ruleDocDirectory/*.md -Exclude README.md |
            ForEach-Object { "PS" + $_.BaseName} | Sort-Object
        $rules = Get-ScriptAnalyzerRule | ForEach-Object RuleName | Sort-Object
        $rulesDocsDiff = Compare-Object -ReferenceObject $rules -DifferenceObject $docs -SyncWindow 25

        $readmeLinks = @{}
        $readmeRules = Get-Content -LiteralPath $ruleDocDirectory/README.md |
            Foreach-Object { if ($_ -match '^\s*\|\s*\[([^]]+)\]\(([^)]+)\)\s*\|') {
                $ruleName = $matches[1]
                $readmeLinks["$ruleName"] = $matches[2]
                "PS${ruleName}"
            }} |
            Sort-Object
        $rulesReadmeDiff = Compare-Object -ReferenceObject $rules -DifferenceObject $readmeRules -SyncWindow 25
    }

    It "Every rule must have a rule documentation file" {
        $rulesDocsDiff | Where-Object SideIndicator -eq "<=" | Foreach-Object InputObject | Should -BeNullOrEmpty
    }
    It "Every rule documentation file must have a corresponding rule" {
        $rulesDocsDiff | Where-Object SideIndicator -eq "=>" | Foreach-Object InputObject | Should -BeNullOrEmpty
    }

    It "Every rule must have an entry in the rule documentation README.md file" {
        $rulesReadmeDiff | Where-Object SideIndicator -eq "<=" | Foreach-Object InputObject | Should -BeNullOrEmpty
    }
    It "Every entry in the rule documentation README.md file must correspond to a rule" {
        $rulesReadmeDiff | Where-Object SideIndicator -eq "=>" | Foreach-Object InputObject | Should -BeNullOrEmpty
    }

    It "Every entry in the rule documentation README.md file must have a valid link to the documentation file" {
        foreach ($key in $readmeLinks.Keys) {
            $link = $readmeLinks[$key]
            $filePath = Join-Path $ruleDocDirectory $link
            $filePath | Should -Exist
        }
    }
    It "Every rule name in the rule documentation README.md file must match the documentation file's basename" {
        foreach ($key in $readmeLinks.Keys) {
            $link = $readmeLinks[$key]
            $filePath = Join-Path $ruleDocDirectory $link
            $fileName = Split-Path $filePath -Leaf
            $fileName | Should -BeExactly "${key}.md"
        }
    }
}
