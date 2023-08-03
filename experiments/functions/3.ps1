function Is-Positive {
	Param( [int] $number );

	return ( $number -ge 0 );
}

function Is-Negative {
	Param( [int] $number );

	return ( $number -le -1 );
}

[int] $userNumber = Read-Host -Prompt "Enter a number";
[string] $userChoice = Read-Host -Prompt "Check for 'positive' or 'negative'";

if ( $userChoice -eq "positive" ) {
	Write-Host( Is-Positive -number $userNumber );
} elseif ( $userChoice -eq "negative" ) {
	Write-Host( Is-Negative -number $userNumber );
}