[int] $monthNumber = Read-Host( "Enter a month of the year" );

switch ( $monthNumber ) {
	1 {
		Write-Host( "The month is January." );
		break;
	}
	2 {
		Write-Host( "The month is Feburary." );
		break;
	}
	3 {
		Write-Host( "The month is March." );
		break;
	}
	4 {
		Write-Host( "The month is April." );
		break;
	}
	5 {
		Write-Host( "The month is May." );
		break;
	}
	6 {
		Write-Host( "The month is June." );
		break;
	}
	7 {
		Write-Host( "The month is July." );
		break;
	}
	8 {
		Write-Host( "The month is August." );
		break;
	}
	9 {
		Write-Host( "The month is September." );
		break;
	}
	10 {
		Write-Host( "The month is October." );
		break;
	}
	11 {
		Write-Host( "The month is November." );
		break;
	}
	12 {
		Write-Host( "The month is December." );
		break;
	}
	default {
		Write-Host( "That is not a valid month number." );
		break;
	}
}
