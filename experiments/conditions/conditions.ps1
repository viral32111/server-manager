# Number assignment to variables
[ int ] $myFirstNumber = 30;
[ int ] $mySecondNumber = 30;

# Output value of the variables
Write-Host( "The first number is $myFirstNumber, and the second is $mySecondNumber." );

# Comparison using numerical operators
if ( $myFirstNumber -eq $mySecondNumber ) {
	Write-Host( "The numbers are equal." );
} elseif ( $myFirstNumber -ne $mySecondNumber ) {
	Write-Host( "The first number is not equal to the second number." );
} elseif ( $myFirstNumber -gt $mySecondNumber ) {
	Write-Host( "The first number is greater than the second number." );
} elseif ( $myFirstNumber -ge $mySecondNumber ) {
	Write-Host( "The first number is greater than or equal to the second number." );
} elseif ( $myFirstNumber -lt $mySecondNumber ) {
	Write-Host( "The first number is less than the second number." );
} elseif ( $myFirstNumber -le $mySecondNumber ) {
	Write-Host( "The first number is less than or equal to the second number." );
} else {
	Write-Host( "Entropy has taken over the universe." );
}

# Increment and decrement operators
$myFirstNumber += 10;
$mySecondNumber -= 5;

# Boolean assignment to variables
[ bool ] $myFirstBool = true;
[ bool ] $mySecondBool = false;

# Comparison using logical operators
if ( $myFirstBool -or $mySecondBool ) {
	Write-Host( "Either boolean is true." );
} elseif ( $myFirstBool -and $mySecondBool ) {
	Write-Host( "Both booleans are true." );
} elseif ( $myFirstBool -xor $mySecondBool ) {
	Write-Host( "The first boolean is true, and the second boolean is not." );
} elseif ( !$myFirstBool ) {
	Write-Host( "The first boolean is false." );
} elseif ( !$mySecondBool ) {
	Write-Host( "The second boolean is false." );
} else {
	Write-Host( "I missed something!" );
}

# Comparison of numbers using switch statement
switch ( $myFirstNumber ) {
	10 {
		Write-Host( "The first number is ten." );
		break;
	}

	20 {
		Write-Host( "The first number is twenty." );
		break;
	}

	30 {
		Write-Host( "The first number is thirty." );
		break;
	}
}
