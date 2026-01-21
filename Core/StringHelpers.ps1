function ConvertTo-String {
    param([object]$v)
    if ($null -eq $v) { return 'White' }
    return [string]$v
}