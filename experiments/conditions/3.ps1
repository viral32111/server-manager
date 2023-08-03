[int] $userNumber = Read-Host( "Enter a number" );

if ( $userNumber -gt 0 -and $userNumber -lt 50 ) {
	Write-Host( "The number is between 1 and 50" );
} elseif ( $userNumber -gt 50 -and $userNumber -lt 100 ) {
	Write-Host( "The number is between 50 and 100." );
} elseif ( $userNumber -gt 100 ) {
	Write-Host( "The number is greater than 100." );
}
