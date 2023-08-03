[array] $userInputs = @();

while ( 1 ) {
	$userInput = Read-Host( "Please enter a value" )

	$userInputs.Add( $userInput ); 
}
