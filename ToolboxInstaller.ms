try(destroyDialog TetraToolBoxInstaller)catch()
rollout TetraToolBoxInstaller "Toolbox Installer" width:216 height:40
(
	button 'btnInstallTetraToolBox' "Install Tetra ToolBox" pos:[0,0] width:216 height:40 align:#left
	local File = dotNetClass "System.IO.File"
	local Directory = dotNetClass "System.IO.Directory"
	local FilePath = dotNetClass "System.IO.Path"
	local scriptRoot = getFilenamePath (getThisScriptFilename())
	local tetraToolDir = PathConfig.appendPath scriptRoot "files"
	local userMacroDir = getDir #userMacros
	local userScriptDir = @"C:\tetraToolBox"
  
	fn GetFileList folder ext = 
	(
		files = getFiles (PathConfig.appendPath folder ext)
		return files
	)
	fn CreateDirectory = 
	(
		if (Directory.Exists (PathConfig.AppendPath userScriptDir "scripts")) != true do
		(
			Directory.CreateDirectory (PathConfig.AppendPath userScriptDir @"max\scripts")
			format "Created Directories : %\n" (PathConfig.AppendPath userScriptDir @"max\scripts")
		)			
	)
	fn CopyFiles sourceList destPath =
	(
		for files in sourceList do
		(
			File.Copy files (PathConfig.AppendPath destPath (getFileNameFile files + getFileNameType files)) true
			format "Files Copied : %\n" (PathConfig.AppendPath destPath (getFileNameFile files + getFileNameType files))
		)
	)
	
	on btnInstallTetraToolBox pressed do
	(
		actionMan.executeAction 0 "40472"
		clearListener()				
		CreateDirectory()		
		format "Copying All Necessary files\n"
		format "------------------------------------------------\n"
		try
		(
			--Copy UserMacros to localuser/usermacros
			macroFileList = (GetFileList  (PathConfig.appendPath tetraToolDir @"max\usermacros") "*.mcr")
			CopyFiles macroFileList userMacroDir		
		
			--Copy main tools to tetra\main\download\3dsMax\
			mainFileList = (GetFileList tetraToolDir "*.*")
			CopyFiles mainFileList userScriptDir		
			
			--Copy scripts to tetra\main\download\3dsMax\
			scriptFileList = (GetFileList  (PathConfig.AppendPath tetraToolDir @"max\scripts") "*.ms")
			CopyFiles scriptFileList (PathConfig.AppendPath userScriptDir @"max\scripts")	
			
			MessageBox "TetraToolBox Installation Complete......Restart 3ds Max" title:"Tetra ToolBox"
		)
		catch
		(
			MessageBox "Please Restart 3dsMax and run the Installer again"
		)
		destroyDialog TetraToolBoxInstaller
		--quitMAX quiet:false exitCode:0				
	)
)
createDialog TetraToolBoxInstaller
