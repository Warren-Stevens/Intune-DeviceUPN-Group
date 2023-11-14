### Using Powerhell to create an Assigned Group of Intune Managed Windows device with a UPN filter ###
 
# Check if AzureAD module is installed - run PS with admin privileges!!!! 

if (Get-Module -Name AzureAD -ListAvailable) {
    # Uninstall AzureAD module
    Uninstall-Module -Name AzureAD -AllVersions -Force
}
 
# Install and Import Azure AD Preview
Install-Module -Name AzureADPreview -AllowClobber -Confirm -force
Import-Module Azureadpreview
 
# Connect to Azure AD
Connect-AzureAD
 
# Import Graph Module and Connect to MS Graph
Install-Module -Name Microsoft.Graph.Intune
Import-Module Microsoft.Graph.Intune
Connect-MSGraph
 
# Set the Group name ---- NB Change Group Name to your requirements!!!!!
$groupName = "Test-Group"

# List Intune managed devices with a UPN filter, Retrieve device object IDs and add to variable ---- NB set email UPN to your requirements!!!!!

$deviceObjectIds = Get-IntuneManagedDevice -filter "emailAddress eq '@test.com' and operatingSystem eq 'Windows'" | Select-Object -ExpandProperty azureADDeviceId 

# Check if the group exists
$existingGroup = Get-AzureADGroup -SearchString $groupName

# If the group doesn't exist, create it and get its ID
if (!$existingGroup) {
    $group = New-AzureADMSGroup -DisplayName $groupName -MailEnabled $false -MailNickName $false -SecurityEnabled $true
    $groupId = $group.Id
    Write-Host "Group created successfully: $($group.DisplayName)"
}
else {
    $groupId = $existingGroup.ObjectId
    Write-Host "Group already exists: $($existingGroup.DisplayName)"
}

# Print a blank line for visual spacing
Write-Host ""

# Print the heading
Write-Host "List of Intune Managed devices adding to group:"

$deviceObjectIds | ForEach-Object {
    $AzureADdeviceId = $_
    $device = Get-AzureAdDevice -Filter "deviceId eq guid'$($AzureADdeviceId)'"
    $deviceName = $device.DisplayName
    
    try {
        Add-AzureADGroupMember -ObjectId $groupId -RefObjectId $device.ObjectId -ErrorAction Stop
        Write-Host "Device added successfully: $deviceName"
    }
    catch {
        if ($_.Exception.Message -match "One or more added object references already exist for the following modified properties: 'members'") {
            Write-Host "Device is already a member of the group: $deviceName"
        } else {
            Write-Host "Error occurred: $($_.Exception.Message)"
        }
    }
}
