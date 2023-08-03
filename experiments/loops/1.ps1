for ( [int] $iteration = 0; $iteration -lt 5; $iteration++ ) {
	[string] $firstName = Read-Host( "Enter your first name" );
	[string] $secondName = Read-Host( "Enter your second name" );

	Write-Host( "Your first name is $firstName, and your second name $secondName." );
}
