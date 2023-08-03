# Define an array of strings
$myArray = @( "A", "B", "C" );

# For loop
for ( [int] $arrayIndex = 0; $arrayIndex -lt $myArray.Length; $arrayIndex++ ) {
	Write-Host( "Index is $arrayIndex, and the value is " + $myArray[ $arrayIndex ] );
}

# For each loop
foreach ( $myItem in $myArray ) {
	Write-Host( "The value is $myItem." );
}

# While loop
[int] $currentPosition = 0;
while ( $currentPosition -lt $myArray.Length ) {
	Write-Host( "Position is $currentPosition, and the value is " + $myArray[ $currentPosition ] );
	$currentPosition++;
}

# Do while loop
[int] $currentPosition = 0;
do {
	Write-Host( "Position is $currentPosition, and the value is " + $myArray[ $currentPosition ] );
	$currentPosition++;
} while ( $currentPosition -lt $myArray.Length )
