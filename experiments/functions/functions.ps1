# Define functions
function Print-Message {
	Write-Host( "Hello World! This was called from a function." );
}

function Display-Number {
	Param( [int] $number );

	Write-Host( "The number is: $number" );
}


# Call the functions
[int] $firstNumber = 100;
[int] $secondNumber = 200;

Print-Message;
Display-Number -number $firstNumber;