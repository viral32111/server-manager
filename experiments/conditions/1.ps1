[int] $userNumber = Read-Host( "Enter a number" );

switch ( $userNumber ) {
	1 {
		Write-Host( "You entered 1" );
		break;
	}
	2 {
		Write-Host( "You entered 2" );
		break;
	}
	3 {
		Write-Host( "You entered 3" );
		break;
	}
	4 {
		Write-Host( "You entered 4" );
		break;
	}
	5 {
		Write-Host( "You entered 5" );
		break;
	}
	default {
		Write-Host( "You can only enter a number between 1 and 5." );
		break;
	}
}
