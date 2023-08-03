# Display CSV data
$myData = Import-Csv -Path "data.csv"
Write-Output -InputObject $myData;

# Write CSV data
Get-Process | Export-Csv -path "processes.csv"

# Write CSV from custom data structure
$people = @(
	[ PSCustomObject ]@{
		Name = "A"
		Age = "1"
	}

	[ PSCustomObject ]@{
		Name = "B"
		Age = "2"
	}
	
	[ PSCustomObject ]@{
		Name = "C"
		Age = "3"
	}
)

Export-Csv -InputObject $people -path "people.csv" -NoTypeInformation
