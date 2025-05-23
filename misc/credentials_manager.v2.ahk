#Requires AutoHotkey v2.0+


/*****************************************************************************************
*  ╔──────────────────────────────────────────────────╗
*  ║              CREDENTIALS_MANAGER                 ║
*  ╚──────────────────────────────────────────────────╝
* @description
* Manages system credentials using Windows Credential Manager API (Advapi32.dll)
* 
* Original code by geek - https://www.autohotkey.com/boards/viewtopic.php?f=83&t=116285
* 
* Provides methods to read, write, delete, and retrieve credentials securely.
* Handles automatic credential creation through user input if not found.
* Credentials are stored using Windows' built-in encryption.
* 
* @methods
* @static write(name, user_name:='', password:='')
*   Writes credentials to Windows Credential Manager
*   @param {String} name - Target name for the credential
*   @param {String} user_name - Username (defaults to 'null')
*   @param {String} password - Password (defaults to 'null')
*   @returns {Integer} Success status from CredWriteW
* 
* @static delete(name)
*   Deletes credentials from Windows Credential Manager
*   @param {String} name - Target name of credential to delete
*   @returns {Integer} Success status from CredDeleteW
* 
* @static read(name)
*   Reads credentials from Windows Credential Manager
*   @param {String} name - Target name of credential to read
*   @returns {Object} Credential info containing name, user_name, and password
*                     Returns undefined if credential not found
* 
* @static get(name)
*   Retrieves credentials, prompting for new ones if not found
*   @param {String} name - Target name of credential to get
*   @returns {Object} Credential info containing name, user_name, and password
*                     Exits app if credentials cannot be saved or found
* 
* @example
* ; Write new credentials
* credentials_manager.write("MyApp", "john_doe", "secretpass123")
* 
* ; Read existing credentials
* cred := credentials_manager.read("MyApp")
* if (cred)
*     MsgBox(cred.user_name)
* 
* ; Get credentials (will prompt if not found)
* cred := credentials_manager.get("MyApp")
* 
* ; Delete credentials
* credentials_manager.delete("MyApp")
*
******************************************************************************************/
class CREDENTIALS_MANAGER {

	static get(name)	=> (cred := this.read(name), cred ? cred : this._get_new_credentials(name))

	static delete(name) => DllCall('Advapi32.dll\CredDeleteW', 'WStr', name, 'UInt', 1, 'UInt', 0, 'UInt')

	static read(name) {
		p_cred 		:= 0
		DllCall('Advapi32.dll\CredReadW',
			'Str',  name,   	; [in]  LPCWSTR      TargetName
			'UInt', 1,      	; [in]  DWORD        Type = CRED_TYPE_GENERIC (https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala)
			'UInt', 0,      	; [in]  DWORD        Flags
			'Ptr*', &p_cred, 	; [out] PCREDENTIALW *Credential
			'UInt' 			; BOOL
		)
		if !p_cred
			return
		name 		:= StrGet(NumGet(p_cred, 8 + A_PtrSize * 0, 'UPtr'), 256, 'UTF-16')
		username 	:= StrGet(NumGet(p_cred, 24 + A_PtrSize * 6, 'UPtr'), 256, 'UTF-16')
		len 		:= NumGet(p_cred, 16 + A_PtrSize * 2, 'UInt')
		password 	:= StrGet(NumGet(p_cred, 16 + A_PtrSize * 3, 'UPtr'), len/2, 'UTF-16')
		DllCall('Advapi32.dll\CredFree', 'Ptr', p_cred)
		return {name: name, username: username, password: password}
	}
	
    	static write(name, username:='', password:='') {
		cred 		:= Buffer(24 + A_PtrSize * 7, 0)
		username	:= username ? username : 'null'
		password	:= password ? password : 'null'
		cbPassword 	:= StrLen(password) * 2
		NumPut('UInt', 1               , cred,  4+A_PtrSize*0) ; Type = CRED_TYPE_GENERIC
		NumPut('Ptr',  StrPtr(name)    , cred,  8+A_PtrSize*0) ; TargetName
		NumPut('UInt', cbPassword      , cred, 16+A_PtrSize*2) ; CredentialBlobSize
		NumPut('Ptr',  StrPtr(password), cred, 16+A_PtrSize*3) ; CredentialBlob
		NumPut('UInt', 3               , cred, 16+A_PtrSize*4) ; Persist = CRED_PERSIST_ENTERPRISE (roam across domain)
		NumPut('Ptr',  StrPtr(username), cred, 24+A_PtrSize*6) ; UserName
		return DllCall('Advapi32.dll\CredWriteW', 'Ptr', cred, 'UInt', 0, 'UInt')
			? this.read(name)
			: false
	}

    	static _get_new_credentials(name) {
        	input_name 	:= name ? name : InputBox('Enter the carrier/site name:', 'Credentials').Value
        	username 	:= InputBox('Enter the username:', 'Credentials').Value
        	password 	:= InputBox('Enter the password:', 'Credentials').Value
        
        	this.write(input_name, username, password) 
			? (cred := this.read(input_name)) 
			: (MsgBox('Failed to save credentials.`n`nThe script will now exit.'), ExitApp)
        
        	return cred ? cred : (MsgBox('Credentials were not found.`n`nThe script will now exit.'), ExitApp)
    	}

}
