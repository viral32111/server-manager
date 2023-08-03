function Combine-Numbers {
	Param( [int] $number1, [int] $number2 );

	$result = $number1 + $number2;
	Write-Host( "The result is: $result" );
}

[int] $firstNumber = 100;
[int] $secondNumber = 200;

Combine-Numbers -number1 $firstNumber -number2 $secondNumber;
