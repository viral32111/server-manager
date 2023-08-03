Write-Host( "1. Show running processes that begin with _____`n2. Start a process.`n3. Output the current running processes to a file." );

[int] $menuChoice = Read-Host( "Enter your choice" );

if ( $menuChoice -eq 1 ) {
	[string] $searchQuery = Read-Host( "Enter your query" );

	Write-Output( Get-Process -Name ( $searchQuery + "*" ) );

} elseif ( $menuChoice -eq 2 ) {
	[string] $processName = Read-Host( "Enter the process name" );

	Start-Process( $processName );
} elseif ( $menuChoice -eq 3 ) {
	Get-Process | Out-File -FilePath "Processes.txt"
}
