Working with people in the community I have found way to get the Windows app store back as well as all of the other items that we removed in early builds.

 

This mechanism was implemented by Microsoft to prevent deprovisioned applications from coming back when a Feature Update was performed. https://docs.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update

 

Put the application you removed and don’t want coming back in this registry location:

HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\

 

Starting with 1803, deprovisioning an application populates this registry key automatically.  What Microsoft does not have documented is that the Feature Update still has all the components and mechanisms in place to put Windows Apps back. It’s only this key list that is used to block them from coming back!

 

On the left is one of our older builds, 1901, that is missing the app store.  On the right is a newly imaged machine.  Deleting all of the excess keys from the problem machine then updating to Windows 10 1909 on it resulted in all of the previously removed applications coming back, including the app store. The app store and other applications are now present and functioning on the test machine.
This is the list we removed that’s in excess and will be corrected with 1909 Feature Update:
Microsoft.BingWeather_8wekyb3d8bbwe

Microsoft.DesktopAppInstaller_8wekyb3d8bbwe

Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe

Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe

Microsoft.MSPaint_8wekyb3d8bbwe

Microsoft.Print3D_8wekyb3d8bbwe

Microsoft.StorePurchaseApp_8wekyb3d8bbwe

Microsoft.Wallet_8wekyb3d8bbwe

Microsoft.WebMediaExtensions_8wekyb3d8bbwe

Microsoft.WindowsAlarms_8wekyb3d8bbwe

Microsoft.WindowsCamera_8wekyb3d8bbwe

Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe

Microsoft.WindowsMaps_8wekyb3d8bbwe

Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe

Microsoft.WindowsStore_8wekyb3d8bbwe

Microsoft.Xbox.TCUI_8wekyb3d8bbwe

Microsoft.XboxGameOverlay_8wekyb3d8bbwe

Microsoft.XboxGamingOverlay_8wekyb3d8bbwe

Microsoft.XboxIdentityProvider_8wekyb3d8bbwe

Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe