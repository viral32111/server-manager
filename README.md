# Server Manager

This is a scripted user interface for managing and diagnosing problems with Windows-based servers that I made back in 2021.

It uses [the `System.Windows.Forms` .NET namespace](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms?view=windowsdesktop-7.0), so the interface is the same as one that would be created via [C# using the .NET Framework](https://dotnet.microsoft.com/en-us/download/dotnet-framework).

Yes, the 1000+ lines of code is within a single PowerShell script. Yes, I know that is not ideal. 😛

Ignore [the experiments directory](/experiments/), it just contains the code I made while learning PowerShell.

## Features

* Login - Protection against unauthorized access.
* Server Status - Check if the server is online via ICMP ping.
* Service Status - Check if the DNS, DHCP and ADDS (Active Directory) services are running.
* User Management - Create & update Active Directory users.
* Bulk Import - Import users into Active Directory from [a comma-separated values file](/active-directory-bulk-user-import.csv).

## Usage

1. Download [the `server-manager.ps1` script](/server-manager.ps1).
2. Edit the script to [configure the server & active directory options](/server-manager.ps1#L14-L23).
3. Launch the script via PowerShell.

I tested this on a [Windows Server 2022](https://www.microsoft.com/en-us/windows-server/) virtual machine.

## License

Copyright (C) 2021-2023 [viral32111](https://viral32111.com).

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see https://www.gnu.org/licenses.
