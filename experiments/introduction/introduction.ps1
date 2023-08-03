# Print hello world to the console
Write-Host( "Hello World!" );

# Write-Host removes the table formatting, while Write-Output keeps it
#Write-Host( Get-Process )
#Write-Output( Get-Process );

# Get input from the user then output it back to the user
[string] $userLocation = Read-Host( "Enter where you live" );
Write-Host( "Your location is: " + $userLocation );

# Print the data type of the variable
Write-Host( "The data type of the input is: " + $userLocation.GetType().Name );

# Add two numbers together
$numberOne = 1;
$addNumbers = $numberOne + 5;
Write-Host( $addNumbers );

# Write out coloured text
Write-Host -ForegroundColor Yellow "This is yellow text.";
Write-Host -ForegroundColor Blue "This is blue text.";

# Get the current date
[DateTime] $rightNow = Get-Date
Write-Host( $rightNow );

# Display the length and count
Write-Host( "The length of the string is: " + $userLocation.Length );
Write-Host( "The count of the string is: " + $userLocation.Count );

# Divide a string up
Write-Output( "Hello World".Split( " " ) );
