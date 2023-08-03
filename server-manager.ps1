##########################################
# Setup
##########################################

# Add the types from the Windows Forms .NET class
Add-Type -Assembly System.Windows.Forms;

# Add the active directory module
Import-Module ActiveDirectory;

# Stop processing if any errors occur
$ErrorActionPreference = "Stop";

##########################################
# Configuration
##########################################

# The IP address of the server for checking if its online
$serverIP = "10.0.0.1";

# The name of the Active Directory domain and primary Organisational Unit to manage users within
$domainName = "example.local";
$organisationalUnit = "Example Unit";

##########################################
# Fetch
##########################################

# Get the domain DN values for the path and the short name
$domainNames = ( Get-ADDomain $domainName | Select-Object -Property DistinguishedName, NetBIOSName, Forest );

# Set a full X.500 path to the organisational unit within the domain
$activeDirectoryPath = ( "OU=" + $organisationalUnit + "," + $domainNames.DistinguishedName );

##########################################
# Utility Functions
##########################################

# Checks if the current user running the script is in the Administrators group
function isRunningAsAdmin {

	# Get the identity of the user running this script
	[ Security.Principal.WindowsPrincipal ] $currentIdentity = [ Security.Principal.WindowsIdentity ]::GetCurrent();

	# Return true or false depending on if this identity is in the administrators group
	return $currentIdentity.IsInRole( "Administrators" );

}

# Checks if a username & password combination exists in Active Directory
function checkActiveDirectoryCredentials {
	param( [ string ] $Username, [ string ] $Password );

	# Instansiate a new directory entry object with an empty path (this server) & the provided credentials
	[ DirectoryServices.DirectoryEntry ] $directoryEntry = New-Object DirectoryServices.DirectoryEntry( "", $Username, $Password );

	# Return true if the directory entry result has a valid path, otherwise false
	return ( $directoryEntry.psbase.name -ne $null );

}

##########################################
# Form Functions
##########################################

# Makes a control responsive (anchoring it with optional padding)
function makeResponsive {
	param( [ System.Windows.Forms.Control ] $Control, [ int ] $Dock, [ int[] ] $Padding = @( 0, 0, 0, 0 ), [ bool ] $AutoSize = $false );

	# Instansiate a padding object and set each side using the values from the provided integer array
	[ System.Windows.Forms.Padding ] $controlPadding = New-Object System.Windows.Forms.Padding;
	$controlPadding.Top = $Padding[ 0 ];
	$controlPadding.Bottom = $Padding[ 1 ];
	$controlPadding.Left = $Padding[ 2 ];
	$controlPadding.Right = $Padding[ 3 ];

	# Set the padding to the object created above
	$Control.Padding = $controlPadding;

	# Set the dock position using the provided value
	$Control.Dock = $Dock; # DockStyle

	# Set the automatic sizing (defaults to false)
	$Control.AutoSize = $AutoSize;

}

# Enables/disables TAB switching and sets the order for a control
function makeTabSwitchable {
	param( [ System.Windows.Forms.Control ] $Control, [ bool ] $Enable, [ int ] $Index = 0 );

	# Set if this control should be part of the TAB switching
	$Control.TabStop = $Enable;

	# Set the order of TAB switching for this control if applicable
	# NOTE: Minus 1 because it starts at 0
	if ( $Enable -eq $true ) {
		$Control.TabIndex = $Index - 1;
	}

}

# Creates a responsive control (control placed within a panel)
function makeResponsiveControl {
	param( [ System.Windows.Forms.Control ] $Parent, $Type, [ int[] ] $Padding, [ int ] $PanelTabIndex = -1 );

	############# Panel #############

	# Instansiate a new panel to hold the control
	[ System.Windows.Forms.Panel ] $containerPanel = New-Object System.Windows.Forms.Panel;

	#$containerPanel.BackColor = "blue";

	# Disable TAB switching to this panel by default unless specified
	if ( $PanelTabIndex -ge 1 ) {
		makeTabSwitchable -Control $containerPanel -Enable $true -Index $PanelTabIndex;
	} else {
		makeTabSwitchable -Control $containerPanel -Enable $false;
	}

	# Dock this panel to the top of the parent, apply padding and make it expand to content height
	makeResponsive -Control $containerPanel -Dock 1 -Padding $Padding -AutoSize $true;


	############# Control #############

	# Instansiate the provided control type
	$responsiveControl = New-Object $Type;

	# Disable TAB switching to this control by default
	makeTabSwitchable -Control $responsiveControl -Enable $false;

	# Dock it to the top of the parent or panel
	makeResponsive -Control $responsiveControl -Dock 1;

	############# Finalise #############

	# Add the control to the panel, and the panel to the parent
	$containerPanel.Controls.Add( $responsiveControl );
	$Parent.Controls.Add( $containerPanel );

	# Return the control
	return $responsiveControl;

}

# Creates a tab page and a tab control for adding sub-tabs to
function makeTabPageAndControl {
	param( [ System.Windows.Forms.Control ] $Parent, [ string ] $Title );

	############# Page #############

	# Instansiate and title a new tab page
	[ System.Windows.Forms.TabPage ] $tabPage = New-Object System.Windows.Forms.TabPage;
	$tabPage.Text = $Title;

	# Disable TAB switching to this control
	makeTabSwitchable -Control $tabPage -Enable $false;

	############# Control #############

	# Instansiate a new tab control for sub-tabs, and dock it inside the above tab page
	[ System.Windows.Forms.TabControl ] $tabControl = New-Object System.Windows.Forms.TabControl;
	$tabControl.Dock = 5; # DockStyle.Fill

	# Disable TAB switching to this control
	makeTabSwitchable -Control $tabControl -Enable $false;

	############# Finalise #############

	# Add the tab control to the tab page, and the tab page to the parent
	$tabPage.Controls.Add( $tabControl );
	$Parent.Controls.Add( $tabPage );

	# Return the tab control
	return $tabControl;

}

# Creates a textbox with a dynamic placeholder
function makeTextBoxWithPlaceholder {
	param( [ System.Windows.Forms.Control ] $Parent, [ int[] ] $Padding, [ string ] $Placeholder, [ bool ] $HideInput = $false, [ int ] $PanelTabIndex = -1 );

	# Instansiate a new textbox using the provided padding and placeholder text
	[ System.Windows.Forms.TextBox ] $textBox = makeResponsiveControl -Parent $Parent -Type System.Windows.Forms.TextBox -Padding $Padding -PanelTabIndex $PanelTabIndex;
	$textBox.Text = $Placeholder;

	# Center the input text in the middle of the textbox
	$textBox.TextAlign = 2; # HorizontalAlignment.Center

	# Add an event handler that runs when the user clicks on the textbox...
	# NOTE: Closure needed to expose function parameters into this at runtime
	$textBox.Add_GotFocus( {

		# If the text is the default then clear it
		if ( $this.Text -eq $Placeholder ) {
			$this.Text = "";

			# Mask the input if applicable
			if ( $HideInput ) {
				$this.PasswordChar = "•";
			}
		}

	}.GetNewClosure() );

	# Add an event handler that runs when the user clicks off the textbox...
	# NOTE: Closure needed to expose function parameters into this at runtime
	$textBox.Add_LostFocus( {

		# If the text is empty then set it back to the default
		if ( $this.Text -eq "" ) {
			$this.Text = $Placeholder

			# Remove input mask if applicable
			if ( $HideInput ) {
				$this.PasswordChar = $null;
			}
		}

	}.GetNewClosure() );

	# Return the textbox
	return $textBox;

}

# Adds either all users or all groups from the configured organisational unit to a combobox
function populateComboBoxWithActiveDirectoryObjects {
	param( [ System.Windows.Forms.ComboBox ] $ComboBox, [ string ] $Object ); # Object can be "User" or "Group"

	# If this is for users...
	if ( $Object -eq "User" ) {

		# Loop through each user in the configured organisational unit/active directory path, and add their full name & legacy account name to the combobox
		# NOTE: For some reason this outputs to the console the index of each item as they are added?
		foreach ( $foundUser in ( Get-ADUser -Filter * -SearchBase $activeDirectoryPath | Select-Object -Property Name, SamAccountName ) ) {
			$ComboBox.Items.Add( $foundUser.Name + " (" + $foundUser.SamAccountName + ")" );
		}

	# If this is for groups...
	} elseif ( $Object -eq "Group" ) {

		# Loop through each group in the configured organisational unit/active directory path, and add its name to the combobox
		# NOTE: For some reason this outputs to the console the index of each item as they are added?
		foreach ( $foundGroup in ( Get-ADGroup -Filter * -SearchBase $activeDirectoryPath | Select-Object -Property Name ) ) {
			$ComboBox.Items.Add( $foundGroup.Name );
		}

	}

}

##########################################
# Window Functions
##########################################

# Creates & shows the main management window with all its controls
function createManagementWindow() {

	############# Form #############
	
	# Instansiate the base form to put everything on
	[ System.Windows.Forms.Form ] $manageForm = New-Object System.Windows.Forms.Form

	# Set the title and hide the icon
	$manageForm.Text = "Server Manager (for " + $organisationalUnit + ", on " + $domainNames.Forest + " aka. " + $domainNames.NetBIOSName + ")";
	$manageForm.ShowIcon = 0;

	# Disable resizing from the corners & the maximise button
	$manageForm.MaximizeBox = 0;
	$manageForm.AutoSize = $false;
	$manageForm.FormBorderStyle = 3; # FormBorderStyle.FixedSingle

	# Set the size and location to the middle of the screen
	$manageForm.Width = 550;
	$manageForm.Height = 400;
	$manageForm.StartPosition = 1; # FormStartPosition.CenterScreen


	############# Tab Container #############
	
	# Instansiate a new container for the tabs and dock inside the parent form
	[ System.Windows.Forms.TabControl ] $mainTabControl = New-Object System.Windows.Forms.TabControl;
	$mainTabControl.Dock = 5; # DockStyle.Fill


	############# Status Tab #############

	[ System.Windows.Forms.TabControl ] $statusTabControl = makeTabPageAndControl -Parent $mainTabControl -Title "Current Statuses";


		############# Server Status Tab #############

		# Instansiate and title a new tab page for the status of this server
		[ System.Windows.Forms.TabPage ] $serverStatusTab = New-Object System.Windows.Forms.TabPage;
		$serverStatusTab.Text = "This Server";


			############# Status Textbox #############

			# Instansiate a new textbox with padding around it for the raw server status output
			[ System.Windows.Forms.RichTextBox ] $serverStatusTextBox = makeResponsiveControl -Parent $serverStatusTab -Type System.Windows.Forms.RichTextBox -Padding @( 2, 10, 10, 10 );

			# Set the font to a monospaced one so it renders whitespace correctly
			$serverStatusTextBox.Font = New-Object System.Drawing.Font( "Consolas", 9 );

			# Manually set the height so it fills up the remaining bottom of the tab page
			$serverStatusTextBox.Height = 240;

			# Set the text to a placeholder and disable user interaction
			$serverStatusTextBox.Text = "The raw information of the connection test will be displayed here.";
			$serverStatusTextBox.ReadOnly = $true;

			# Make the background color white (needed because making it read-only changes the background color)
			$serverStatusTextBox.BackColor = "white";


			############# Status Label #############

			# Instansiate a new label with padding around it for the easy server status and align content to the middle
			[ System.Windows.Forms.Label ] $serverStatusLabel = makeResponsiveControl -Parent $serverStatusTab -Type System.Windows.Forms.Label -Padding @( 0, 0, 10, 10 );
			$serverStatusLabel.Text = "Server Status: Not Checked";
			$serverStatusLabel.TextAlign = 2;


			############# Refresh Button #############

			# Instansiate a new button with padding around it for refreshing the server status
			[ System.Windows.Forms.Button ] $refreshServerStatusButton = makeResponsiveControl -Parent $serverStatusTab -Type System.Windows.Forms.Button -Padding @( 10, 10, 10, 10 );
			$refreshServerStatusButton.Text = "Refresh Server Status";

			# Add an event handler that runs whenever the button is clicked...
			$refreshServerStatusButton.Add_Click( {

				# Store the current hour, minute and second
				[ string ] $lastCheck = ( Get-Date -Format "HH:mm:ss" );

				# Check if the server is online (works the same as ping but returns PowerShell-friendly data)
				$connectionTest = Test-Connection -Count 1 $serverIP -ErrorAction SilentlyContinue;

				# If the server is online...
				if ( $connectionTest ) {

					# Set the label to reflect this
					$serverStatusLabel.Text = "Server Status: Online";

					# Set the textbox to a filtered list of specific useful properties returned by the connection tes
					$serverStatusTextBox.Text = ( $connectionTest | Select-Object -Property @{N='Source Name';E={$_.PSComputerName}}, @{N='Source IPv4 Address';E={$_.IPv4Address}}, @{N='Source IPv6 Address';E={$_.IPv6Address}}, @{N='Target IP Address';E={$_.Address}}, @{N='Packet Size (Bytes)';E={$_.ReplySize}}, @{N='Latency (Milliseconds)';E={$_.ResponseTime}}, @{N='Time-To-Live (Milliseconds)';E={$_.TimeToLive}} | Out-String ).Trim();
				
				# Otherwise, if the server is offline
				} else {

					# Set the label and textbox to reflect this
					$serverStatusLabel.Text = "Server Status: Offline";
					$serverStatusTextBox.Text = "Server is offline, no raw information to display.";

				}

				# Append the stored time to the end of the label
				$serverStatusLabel.Text += " (as of " + $lastCheck + ")";

			} );

		# Add this tab page to the tab control
		$statusTabControl.Controls.Add( $serverStatusTab );


		############# Service Status Tab #############

		# Instansiate and title a new tab page for the status of required services
		[ System.Windows.Forms.TabPage ] $serviceStatusTab = New-Object System.Windows.Forms.TabPage;
		$serviceStatusTab.Text = "Core Services";

			
			############# Status Textbox #############

			# Instansiate a new textbox with padding around it for the raw service statuses output
			[ System.Windows.Forms.RichTextBox ] $serviceStatusTextBox = makeResponsiveControl -Parent $serviceStatusTab -Type System.Windows.Forms.RichTextBox -Padding @( 2, 10, 10, 10 );
			
			# Set the font to a monospaced one so it renders whitespace correctly
			$serviceStatusTextBox.Font = New-Object System.Drawing.Font( "Consolas", 9 );

			# Manually set the height so it fills up the remaining bottom of the page
			$serviceStatusTextBox.Height = 240;

			# Set the text to a placeholder and disable user interaction
			$serviceStatusTextBox.Text = "The raw information of the service statuses will be displayed here.";
			$serviceStatusTextBox.ReadOnly = $true;

			# Make the background color white (needed because making it read-only changes the background color)
			$serviceStatusTextBox.BackColor = "white";


			############# Status Label #############

			# Instansiate a new label with padding around it for the easy service statuses and align content to the middle
			[ System.Windows.Forms.Label ] $serviceStatusLabel = makeResponsiveControl -Parent $serviceStatusTab -Type System.Windows.Forms.Label -Padding @( 0, 0, 10, 10 );
			$serviceStatusLabel.Text = "DHCP: Not Checked | DNS: Not Checked | Active Directory: Not Checked";
			$serviceStatusLabel.TextAlign = 2;
			

			############# Refresh Button #############

			# Instansiate a new button with padding around it for refreshing the service statuses
			[ System.Windows.Forms.Button ] $refreshServiceStatusButton = makeResponsiveControl -Parent $serviceStatusTab -Type System.Windows.Forms.Button -Padding @( 10, 10, 10, 10 );
			$refreshServiceStatusButton.Text = "Refresh Service Statuses";

			# Add an event handler that runs whenever the button is clicked...
			$refreshServiceStatusButton.Add_Click( {

				# Store the current hour, minute and second
				[ string ] $lastCheck = ( Get-Date -Format "HH:mm:ss" );

				# Get the statuses of each core service
				$dhcpStatus = Get-Service -Name "DHCP Server";
				$dnsStatus = Get-Service -Name "DNS Server";
				$activeDirectoryStatus = Get-Service -Name "Active Directory Domain Services";

				# Update the label with pipe symbol seperating them
				$serviceStatusLabel.Text = "DHCP: " + $dhcpStatus.Status;
				$serviceStatusLabel.Text += " | DNS: " + $dnsStatus.Status;
				$serviceStatusLabel.Text += " | Active Directory: " + $activeDirectoryStatus.Status;
				$serviceStatusLabel.Text += " (as of " + $lastCheck + ")";

				# Update the raw information textbox with new lines seperating them
				$serviceStatusTextBox.Text = ( $dhcpStatus | Select-Object @{N='Service Name';E={$_.Name}}, @{N='Display Name';E={$_.DisplayName}}, @{N='Current Status';E={$_.Status}} | Format-List | Out-String ).Trim() + "`n`n";
				$serviceStatusTextBox.Text += ( $dnsStatus | Select-Object @{N='Service Name';E={$_.Name}}, @{N='Display Name';E={$_.DisplayName}}, @{N='Current Status';E={$_.Status}} | Format-List | Out-String ).Trim() + "`n`n";
				$serviceStatusTextBox.Text += ( $activeDirectoryStatus | Select-Object @{N='Service Name';E={$_.Name}}, @{N='Display Name';E={$_.DisplayName}}, @{N='Current Status';E={$_.Status}} | Format-List | Out-String ).Trim();

			} );


		# Add this tab page to the tab control
		$statusTabControl.TabPages.Add( $serviceStatusTab );


	############# User Management Tab #############
	[ System.Windows.Forms.TabControl ] $userManagementTabControl = makeTabPageAndControl -Parent $mainTabControl -Title "Active Directory User Management";

		############# Create User Tab #############

		# Instansiate a new tab page for creating new users
		[ System.Windows.Forms.TabPage ] $createUserTab = New-Object System.Windows.Forms.TabPage;
		$createUserTab.Text = "Create New User";

		# Add this tab page to the tab container
		$userManagementTabControl.TabPages.Add( $createUserTab );


			############# Create Button #############

			# Instansiate a new button with padding around it for creating the user
			[ System.Windows.Forms.Button ] $createUserButton = makeResponsiveControl -Parent $createUserTab -Type System.Windows.Forms.Button -Padding @( 8, 10, 9, 9 );
			$createUserButton.Text = "Create a new user using the information above...";

			# Add an event handler that runs whenever the button is clicked...
			$createUserButton.Add_Click( {
				
				# Store the inputs for easy access
				[ string ] $firstName = $firstNameTextBox.Text;
				[ string ] $lastName = $lastNameTextBox.Text;
				[ string ] $accountName = $accountNameTextBox.Text;
				[ string ] $password = $passwordTextBox.Text;
				[ string ] $passwordConfirm = $passwordConfirmTextBox.Text;
				[ bool ] $changePasswordNextLogin = $changePasswordNextLoginCheckBox.Checked;
				[ bool ] $canChangePassword = $canChangePasswordCheckBox.Checked;
				[ bool ] $passwordNeverExpires = $passwordNeverExpiresCheckBox.Checked;
				[ bool ] $accountEnabled = $accountEnabledCheckBox.Checked;

				# Show an error prompt and stop processing if no first name was entered
				if ( $firstName -eq "Enter the user's first name (e.g. John)..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must enter a first name for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if no last name was entered
				if ( $lastName -eq "Enter the user's last name (e.g. Doe)..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must enter a last name for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if no account name was entered
				if ( $accountName -eq "Enter the user's account name (e.g. JohnD)..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must enter an account name for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if no password was entered
				if ( $password -eq "Enter the user's password (e.g. P4ssw0rd!)..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must enter a password for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if confirmed password was entered
				if ( $passwordConfirm -eq "Enter the user's password again..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must confirm the password for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if the password and confirmed password do not match
				if ( -not ( $password -eq $passwordConfirm ) ) {
					[ System.Windows.Forms.MessageBox ]::Show( "The entered passwords do not match.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if both change password at next logon and user cannot change password are enabled
				if ( $changePasswordNextLogin -and ( -not $canChangePassword ) ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You cannot have the user changing their password on next login, and the user not being able to change their password.", "Error", "OK", "Error" );
					return;
				}

				# Create the extra values required for creating the user
				[ string ] $fullName = $firstName + " " + $lastName;
				[ string ] $initials = $firstName.Substring( 0, 1 ) + " " + $lastName.Substring( 0, 1 );
				[ string ] $principalName = $accountName.ToLower() + "@" + $domainNames.Forest;

				# Prompt for the admin to confirm creation of this account, stop processing if they do not agree to it
				[ string ] $confirmResult = [ System.Windows.Forms.MessageBox ]::Show( "Are you sure you wish to create a new user with these details?`n`nFirst Name: " + $firstName + "`nLast Name: " + $lastName + "`nFull Name: " + $fullName + "`nInitials: " + $initials + "`nLegacy Login: " + $domainNames.NetBIOSName + "\" + $accountName + "`nPrincipal Login: " + $principalName, "Confirm", "YesNo", "Question" );
				if ( -not ( $confirmResult -eq "Yes" ) ) {
					return;
				}

				# Create the new account with the above details in the configured active directory path
				# NOTE: Inside a try-catch loop because all sorts of errors could occur
				try {
					New-ADUser `
						-Path $activeDirectoryPath `
						-Name $fullName `
						-DisplayName $fullName `
						-GivenName $firstName `
						-Surname $lastName `
						-Initials $initials `
						-SamAccountName $accountName `
						-UserPrincipalName $principalName `
						-ChangePasswordAtLogon $changePasswordNextLogin `
						-CannotChangePassword ( -not $canChangePassword ) `
						-PasswordNeverExpires $passwordNeverExpires `
						-Enabled $accountEnabled `
						-AccountPassword ( ConvertTo-SecureString -AsPlainText $password -Force );
					
					# Show a message box to tell the admin all was successful
					[ System.Windows.Forms.MessageBox ]::Show( "The account has been created.", "Success", "OK", "Information" );

					# Reset all the inputs
					$firstNameTextBox.Text = "Enter the user's first name (e.g. John)...";
					$lastNameTextBox.Text = "Enter the user's last name (e.g. Doe)...";
					$accountNameTextBox.Text = "Enter the user's account name (e.g. JohnD)...";

					$passwordTextBox.Text = "Enter the user's password (e.g. P4ssw0rd!)...";
					$passwordTextBox.PasswordChar = $null;
					$passwordConfirmTextBox.Text = "Enter the user's password again...";
					$passwordConfirmTextBox.PasswordChar = $null;

					$changePasswordNextLoginCheckBox.Checked = $false;
					$canChangePasswordCheckBox.Checked = $true;
					$passwordNeverExpiresCheckBox.Checked = $true;
					$accountEnabledCheckBox.Checked = $true;

				# Show a message box containing the error that occured if anything goes wrong
				} catch {
					[ System.Windows.Forms.MessageBox ]::Show( "An error was encountered while creating the new user.`n`n" + $Error[ 0 ], "Error", "OK", "Error" );
				}

			} );


			############# Account Enabled Checkbox #############

			# Instansiate a new checkbox for if the users account should be enabled, and make it checked by default
			[ System.Windows.Forms.CheckBox ] $accountEnabledCheckBox = makeResponsiveControl -Parent $createUserTab -Type System.Windows.Forms.CheckBox -Padding @( 0, 0, 170, 50 );
			$accountEnabledCheckBox.Text = "Enable the account after creation?";
			$accountEnabledCheckBox.Checked = $true;


			############# Password Checkboxes #############

			# Instansiate a new checkbox for if the user's password should not expire, and make it checked by default
			[ System.Windows.Forms.CheckBox ] $passwordNeverExpiresCheckBox = makeResponsiveControl -Parent $createUserTab -Type System.Windows.Forms.CheckBox -Padding @( 0, 0, 155, 50 );
			$passwordNeverExpiresCheckBox.Text = "Set the user's password to never expire?";
			$passwordNeverExpiresCheckBox.Checked = $true;

			# Instansiate a new checkbox for if the user should be able to change their password, and make it checked by default
			[ System.Windows.Forms.CheckBox ] $canChangePasswordCheckBox = makeResponsiveControl -Parent $createUserTab -Type System.Windows.Forms.CheckBox -Padding @( 0, 0, 130, 50 );
			$canChangePasswordCheckBox.Text = "Should the user be able to change their password?";
			$canChangePasswordCheckBox.Checked = $true;

			# Instansiate a new checkbox for if the user's should change their password when next logging in
			[ System.Windows.Forms.CheckBox ] $changePasswordNextLoginCheckBox = makeResponsiveControl -Parent $createUserTab -Type System.Windows.Forms.CheckBox -Padding @( 2, 0, 100, 50 );
			$changePasswordNextLoginCheckBox.Text = "Require the user to change their password when they next login?";


			############# Password Textboxes #############

			# Instansiate a new textbox for the user's password
			[ System.Windows.Forms.TextBox ] $passwordConfirmTextBox = makeTextBoxWithPlaceholder -Parent $createUserTab -Padding @( 2, 8, 10, 10 ) -Placeholder "Enter the user's password again..." -HideInput $true;
			[ System.Windows.Forms.TextBox ] $passwordTextBox = makeTextBoxWithPlaceholder -Parent $createUserTab -Padding @( 8, 2, 10, 10 ) -Placeholder "Enter the user's password (e.g. P4ssw0rd!)..." -HideInput $true;


			############# Account Name Textbox #############

			# Instansiate a new textbox for the users legacy account name
			[ System.Windows.Forms.TextBox ] $accountNameTextBox = makeTextBoxWithPlaceholder -Parent $createUserTab -Padding @( 8, 8, 10, 10 ) -Placeholder "Enter the user's account name (e.g. JohnD)...";


			############# Name Textboxes #############

			# Instansiate a new textbox for the user's real name
			[ System.Windows.Forms.TextBox ] $lastNameTextBox = makeTextBoxWithPlaceholder -Parent $createUserTab -Padding @( 2, 8, 10, 10 ) -Placeholder "Enter the user's last name (e.g. Doe)...";
			[ System.Windows.Forms.TextBox ] $firstNameTextBox = makeTextBoxWithPlaceholder -Parent $createUserTab -Padding @( 5, 2, 10, 10 ) -Placeholder "Enter the user's first name (e.g. John)...";


			############# Instruction Label #############

			# Instansiate a new centered label with padding for displaying instructions
			[ System.Windows.Forms.Label ] $createUserInstructionLabel = makeResponsiveControl -Parent $createUserTab -Type System.Windows.Forms.Label -Padding @( 5, 0, 0, 0 );
			$createUserInstructionLabel.Text = "This is where you can create new Active Directory users in the configured Organisational Unit.";
			$createUserInstructionLabel.TextAlign = 32; # ContentAlignment.MiddleCenter


		############# Edit Password Tab #############

		# Instansiate and title a new tab page for editing a user's password
		[ System.Windows.Forms.TabPage ] $editPasswordTab = New-Object System.Windows.Forms.TabPage;
		$editPasswordTab.Text = "Edit User Password";

		# Add this tab page to the tab container
		$userManagementTabControl.TabPages.Add( $editPasswordTab );


			############# Policy Textbox #############

			# Instansiate a new textbox with padding around it for the raw password policy
			[ System.Windows.Forms.RichTextBox ] $editPasswordPolicyTextBox = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.RichTextBox -Padding @( 0, 10, 10, 10 );
			
			# Set the font to a monospaced one so it renders whitespace correctly
			$editPasswordPolicyTextBox.Font = New-Object System.Drawing.Font( "Consolas", 9 );

			# Manually set the height so it fills up the remaining bottom of the page
			$editPasswordPolicyTextBox.Height = 93;

			# Set the text to the raw password policy information and disable user interaction
			$editPasswordPolicyTextBox.Text = ( Get-ADDefaultDomainPasswordPolicy -Identity $domainName | Select-Object @{N='Needs Complexity';E={$_.ComplexityEnabled}}, @{N='Lockout Duration';E={$_.LockoutDuration}}, @{N='Minimum Age';E={$_.MinPasswordAge}}, @{N='Maximum Age';E={$_.MaxPasswordAge}}, @{N='Minimum Length';E={$_.MinPasswordLength}}, @{N='History Count';E={$_.PasswordHistoryCount}} | Out-String ).Trim();
			$editPasswordPolicyTextBox.ReadOnly = $true;

			# Make the background color white (needed because making it read-only changes the background color)
			$editPasswordPolicyTextBox.BackColor = "white";


			############# Policy Label #############

			# Instansiate a new centered label with padding for displaying instructions
			[ System.Windows.Forms.Label ] $editPasswordPolicyLabel = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.Label -Padding @( 10, 0, 0, 0 );
			$editPasswordPolicyLabel.Text = "This is the information about the password policy for the configured domain.";
			$editPasswordPolicyLabel.TextAlign = 32; # ContentAlignment.MiddleCenter


			############# Refresh Button #############

			# Instansiate a new button with padding around it for refreshing the list of users
			[ System.Windows.Forms.Button ] $editPasswordRefreshButton = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.Button -Padding @( 1, 0, 9, 9 );
			$editPasswordRefreshButton.Text = "Refresh the list of users...";

			# Add an event handler that runs whenever the button is clicked...
			$editPasswordRefreshButton.Add_Click( {

				# Clear the user selection combobox
				$selectUserComboBox.Items.Clear();

				# Repopulate this combobox with the users in the configured organisational unit
				populateComboBoxWithActiveDirectoryObjects -ComboBox $selectUserComboBox -Object "User";

				# Show a message box for user feedback
				[ System.Windows.Forms.MessageBox ]::Show( "The list of users has been refreshed.", "Success", "OK", "Information" );

			} )


			############# Change Button #############

			# Instansiate a new button with padding around it for changing the users password
			[ System.Windows.Forms.Button ] $editPasswordButton = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.Button -Padding @( 5, 1, 9, 9 );
			$editPasswordButton.Text = "Change the selected users password using the credentials above...";

			# Add an event handler that runs whenever the button is clicked...
			$editPasswordButton.Add_Click( {

				# Store the inputs for easy access
				[ int ] $selectedUser = $selectUserComboBox.SelectedIndex;
				[ string ] $password = $editPasswordTextBox.Text;
				[ string ] $passwordConfirm = $editPasswordConfirmTextBox.Text;
				[ bool ] $changePasswordNextLogin = $editPasswordNextLoginCheckBox.Checked;

				# Show an error prompt and stop processing if no user was selected (i.e. value is -1)
				if ( $selectedUser -lt 0 ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must select a user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if no password was entered
				if ( $password -eq "Enter the user's new password (e.g. P4ssw0rd!)..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must enter a new password for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if confirmed password was entered
				if ( $passwordConfirm -eq "Enter the user's new password again..." ) {
					[ System.Windows.Forms.MessageBox ]::Show( "You must confirm the new password for the user.", "Error", "OK", "Error" );
					return;
				}

				# Show an error prompt and stop processing if the password and confirmed password do not match
				if ( -not ( $password -eq $passwordConfirm ) ) {
					[ System.Windows.Forms.MessageBox ]::Show( "The entered passwords do not match.", "Error", "OK", "Error" );
					return;
				}

				# Store the text that is selected in the combobox
				[ string ] $selectedUserValue = $selectUserComboBox.SelectedItem;

				# Work out the identity path to this user within the configured Organisational Unit
				[ int ] $accountNameStarts = $selectedUserValue.IndexOf( "(" );
				[ string ] $identityPath = "CN=" + $selectedUserValue.Substring( 0, $accountNameStarts - 1 ) + "," + $activeDirectoryPath;

				# Edit the selected user's password and account attributes with the above details in the set active directory path
				# NOTE: Inside a try-catch loop because all sorts of errors could occur
				try {
					Set-ADAccountPassword -Identity $identityPath -Reset -NewPassword ( ConvertTo-SecureString -AsPlainText $password -Force );
					Set-ADUser -Identity $identityPath -ChangePasswordAtLogon $changePasswordNextLogin;

					# Show a message box to tell the admin all was successful
					[ System.Windows.Forms.MessageBox ]::Show( "The user's password has been changed.", "Success", "OK", "Information" );

					# Reset all the inputs
					$selectUserComboBox.SelectedIndex = -1;

					$editPasswordTextBox.Text = "Enter the user's new password (e.g. P4ssw0rd!)...";
					$editPasswordTextBox.PasswordChar = $null;
					$editPasswordConfirmTextBox.Text = "Enter the user's new password again...";
					$editPasswordConfirmTextBox.PasswordChar = $null;

					$editPasswordNextLoginCheckBox.Checked = $false;

				# Show a message box containing the error that occured if anything goes wrong
				} catch {
					[ System.Windows.Forms.MessageBox ]::Show( "An error was encountered while editing the selected user's password.`n`n" + $Error[ 0 ], "Error", "OK", "Error" );
				}

			} )


			############# Password Checkboxes #############

			# Instansiate a new checkbox for if the user's should change their password when next logging in
			[ System.Windows.Forms.CheckBox ] $editPasswordNextLoginCheckBox = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.CheckBox -Padding @( 0, 0, 100, 50 );
			$editPasswordNextLoginCheckBox.Text = "Require the user to change their password when they next login?";


			############# Password Textboxes #############

			# Instansiate a new textbox for the new user's password
			[ System.Windows.Forms.TextBox ] $editPasswordConfirmTextBox = makeTextBoxWithPlaceholder -Parent $editPasswordTab -Padding @( 2, 8, 10, 10 ) -Placeholder "Enter the user's new password again..." -HideInput $true;
			[ System.Windows.Forms.TextBox ] $editPasswordTextBox = makeTextBoxWithPlaceholder -Parent $editPasswordTab -Padding @( 2, 2, 10, 10 ) -Placeholder "Enter the user's new password (e.g. P4ssw0rd!)..." -HideInput $true;


			############# User Selection #############

			# Instansiate a new combobox for listing the users
			[ System.Windows.Forms.ComboBox ] $selectUserComboBox = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.ComboBox -Padding @( 5, 2, 10, 10 );
			$selectUserComboBox.DropDownStyle = 2; # ComboBoxStyle.DropDownList
			
			# Initially populate this combobox with the users in the configured organisational unit
			populateComboBoxWithActiveDirectoryObjects -ComboBox $selectUserComboBox -Object "User";


			############# Instruction Label #############

			# Instansiate a new centered label with padding for displaying instructions
			[ System.Windows.Forms.Label ] $editPasswordInstructionLabel = makeResponsiveControl -Parent $editPasswordTab -Type System.Windows.Forms.Label -Padding @( 5, 0, 0, 0 );
			$editPasswordInstructionLabel.Text = "This is where you can change passwords for existing users within the configured Organisational Unit.";
			$editPasswordInstructionLabel.TextAlign = 32; # ContentAlignment.MiddleCenter


		############# Edit User Groups Tab #############

		# Instansiate and title a new tab page for adding and removing users to and from a group
		[ System.Windows.Forms.TabPage ] $editGroupsTab = New-Object System.Windows.Forms.TabPage;
		$editGroupsTab.Text = "Edit User Groups";

		# Add this tab page to the tab container
		$userManagementTabControl.TabPages.Add( $editGroupsTab );


			############# Note Label #############

			# Instansiate a new centered label with padding for displaying a note
			[ System.Windows.Forms.Label ] $editGroupsNoteLabel = makeResponsiveControl -Parent $editGroupsTab -Type System.Windows.Forms.Label -Padding @( 5, 0, 50, 50 );
			$editGroupsNoteLabel.Text = "The default Domain Users group automatically added to newly created users is hidden as it's not within the scope of the configured Organisational Unit.";
			$editGroupsNoteLabel.TextAlign = 32; # ContentAlignment.MiddleCenter


			############# Remove User From Group Box #############

			# Instansiate a new group box for containing the remove user from group controls
			# NOTE: Manual internal padding is specified to prevent child controls from clipping outside the bounds of the drawn box
			[ System.Windows.Forms.GroupBox ] $removeUserGroupBox = makeResponsiveControl -Parent $editGroupsTab -Type System.Windows.Forms.GroupBox -Padding @( 10, 5, 8, 8 );
			$removeUserGroupBox.Text = "Remove existing users from existing groups within the configured Organisational Unit";
			$removeUserGroupBox.Padding = New-Object System.Windows.Forms.Padding( 10, 8, 10, 0 ); # Left, Top, Right, Bottom
			$removeUserGroupBox.Height = 112;


				############# Remove Button #############

				# Instansiate a new button with padding around it for removing a user from a group
				[ System.Windows.Forms.Button ] $removeGroupButton = makeResponsiveControl -Parent $removeUserGroupBox -Type System.Windows.Forms.Button -Padding @( 10, 0, 0, 0 );
				$removeGroupButton.Text = "Remove the selected user from the selected group...";

				# Add an event handler that runs whenever the button is clicked...
				$removeGroupButton.Add_Click( {

					# Show an error prompt and stop processing if no user was selected
					if ( $removeGroupUserComboBox.SelectedIndex -lt 0 ) {
						[ System.Windows.Forms.MessageBox ]::Show( "You must select a user.", "Error", "OK", "Error" );
						return;
					}

					# Show an error prompt and stop processing if no group was selected
					if ( $removeGroupGroupComboBox.SelectedIndex -lt 0 ) {
						[ System.Windows.Forms.MessageBox ]::Show( "You must select a group.", "Error", "OK", "Error" );
						return;
					}

					# Store the text that is selected in the comboboxes
					[ string ] $selectedUser = $removeGroupUserComboBox.SelectedItem;
					[ string ] $selectedGroup = $removeGroupGroupComboBox.SelectedItem;

					# Work out the identity paths to the selected user and group within the configured Organisational Unit
					[ int ] $accountNameStarts = $selectedUser.IndexOf( "(" );
					[ string ] $fullUserName = $selectedUser.Substring( 0, $accountNameStarts - 1 );
					[ string ] $userIdentityPath = "CN=" + $fullUserName + "," + $activeDirectoryPath;
					[ string ] $groupIdentityPath = "CN=" + $selectedGroup + "," + $activeDirectoryPath;
					
					# Remove the selected user from the selected group using the above paths
					# NOTE: Inside a try-catch loop because all sorts of errors could occur
					try {
						Remove-ADGroupMember -Identity $groupIdentityPath -Members $userIdentityPath -Confirm: $false; # Last part disables the confirmation prompt

						# Show a message box to tell the admin all was successful
						[ System.Windows.Forms.MessageBox ]::Show( "The selected user has been removed from the selected group.", "Success", "OK", "Information" );

						# Reset the input (group selection box is reset by selection changed event handler later on)
						$removeGroupUserComboBox.SelectedIndex = -1;

					# Show a message box containing the error that occured if anything goes wrong
					} catch {
						[ System.Windows.Forms.MessageBox ]::Show( "An error was encountered while removing the selected user from the selected group.`n`n" + $Error[ 0 ], "Error", "OK", "Error" );
					}

				} )


				############# Group Selection #############

				# Instansiate a new combobox for listing the groups the selected user is a member of
				[ System.Windows.Forms.ComboBox ] $removeGroupGroupComboBox = makeResponsiveControl -Parent $removeUserGroupBox -Type System.Windows.Forms.ComboBox -Padding @( 2, 0, 1, 1 );
				$removeGroupGroupComboBox.DropDownStyle = 2; # ComboBoxStyle.DropDownList
				$removeGroupGroupComboBox.Enabled = $false;


				############# User Selection #############

				# Instansiate a new combobox for listing the users in this organisational unit
				[ System.Windows.Forms.ComboBox ] $removeGroupUserComboBox = makeResponsiveControl -Parent $removeUserGroupBox -Type System.Windows.Forms.ComboBox -Padding @( 0, 2, 1, 1 );
				$removeGroupUserComboBox.DropDownStyle = 2; # ComboBoxStyle.DropDownList

				# Initially populate this combobox with the users in the configured organisational unit
				populateComboBoxWithActiveDirectoryObjects -ComboBox $removeGroupUserComboBox -Object "User";

				# Add an event handler that runs whenever the selected item changes...
				$removeGroupUserComboBox.Add_SelectedValueChanged( {

					# Clear the group selection combobox
					$removeGroupGroupComboBox.Items.Clear();

					# If an item is actually selected...
					if ( $removeGroupUserComboBox.SelectedIndex -ge 0 ) {

						# Work out the identity path for this user within the configured organisational unit
						[ string ] $selectedUser = $removeGroupUserComboBox.SelectedItem;
						[ int ] $accountNameStarts = $selectedUser.IndexOf( "(" );
						[ string ] $identityPath = "CN=" + $selectedUser.Substring( 0, $accountNameStarts - 1 ) + "," + $activeDirectoryPath;

						# Enable the group selection combobox
						$removeGroupGroupComboBox.Enabled = $true;

						# Loop through all groups the selected user is a member of (excluding the default domain users) and add their names to the group selection combobox
						foreach ( $userGroupName in ( Get-ADPrincipalGroupMembership -Identity $identityPath | Select -ExpandProperty Name | Where-Object { $_ -ne "Domain Users" } ) ) {
							$removeGroupGroupComboBox.Items.Add( $userGroupName );
						}

					# Otherwise, if this was just a reset...
					} else {

						# Disable the group selection combobox
						$removeGroupGroupComboBox.Enabled = $false;
						
					}

				} );


			############# Add User To Group Box #############

			# Instansiate a new group box for containing the add user to group controls
			# NOTE: Manual internal padding is specified to prevent child controls from clipping outside the bounds of the drawn box
			[ System.Windows.Forms.GroupBox ] $addUserGroupBox = makeResponsiveControl -Parent $editGroupsTab -Type System.Windows.Forms.GroupBox -Padding @( 0, 0, 8, 8 );
			$addUserGroupBox.Text = "Add existing users to existing groups within the configured Organisational Unit";
			$addUserGroupBox.Padding = New-Object System.Windows.Forms.Padding( 10, 8, 10, 0 ); # Left, Top, Right, Bottom
			$addUserGroupBox.Height = 112;


				############# Add Button #############

				# Instansiate a new button with padding around it for adding a user to a group
				[ System.Windows.Forms.Button ] $addGroupButton = makeResponsiveControl -Parent $addUserGroupBox -Type System.Windows.Forms.Button -Padding @( 10, 0, 0, 0 );
				$addGroupButton.Text = "Add the selected user to the selected group...";

				# Add an event handler that runs whenever the button is clicked...
				$addGroupButton.Add_Click( {

					# Store the inputs for easy access
					[ int ] $selectedUser = $addGroupUserComboBox.SelectedIndex;
					[ int ] $selectedGroup = $addGroupGroupComboBox.SelectedIndex;

					# Show an error prompt and stop processing if no user was selected
					if ( $selectedUser -lt 0 ) {
						[ System.Windows.Forms.MessageBox ]::Show( "You must select a user.", "Error", "OK", "Error" );
						return;
					}

					# Show an error prompt and stop processing if no group was selected
					if ( $selectedGroup -lt 0 ) {
						[ System.Windows.Forms.MessageBox ]::Show( "You must select a group.", "Error", "OK", "Error" );
						return;
					}

					# Store the text that is selected in the comboboxes
					$selectedUserValue = $addGroupUserComboBox.GetItemText( $addGroupUserComboBox.SelectedItem );
					$selectedGroupValue = $addGroupGroupComboBox.GetItemText( $addGroupGroupComboBox.SelectedItem );

					# Work out the identity paths to the selected user and group within the configured Organisational Unit
					[ int ] $accountNameStarts = $selectedUserValue.IndexOf( "(" );
					[ string ] $fullUserName = $selectedUserValue.Substring( 0, $accountNameStarts - 1 );
					[ string ] $userIdentityPath = "CN=" + $fullUserName + "," + $activeDirectoryPath;
					[ string ] $groupIdentityPath = "CN=" + $selectedGroupValue + "," + $activeDirectoryPath;

					# Show an error message box and stop processing if the user is already in this group
					$usersInSelectedGroup = Get-ADGroupMember -Identity $groupIdentityPath -Recursive | Select -ExpandProperty Name;
					if ( $usersInSelectedGroup -contains $fullUserName ) {
						[ System.Windows.Forms.MessageBox ]::Show( "The selected user is already a member of the selected group.", "Error", "OK", "Error" );
						return;
					}

					# Add the selected user to the selected group using the above paths
					# NOTE: Inside a try-catch loop because all sorts of errors could occur
					try {
						Add-ADGroupMember -Identity $groupIdentityPath -Members $userIdentityPath -Confirm: $false; # Last part disables the confirmation prompt

						# Show a message box to tell the admin all was successful
						[ System.Windows.Forms.MessageBox ]::Show( "The selected user has been added to the selected group.", "Success", "OK", "Information" );

						# Reset all the inputs
						$addGroupUserComboBox.SelectedIndex = -1;
						$addGroupGroupComboBox.SelectedIndex = -1;

					# Show a message box containing the error that occured if anything goes wrong
					} catch {
						[ System.Windows.Forms.MessageBox ]::Show( "An error was encountered while adding the selected user to the selected group.`n`n" + $Error[ 0 ], "Error", "OK", "Error" );
					}

				} )


				############# Group Selection #############

				# Instansiate a new combobox for listing the groups in this organisational unit
				[ System.Windows.Forms.ComboBox ] $addGroupGroupComboBox = makeResponsiveControl -Parent $addUserGroupBox -Type System.Windows.Forms.ComboBox -Padding @( 2, 0, 1, 1 );
				$addGroupGroupComboBox.DropDownStyle = 2; # ComboBoxStyle.DropDownList

				# Initially populate this combobox with the groups in the configured organisational unit
				populateComboBoxWithActiveDirectoryObjects -ComboBox $addGroupGroupComboBox -Object "Group";


				############# User Selection #############

				# Instansiate a new combobox for listing the users in this organisational unit
				[ System.Windows.Forms.ComboBox ] $addGroupUserComboBox = makeResponsiveControl -Parent $addUserGroupBox -Type System.Windows.Forms.ComboBox -Padding @( 0, 2, 1, 1 );
				$addGroupUserComboBox.DropDownStyle = 2; # ComboBoxStyle.DropDownList

				# Initially populate this combobox with the users in the configured organisational unit
				populateComboBoxWithActiveDirectoryObjects -ComboBox $addGroupUserComboBox -Object "User";


			############# Refresh Button #############

			# Instansiate a new button with padding around it for refreshing the list of users and groups
			[ System.Windows.Forms.Button ] $editGroupsRefreshButton = makeResponsiveControl -Parent $editGroupsTab -Type System.Windows.Forms.Button -Padding @( 8, 10, 9, 9 );
			$editGroupsRefreshButton.Text = "Refresh the list of users and groups...";

			# Add an event handler that runs whenever the button is clicked...
			$editGroupsRefreshButton.Add_Click( {

				# Clear the comboboxes
				$addGroupUserComboBox.Items.Clear();
				$addGroupGroupComboBox.Items.Clear();
				$removeGroupUserComboBox.Items.Clear();
				$removeGroupGroupComboBox.Items.Clear();

				# Repopulate the comboboxes with the users in the configured organisational unit
				populateComboBoxWithActiveDirectoryObjects -ComboBox $addGroupUserComboBox -Object "User";
				populateComboBoxWithActiveDirectoryObjects -ComboBox $removeGroupUserComboBox -Object "User";

				# Repopulate the comboboxes with the groups in the configured organisational unit
				populateComboBoxWithActiveDirectoryObjects -ComboBox $addGroupGroupComboBox -Object "Group";
				
				# Disable the last group selection combobox
				$removeGroupGroupComboBox.Enabled = $false;

				# Show a message box for user feedback
				[ System.Windows.Forms.MessageBox ]::Show( "The list of users and groups has been refreshed.", "Success", "OK", "Information" );

			} )


		############# Import Users Tab #############

		# Instansiate and title a new tab page for adding users to a group
		[ System.Windows.Forms.TabPage ] $importUsersTab = New-Object System.Windows.Forms.TabPage;
		$importUsersTab.Text = "Bulk Import & Export Users";

		# Add this tab page to the tab container
		$userManagementTabControl.TabPages.Add( $importUsersTab );


			############# Guide Label #############

			# Instansiate a new centered label with padding for displaying the guide
			[ System.Windows.Forms.Label ] $importExportGuideLabel = makeResponsiveControl -Parent $importUsersTab -Type System.Windows.Forms.Label -Padding @( 5, 10, 30, 30 );
			$importExportGuideLabel.Text = "The file should be stored as comma-seperated values (.csv) with the first row containing the following headings: firstName, lastName, accountName, password, changePasswordNextLogin, and accountEnabled.`n`nThe first two specify the full name of the user, the third is the logon name, the fourth is the initial user password, and finally the fifth and sixth are booleans (true or false) for specifying if the user should be required to change their password when they next login, and if the account should be enabled once imported.";
			$importExportGuideLabel.TextAlign = 32; # ContentAlignment.MiddleCenter
			$importExportGuideLabel.Height = 110; # Manual height required to show all text

			############# Import Button #############

			# Instansiate a new button with padding around it for importing users
			[ System.Windows.Forms.Button ] $importUsersButton = makeResponsiveControl -Parent $importUsersTab -Type System.Windows.Forms.Button -Padding @( 0, 0, 9, 9 );
			$importUsersButton.Text = "Bulk import users into the configured Organisational Unit from a .csv file...";

			# Add an event handler that runs whenever the button is clicked...
			$importUsersButton.Add_Click( {

				# Instansiate a new file dialog for selecting a file to import...
				[ System.Windows.Forms.FileDialog ] $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog;

				# Set the title of the dialog
				$openFileDialog.Title = "Select a comma-seperated values file containing users to import into the configured Organisational Unit";

				# Start in the current working directory, but remember the previous directory the user opened
				$openFileDialog.InitialDirectory = ( Get-Location ).Path;
				$openFileDialog.RestoreDirectory = $true;

				# Only allow .csv files, or all files (good practice as file extension does not always dictate content)
				$openFileDialog.Filter = "Comma-seperated value files (*.csv)|*.csv|All files (*.*)|*.*";

				# Disable selecting multiple files
				$openFileDialog.Multiselect = $false;
				
				# Always ensure what the user selects is valid
				$openFileDialog.CheckFileExists = $true;
				$openFileDialog.CheckPathExists = $true;
				
				# Open the dialog and store the result in a string
				[ string ] $dialogResult = $openFileDialog.ShowDialog();

				# If the user selected anything other than open (i.e. cancel, etc.) then do not continue
				if ( $dialogResult -ne "OK" ) {
					return;
				}

				# Store the path to the file the user selected
				[ string ] $fileToImport = $openFileDialog.FileName;

				# Parse the csv file content into an array of object inside a try-catch loop to handle malformed files
				try {

					# Define a variable for holding the iteration number of the loop below
					[ int ] $loopCounter = 0;

					# Attempt to import then loop through each of the rows in the .csv file
					# NOTE: Manually specifying delimiter, headings and character encoding to catch incorrectly formatted files
					Import-CSV -Path $fileToImport -Delimiter ',' -Header @( "firstName", "lastName", "accountName", "password", "changePasswordNextLogin", "accountEnabled" ) -Encoding "utf8" | Foreach-Object {
						
						# If this is the first iteration then validate the header names...
						if ( $loopCounter -eq 0 ) {
							if ( $_.firstName -ne "firstName" ) { throw "Incorrect first name header in file." };
							if ( $_.lastName -ne "lastName" ) { throw "Incorrect last name header in file." };
							if ( $_.accountName -ne "accountName" ) { throw "Incorrect account name header in file." };
							if ( $_.password -ne "password" ) { throw "Incorrect password header in file." };
							if ( $_.changePasswordNextLogin -ne "changePasswordNextLogin" ) { throw "Incorrect change password at next login header in file." };
							if ( $_.accountEnabled -ne "accountEnabled" ) { throw "Incorrect account enabled header in file." };
						
						# Otherwise process the actual rows...
						} else {

							# Convert the boolean values in the row to actual booleans
							$changePasswordNextLogin = if ( $_.changePasswordNextLogin -eq "true" ) { $true } else { $false };
							$accountEnabled = if ( $_.accountEnabled -eq "true" ) { $true } else { $false };

							# Create the extra values required for creating the user
							[ string ] $fullName = $_.firstName + " " + $_.lastName;
							[ string ] $initials = $_.firstName.Substring( 0, 1 ) + " " + $_.lastName.Substring( 0, 1 );
							[ string ] $principalName = $_.accountName.ToLower() + "@" + $domainNames.Forest;

							# Create the new accounts with the imported details
							New-ADUser `
								-Path $activeDirectoryPath `
								-Name $fullName `
								-DisplayName $fullName `
								-GivenName $_.firstName `
								-Surname $_.lastName `
								-Initials $initials `
								-SamAccountName $_.accountName `
								-UserPrincipalName $principalName `
								-ChangePasswordAtLogon $changePasswordNextLogin `
								-Enabled $accountEnabled `
								-AccountPassword ( ConvertTo-SecureString -AsPlainText $_.password -Force );

						}

						# Increment the counter
						$loopCounter++;

					}

					# Show a message box to tell the admin all was successful
					[ System.Windows.Forms.MessageBox ]::Show( "Successfully imported " + ( $loopCounter - 1 ) + " accounts.", "Success", "OK", "Information" ); # -1 for the headings row

				} catch {
					# Show a messagebox if the import failed
					[ System.Windows.Forms.MessageBox ]::Show( "An error was encountered while importing users from the .csv file.`n`n" + $Error[ 0 ], "Error", "OK", "Error" );
				}

			} );


			############# Instruction Label #############

			# Instansiate a new centered label with padding for displaying the instructions
			[ System.Windows.Forms.Label ] $importInstructionLabel = makeResponsiveControl -Parent $importUsersTab -Type System.Windows.Forms.Label -Padding @( 10, 10, 30, 30 );
			$importInstructionLabel.Text = "This is where you can bulk import multiple users to the configured Organisational Unit with ease by browsing to a file using the button below.";
			$importInstructionLabel.TextAlign = 32; # ContentAlignment.MiddleCenter


	############# Finalise #############

	# Add the main tab container to the form
	$manageForm.Controls.Add( $mainTabControl );
	
	# Show the management form
	$manageForm.ShowDialog();

}

# Creates & shows the login window with all its controls
function createLoginWindow() {

	############# Form #############

	# Instansiate the base form to put everything on
	[ System.Windows.Forms.Form ] $loginForm = New-Object System.Windows.Forms.Form;

	# Set the title and hide the icon
	$loginForm.Text = "Server Manager";
	$loginForm.ShowIcon = $false;
	
	# Hide the minimise and maximise buttons to act like a prompt
	$loginForm.MinimizeBox = $false;
	$loginForm.MaximizeBox = $false;

	# Disable resizing from the corners
	$loginForm.AutoSize = $false;
	$loginForm.FormBorderStyle = 3; # FormBorderStyle.FixedSingle

	# Set the size and open in the middle of the screen
	$loginForm.Width = 400;
	$loginForm.Height = 155;
	$loginForm.StartPosition = 1; # FormStartPosition.CenterScreen

	# Add an event handler that runs when the base form finishes loading...
	$loginForm.Add_Load( {

		# Set the currently selected control to the label
		# NOTE: This is done so the username textbox is not cleared on startup
		$loginForm.ActiveControl = $instructionLabel;

	} );


	############# Login Button #############

	# Instansiate a new button for attempting login
	[ System.Windows.Forms.Button ] $loginFormButton = makeResponsiveControl -Parent $loginForm -Type System.Windows.Forms.Button -Padding @( 0, 10, 39, 39 ) -PanelTabIndex 5;

	# Set the text and center it
	$loginFormButton.Text = "Login...";
	$loginFormButton.TextAlign = 2; # HorizontalAlignment.Center

	# Enable TAB switching to it
	makeTabSwitchable -Control $loginFormButton -Enable $true -Index 6;

	# Add an event handler that runs when the button is clicked...
	$loginFormButton.Add_Click( {

		# Store the inputs for easy access
		[ string ] $username = $usernameTextbox.Text;
		[ string ] $password = $passwordTextbox.Text;

		# Show an error prompt and stop processing if no username was entered
		if ( $username -eq "Enter your username..." ) {
			[ System.Windows.Forms.MessageBox ]::Show( "You must enter a username.", "Error", "OK", "Error" );
			return;
		}

		# Show an error prompt and stop processing if no password was entered
		if ( $password -eq "Enter your password..." ) {
			[ System.Windows.Forms.MessageBox ]::Show( "You must enter a password.", "Error", "OK", "Error" );
			return;
		}

		# Call the credentials check utility function with the entered username and password
		[ bool ] $areCredentialsCorrect = checkActiveDirectoryCredentials -Username $username -Password $password;

		# Show an error message box and stop processing if the credentials are incorrect
		if ( $areCredentialsCorrect -ne $true ) {
			[ System.Windows.Forms.MessageBox ]::Show( "That user does not exist, or your password is incorrect.", "Error", "OK", "Error" );
			return;
		}

		# Hide the login window and open the main management window
		$loginForm.Hide();
		createManagementWindow;

	} );


	############# Password Textbox #############

	# Instansiate a new textbox for inputting the password, and enable TAB switching to it
	[ System.Windows.Forms.TextBox ] $passwordTextbox = makeTextBoxWithPlaceholder -Parent $loginForm -Padding @( 3, 10, 40, 40 ) -Placeholder "Enter your password..." -HideInput $true -PanelTabIndex 3;
	makeTabSwitchable -Control $passwordTextbox -Enable $true -Index 4;


	############# Username Textbox #############

	# Instansiate a new textbox for inputting the username, and enable TAB switching to it
	[ System.Windows.Forms.TextBox ] $usernameTextbox = makeTextBoxWithPlaceholder -Parent $loginForm -Padding @( 6, 3, 40, 40 ) -Placeholder "Enter your username..." -PanelTabIndex 1;
	makeTabSwitchable -Control $usernameTextbox -Enable $true -Index 2;


	############# Instruction Label #############

	# Instansiate a new centered label with padding for displaying instructions to login
	[ System.Windows.Forms.Label ] $instructionLabel = makeResponsiveControl -Parent $loginForm -Type System.Windows.Forms.Label -Padding @( 5, 0, 0, 0 );
	$instructionLabel.Text = "Please authenticate with your Active Directory credentials to continue.";
	$instructionLabel.TextAlign = 32; # ContentAlignment.MiddleCenter


	############# Finalising #############

	# Show the form with all the added controls
	$loginForm.ShowDialog();

}

# Get if this program is running as an administrator
[ bool ] $isAdmin = isRunningAsAdmin;

# If the program is not running as an administrator then show an error and stop processing
if ( $isAdmin -eq $false ) {
	[ System.Windows.Forms.MessageBox ]::Show( "Only users within the Administrators group can use this program.", "Error", "OK", "Error" );
	return;
}

# Start the script by creating the login form
createLoginWindow;
