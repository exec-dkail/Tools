try(_tetraQAMaxForm.Close())catch()
_tetraQAMaxForm = dotNetObject "MaxCustomControls.MaxForm"
(	
	-- local Variables
	local _tetraQAMaxFormWH = [900,400]
	local _dnBackColor = (dotNetClass "System.Drawing.Color").FromArgb 64 64 64
	local _dnForeColor = (dotNetClass "System.Drawing.Color").FromArgb 220 220 220
	local _dataForeColor = (dotNetClass "System.Drawing.Color").FromArgb 10 10 10
	local _dataOkColor = (dotNetClass "System.Drawing.Color").FromArgb 0 150 0
	local _dataErrorColor = (dotNetClass "System.Drawing.Color").FromArgb 180 0 0
	local _dataWarningColor = (dotNetClass "System.Drawing.Color").FromArgb 200 200 0
	local _paramList = #("Helpers","Ballistic","LOD Distance","Collision Type","Collision Logic Material","Accessory Parts","Materials")
	local _errordata = #()

	local CollisionBox = #("HEADLIGHT_LEFT","HEADLIGHT_RIGHT","FOGLIGHT_LEFT","FOGLIGHT_RIGHT","HOOD","ENGINE","BACKWINDOW","TRUNK","TAILLIGHT_MIDDLE","QUARTER_WINDOW_FRONT_LEFT","QUARTER_WINDOW_FRONT_RIGHT","QUARTER_WINDOW_BACK_LEFT","QUARTER_WINDOW_BACK_RIGHT") 	
	local CollisionCylinder = #("STATE01_WHEEL_BACK_LEFT","STATE01_WHEEL_BACK_RIGHT","STATE01_WHEEL_FRONT_LEFT","STATE01_WHEEL_FRONT_RIGHT","STATE02_WHEEL_BACK_LEFT","STATE02_WHEEL_BACK_RIGHT","STATE02_WHEEL_FRONT_LEFT","STATE02_WHEEL_FRONT_RIGHT","RIM_BACK_LEFT","RIM_BACK_RIGHT","RIM_FRONT_LEFT","RIM_FRONT_RIGHT")
	local LogicMaterial_GlassP = #("BACKWINDOW","FOGLIGHT_LEFT","FOGLIGHT_RIGHT","HEADLIGHT_LEFT","HEADLIGHT_RIGHT","QUARTER_WINDOW_LEFT","QUARTER_WINDOW_RIGHT","STATE01_WINDSHIELD","STATE02_WINDSHIELD","STATE03_WINDSHIELD","TAILLIGHT_LEFT","TAILLIGHT_MIDDLE","TAILLIGHT_RIGHT")
	local LogicMaterial_RubberVehicle  = #("STATE01_WHEEL_BACK_LEFT","STATE01_WHEEL_BACK_RIGHT","STATE01_WHEEL_FRONT_LEFT","STATE01_WHEEL_FRONT_RIGHT")
	local excludedBallistics = #("RPMMETER","SPEEDOMETER","STEERINGWHEEL")
	local excludedCollisionType = #("WINDSHIELD","STEERINGWHEEL","WHEEL_FRONT_LEFT","WHEEL_FRONT_RIGHT","WHEEL_BACK_LEFT","WHEEL_BACK_RIGHT","TIRE_FRONT_LEFT","TIRE_FRONT_RIGHT","TIRE_BACK_LEFT", "TIRE_BACK_RIGHT","RPMMETER","SPEEDOMETER","WIPER_LEFT","WIPER_RIGHT","WIPER_BACK","TIRE_FRONT_LEFT", "TIRE_FRONT_RIGHT", "TIRE_BACK_LEFT", "TIRE_BACK_RIGHT")
	
	local LODDistance = "#(8,16,32,64,150,200,400)"
	local _xPadding = 2 
	local curColumn = 0
	local colCreated = false

	-- form controls	
	local _tetraQACheckList = dotNetObject "System.Windows.Forms.ListView"
	local _tetraQADataList = dotNetObject "System.Windows.Forms.DataGridView"
	local _tetraQACarName = dotNetObject "System.Windows.Forms.Label"
	local _tetraQACarLocation = dotNetObject "System.Windows.Forms.Label"
	local _tetraQAShowErrors = dotNetObject "System.Windows.Forms.Checkbox"
	local _tetraQAValidateScene = dotNetObject "System.Windows.Forms.Button"	

	struct DataStruct
	(
		fn CheckHelperCase obj = 
		(				
			if obj.name == toUpper obj.name then
			(
				return true
			)
			else 
			(
				return false
			)
		),
		fn CheckComplexCollision obj = 
		(
			childrenArr = obj.children
			indexArr = #()
			if childrenArr.count > 0 do
			(
				for child in childrenArr where superClassOf child == GeometryClass do
				(
					if (findString child.name "LOD") != undefined do
					(
						lods = (filterString child.name "_")[(filterString child.name "_").Count]
						index = (substituteString lods "LOD" "") as integer
						AppendIfUnique indexArr index
					)
				)
			)	
			return (amax indexArr)
		),
		fn CheckCollisionType obj =
		(
			collisionType = #()
			childrenArr = obj.children
			if childrenArr.Count > 0 then
			(
				for child in childrenArr where superClassOf child == GeometryClass do
				(
					if (findString child.Name "COL") != undefined do
					(
						cType = FcxBasicShapeTypeLabels[child.shape_type+1]
						AppendIfUnique collisionType #(child.name,cType)
					)
				)
			)
			return collisionType
		),
		fn CheckCollisionLogicMaterial obj = 
		(
			collisionMaterial = #()
			childrenArr = obj.children
			if childrenArr.Count > 0 do
			(
				for child in childrenArr where superClassOf child == GeometryClass do
				(
					if (findString child.Name "COL") != undefined do
					(
						logicMaterial = (filterString (FindLogicMaterialByID child.sound_id).lmName "/")[2]
						if logicMaterial != undefined and logicMaterial != "" do
						(
							AppendIfUnique collisionMaterial #(child.name,logicMaterial)
						)
					)
				)
			)
			return collisionMaterial
		),
		fn CheckCollisionMaterial obj =
		(
			hasMaterial = #()
			childrenArr = obj.children
			if childrenArr.Count > 0 do
			(
				for child in childrenArr where superClassOf child == GeometryClass do
				(
					if (findString child.Name "COL") != undefined do
					(
						if child.material != undefined then
						(
							Append hasMaterial true
						)
						else
						(
							Append hasMaterial false
						)
					)
				)
			)
			return hasMaterial
		),
		fn CheckLODDistance obj = 
		(
			lodDistance = #()
			for indx = 1 to 7 do
			(
				lodIndx = formattedprint indx format:"02d"
				AppendIfUnique lodDistance ((execute ("obj.Lod" + lodIndx)) as integer)
			)
			return lodDistance
		),
		fn GetRowData = 
		(
			rowArray = #()
			for i = 0 to _tetraQADataList.Rows.Count-1 do
			(
				AppendIfUnique rowArray _tetraQADataList.Rows.Item[i]
			)				
			return rowArray
		),
		fn InsertData oNode Cell ColName =
		(
			ds = DataStruct
			obj = getNodeByName oNode
			case colName of 
			(
				"Ballistic" :
				(
					if (findItem excludedBallistics obj.name) == 0 then
					(					
						colMesh = obj.ccol_mesh
						getMaxLOD = ds.CheckComplexCollision obj
						if getMaxLOD != undefined then
						(
							if getMaxLOD == (colMesh-1) then
							(
								Cell.Value = "L" + (colMesh-1) as string
							)
							else if getMaxLOD > 4 and colMesh == 5 then
							(
								Cell.Value = "L" + (colMesh-1) as string
							)		
							else 
							(
								Cell.Value = "L" + (colMesh-1) as string
							)
						)
						else
						(
							Cell.Value = ""
						)
					)
					else
					(
						Cell.Value = ""
					)					
				)
				"LOD Distance" :
				(
					if obj.name == (getFileNameFile maxfilename) then
					(
						try
						(
							Cell.Value = (ds.CheckLODDistance obj) as string
						)
						catch
						(
							Cell.Value = "Please Refresh Data"
						)
					)
					else
					(
						Cell.Value = " "
					)					
				)
				"Collision Type" :
				(
					if (findItem excludedCollisionType obj.name) == 0 and obj.name != (getFileNameFile maxfilename) then
					(
						colType = ds.CheckCollisionType obj
						if colType.Count > 0 then
						(		
							str = ""
							for i = 1 to colType.count do
							(
								if i < colType.count then
								(
									str += colType[i][1] + " : " + colType[i][2] + "\n"
								)
								else
								(
									str += colType[i][1] + " : " + colType[i][2]
								)
							)							
							Cell.Value = str
						)
						else
						(
							Cell.Value = ""
						)
					)
				)
				"Collision Logic Material" :
				(
					colMaterial = ds.CheckCollisionLogicMaterial obj
					if colMaterial.Count > 0 then
					(		
						str = ""
						for i = 1 to colMaterial.count do
						(
							if i < colMaterial.count then
							(
								str += colMaterial[i][1] + " : " + colMaterial[i][2] + "\n"
							)
							else
							(
								str += colMaterial[i][1] + " : " + colMaterial[i][2]
							)
						)							
						Cell.Value = str
					)
					else
					(
						Cell.Value = ""
					)
				)
				"Materials" :
				(
					colMaterial = ds.CheckCollisionMaterial obj
					if (findItem colMaterial true) != 0 then
					(
						Cell.Value = "Has Material"
					)
					else
					(
						Cell.Value = "No Material"
					)
				)
				"Accessory Parts" :
				(
					if obj.export_tag == "ACCESSORY" then
					(
						Cell.Value = "Is Accessory"
					)
					else Cell.Value = " "
					
				)
				
			)
		),
		fn ValidateData = 
		(
			ds = DataStruct
			rowData = ds.GetRowData()
			for row in rowData do
			(
				for i = 0 to row.Cells.Count-1 do
				(
					obj = getNodeByName (row.Cells.Item[0].Value)
					vCell = row.Cells.Item[i]
					columnName = vCell.OwningColumn.Name
					case columnName of
					(
						"Helpers":
						(							
							if (ds.CheckHelperCase obj) == false and obj.name != (getFileNameFile maxFileName) then
							(
								vCell.Style.BackColor = _dataErrorColor
								AppendIfUnique _errordata row
							)							
						)						
						"Ballistic" :
						(
							try
							(
								if (findItem excludedBallistics obj.name) == 0 do
								(								
									colMesh = obj.ccol_mesh
									getMaxLOD = ds.CheckComplexCollision obj
									if getMaxLOD != undefined then
									(
										if getMaxLOD == (colMesh-1) then
										(
											vCell.Style.BackColor = _dataOkColor
										)
										else if getMaxLOD > 4 and colMesh == 5 then
										(
											vCell.Style.BackColor = _dataOkColor
										)
										else
										(
											vCell.Style.BackColor = _dataErrorColor
											AppendIfUnique _errordata row
										)
									)								
								)
							)
							catch(format "@Ballistics Exception on Object : % | %\n" obj.name (getCurrentException()))								
						)						
						"Collision Type" :
						(
							try
							(
								if vCell.Value == "No Collision Object" then
								(
									vCell.Style.BackColor = _dataWarningColor
									vCell.Style.ForeColor = _dataForeColor
								)
								else
								(
									colType = ds.CheckCollisionType obj
									for i in colType do
									(
										colObj = getNodeByName i[1]
										if colObj.export_tag == "SCOL" then
										(
											if (findItem CollisionBox obj.name) != 0 then
											(											
												if (FcxBasicShapeTypeLabels[colObj.shape_type+1]) == "Box" then
												(
													vCell.Style.BackColor = _dataOkColor
												)
												else
												(
													vCell.Style.BackColor = _dataWarningColor
													vCell.Style.ForeColor = _dataForeColor
												)
											)
											else if (findItem CollisionCylinder obj.name) != 0 then
											(											
												if (FcxBasicShapeTypeLabels[colObj.shape_type+1]) == "Cylinder" then
												(
													vCell.Style.BackColor = _dataOkColor
												)
												else
												(
													vCell.Style.BackColor = _dataWarningColor
													vCell.Style.ForeColor = _dataForeColor
												)
											)
											else 
											(
												vCell.Style.BackColor = _dataOkColor											
											)
										)
										else
										(
											AppendIfUnique _errordata row 
											vCell.Style.BackColor = _dataErrorColor
										)
									)												
								)
							)
							catch(format "@CollisionType Exception: %\n" (getCurrentException()))
						)
						"Collision Logic Material" :
						(
							try
							(
								if vCell.Value == "No Collision Object" then
								(
									vCell.Style.BackColor = _dataWarningColor
									vCell.Style.ForeColor = _dataForeColor
								)
								else
								(
									colMat = ds.CheckCollisionType obj
									for i in colMat do
									(
										colObj = getNodeByName i[1]
										if colObj.export_tag == "SCOL" then
										(
											if ((filterString (FindLogicMaterialByID colObj.sound_id).lmName "/")[2]) == "Default" then
											(
												vCell.Style.BackColor = _dataErrorColor
												AppendIfUnique _errordata row 
											)
											else if (findItem LogicMaterial_GlassP obj.name) != 0 then
											(			
												mat = (filterString (FindLogicMaterialByID colObj.sound_id).lmName "/")[2]
												if mat == "Glass_P" then
												(
													vCell.Style.BackColor = _dataOkColor
												)
												else
												(													
													vCell.Style.BackColor = _dataWarningColor
													vCell.Style.ForeColor = _dataForeColor
												)
											)
											else if (findItem LogicMaterial_RubberVehicle obj.name) != 0 then
											(
												mat = (filterString (FindLogicMaterialByID colObj.sound_id).lmName "/")[2]											
												if mat == "Rubber_Vehicle" then
												(
													vCell.Style.BackColor = _dataOkColor
												)
												else
												(
													vCell.Style.BackColor = _dataWarningColor
													vCell.Style.ForeColor = _dataForeColor
												)
											)
											else 
											(
												mat = (filterString (FindLogicMaterialByID colObj.sound_id).lmName "/")[2]											
												if mat == "Metal_Vehicle" or mat == "Glass_P" or mat == "Rubber_Vehicle" then
												(
													vCell.Style.BackColor = _dataOkColor
												)
												else
												(													
													vCell.Style.BackColor = _dataWarningColor
													vCell.Style.ForeColor = _dataForeColor
												)
											)
										)
										else
										(
											vCell.Style.BackColor = _dataErrorColor
											AppendIfUnique _errordata row 											
										)
									)												
								)
							)
							catch(format "@Ballistics Exception: %\n" (getCurrentException()))
						)
						"Materials" :
						(
							colMaterial = ds.CheckCollisionMaterial obj
							if (findItem colMaterial true) != 0 do
							(
								vCell.Style.BackColor = _dataErrorColor
							)
						)
					)
				)
			)
		)
	)	
	-- Data Functions
	function PopulateData =  
	(	
		_tetraQADataList.Rows.Clear()
		objectArr = #()
		for obj in helpers where obj.children.count > 0 do
		(
			for def in (custAttributes.getDefs obj) do
			(
				if def != undefined and def.name == #NMDPrimitiveCustomAttribute do
				(
					AppendIfUnique objectArr obj.name
				)
			)
		)
		rowData = #()
		for obj in objectArr do
		(			
			dgvCell = dotNetObject "DataGridViewTextBoxCell"
			dgvRow = dotNetObject "DataGridViewRow"
			dgvCell.Value = obj
			dgvRow.Cells.Insert 0 dgvCell
			AppendIfUnique rowData dgvRow
		)
		_tetraQADataList.Rows.AddRange rowData
		ds = DataStruct
		ds.ValidateData()
	)
	function PopulateSelectedData = 
	(
		columnData = #()
		if _tetraQADataList.Columns.Count > 1 do
		(
			local ds = DataStruct
			local getOwner
			for i = 0 to _tetraQADataList.Columns.Count-1 do
			(
				AppendIfUnique columnData #(_tetraQADataList.Columns.Item[i].Name,_tetraQADataList.Columns.Item[i].Index)
			)
			for r = 0 to _tetraQADataList.Rows.Count-1 do
			(show
				for c = 1 to _tetraQADataList.Rows.Item[r].Cells.Count-1 do
				(
					columnName = _tetraQADataList.Rows.Item[r].Cells.Item[c].OwningColumn.Name
					columnIndex = _tetraQADataList.Rows.Item[r].Cells.Item[c].ColumnIndex
					ds.InsertData _tetraQADataList.Rows.Item[r].Cells.Item[0].Value _tetraQADataList.Rows.Item[r].Cells.Item[c] columnName
				)				
			)			
			ds.ValidateData()
		)
	)		
	--Style Functions
	function InitializeCheckList = 
	(
		_tetraQACheckList.BackColor = _dnBackColor
		_tetraQACheckList.ForeColor = _dnForeColor
		_tetraQACheckList.BorderStyle = _tetraQACheckList.BorderStyle.None		
		_tetraQACheckList.FullRowSelect = true
		_tetraQACheckList.HideSelection = true
		_tetraQACheckList.View = (dotNetClass "System.Windows.Forms.View").Details
		_tetraQACheckList.Checkboxes = true
		_tetraQACheckList.Size = (dotNetObject "System.Drawing.Size" 170 _tetraQAMaxForm.ClientSize.Height)
		_tetraQACheckList.Scrollable = false	
		_tetraQACheckList.Columns.Add "CheckList" 200
		rows = #()
		for item in _paramList do
		(
			listViewItem = dotNetObject "ListViewItem" item
			Append rows listViewItem
		)
		_tetraQACheckList.Items.AddRange rows
		_tetraQACheckList.Items.Item[0].Checked = true
	)	
	function BuildDataGridHeader hName = 
	(
		dataGridViewCell = dotNetObject "System.Windows.Forms.DataGridViewColumn"
		dataGridViewCell.HeaderText = hName
		dataGridViewCell.MinimumWidth = 5
		dataGridViewCell.Width = (_tetraQADataList.Width/curColumn)
		dataGridViewCell.CellTemplate = dotNetObject "System.Windows.Forms.DataGridViewTextBoxCell"
		dataGridViewCell.Name = hName
		dataGridViewCell.ReadOnly = true
		return dataGridViewCell
	)
	function InitializeDataList =
	(
		_defCellStyle = dotNetObject "DataGridViewCellStyle"	
		_defCellStyle.BackColor = _dnBackColor
		_defCellStyle.ForeColor = _dnForeColor
		_defCellStyle.WrapMode = (dotNetClass "System.Windows.Forms.DataGridViewTriState").True
		
		_tetraQADataList.GridColor = (dotNetClass "System.Drawing.Color").FromArgb 50 50 50
		_tetraQADataList.BackgroundColor = _dnBackColor
		_tetraQADataList.BackColor = _dnBackColor
		_tetraQADataList.ForeColor = _dnBackColor
		_tetraQADataList.AutoSizeRowsMode = _tetraQADataList.AutoSizeRowsMode.AllCells
		_tetraQADataList.DefaultCellStyle = _defCellStyle

		_tetraQADataList.BorderStyle = _tetraQADataList.BorderStyle.None
		_tetraQADataList.AllowUserToAddRows = false
		_tetraQADataList.AutoGenerateColumns = false
		_tetraQADataList.SelectionMode = _tetraQADataList.SelectionMode.FullRowSelect 
		_tetraQADataList.RowHeadersVisible = false
		_tetraQADataList.Left = _tetraQACheckList.Width + _xPadding
		_tetraQADataList.Top = 60
		_tetraQADataList.Size = (dotNetObject "System.Drawing.Size" (_tetraQAMaxForm.Width - (_tetraQACheckList.Width + _xPadding + 16)) (_tetraQAMaxForm.ClientSize.Height-_tetraQADataList.Top))
		
	)
	function InitializeCarData = 
	(
		_tetraQACarName.Size =  (dotNetObject "System.Drawing.Size" (_tetraQAMaxForm.Width - 320) 18)
		_tetraQACarName.Left = (_tetraQACheckList.Width + _xPadding + 10)
		_tetraQACarName.Top = 6
		_tetraQACarName.Text = "Car Name : Max File Not Opened"
		_tetraQACarLocation.Size =  (dotNetObject "System.Drawing.Size" (_tetraQAMaxForm.Width - 320) 18)
		_tetraQACarLocation.Left = (_tetraQACheckList.Width + _xPadding + 10)
		_tetraQACarLocation.Top = 28
		_tetraQACarLocation.Text = "Car Directory : Max File Not Opened"
	)
	function InitializeShowErrors =
	(
		_tetraQAShowErrors.Width = 106
		_tetraQAShowErrors.Text = "Show Error Only"
		_tetraQAShowErrors.Left = (_tetraQAMaxForm.Width - 126)
		_tetraQAShowErrors.Top = 2
	)	
	function InitializeValidateScene =
	(
		_tetraQAValidateScene.Size = dotNetObject "System.Drawing.Size" 100 30
		_tetraQAValidateScene.Left = (_tetraQAMaxForm.Width - 126)
		_tetraQAValidateScene.Top = 26
		_tetraQAValidateScene.Text = "Refesh Data"
		_tetraQAValidateScene.FlatStyle = _tetraQAValidateScene.FlatStyle.Flat
		_tetraQAValidateScene.FlatAppearance.BorderColor = _dnBackColor
		_tetraQAValidateScene.FlatAppearance.BorderSize  = 0
		_tetraQAValidateScene.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 0 150 0
	)

	--Main UI Functions	
	function SetUIControlLocation  =
	(
		_tetraQACheckList.Size = (dotNetObject "System.Drawing.Size" 170 _tetraQAMaxForm.ClientSize.Height)
		_tetraQADataList.Size = (dotNetObject "System.Drawing.Size" (_tetraQAMaxForm.Width - (_tetraQACheckList.Width + _xPadding + 16)) (_tetraQAMaxForm.ClientSize.Height-_tetraQADataList.Top))
		_tetraQAShowErrors.Left = (_tetraQAMaxForm.Width - 126)
		_tetraQACarName.Width = _tetraQAMaxForm.Width - 320
		_tetraQACarLocation.Width = _tetraQAMaxForm.Width - 320
		_tetraQAValidateScene.Left = (_tetraQAMaxForm.Width - 126)
	)
	function RemoveDataGridColumns colName = 
	(
		_tetraQADataList.Columns.Remove (colName)
	)
	function GetCheckListItems =
	(
		tParamsList = #()
		for i = 0 to _tetraQACheckList.Items.Count-1 do 
		(			
			if _tetraQACheckList.Items.Item[i] != undefined and _tetraQACheckList.Items.Item[i].Checked == true then
			(
				AppendIfUnique tParamsList (_tetraQACheckList.Items.Item[i].Text)
			)			
		)
		return tParamsList
	)
	function FixDisplayIndex =
	(
		newParamList = GetCheckListItems()
		if newParamList.Count > 0 do
		(
			for i = 0 to _tetraQADataList.Columns.Count-1 do 
			(
				displayIndex = findItem newParamList (_tetraQADataList.Columns.Item[i].HeaderText)
				if displayIndex > 0 do
				(
					if _tetraQADataList.Columns.Count > 1 do
					(
						_tetraQADataList.Columns.Item[i].Name = (newParamList[i+1])
						_tetraQADataList.Columns.Item[i].HeaderText = (newParamList[i+1])
						--_tetraQADataList.Columns.Item[i].DisplayIndex = displayIndex-1						
					)
				)
			)
		)
	)
	function FixColumnWidth = 
	(
		for i = 0 to _tetraQADataList.Columns.Count-1 do
		(
			_tetraQADataList.Columns.Item[i].AutoSizeMode = (dotNetClass "System.Windows.Forms.DataGridViewAutoSizeColumnMode").Fill
		)
	)
	-- Events
	function OnActivated e =
	(	
		if maxfilepath != "" then
		(
			_tetraQACarLocation.Text = "Car Directory : "+ maxfilepath
		)
		if maxfilename != "" then
		(
			_tetraQACarName.Text= "Car Name : " + maxfilename
		)
	)
	function OnResize e =
	(
		SetUIControlLocation()
	)
	function OnMaximumSizeChanged e =
	(
		SetUIControlLocation()
	)
	function OnItemCheck e =
	(
		if e.NewValue == (dotNetClass "System.Windows.Forms.CheckState").Checked do
		(
			curColumn += 1		
			case e.Index of
			(
				0 : 
				(
					_tetraQADataList.Columns.Add (BuildDataGridHeader "Helpers")
					PopulateData()
				)
				1 : _tetraQADataList.Columns.Add (BuildDataGridHeader "Ballistic")
				2 : _tetraQADataList.Columns.Add (BuildDataGridHeader "LOD Distance")
				3 : _tetraQADataList.Columns.Add (BuildDataGridHeader "Collision Type")
				4 : _tetraQADataList.Columns.Add (BuildDataGridHeader "Collision Logic Material")
				5 : _tetraQADataList.Columns.Add (BuildDataGridHeader "Accessory Parts")
				6 : _tetraQADataList.Columns.Add (BuildDataGridHeader "Materials")
			)				
		)
		if e.NewValue == (dotNetClass "System.Windows.Forms.CheckState").UnChecked do
		(
			if e.Index != 0 then
			(				
				curColumn -= 1					
				RemoveDataGridColumns (_tetraQACheckList.Items.Item[e.Index].Text)
				_errordata = #()
			)
			else
			(				
				e.NewValue = (dotNetClass "System.Windows.Forms.CheckState").Checked
			)			
		)
	)
	function OnItemChecked e =
	(
		FixColumnWidth()
		FixDisplayIndex()
		PopulateSelectedData()
	)
	function OnClick =
	(	
		if _tetraQAShowErrors.Checked != true do
		(
			_errordata = #()
			PopulateData()
			PopulateSelectedData()
		)
	)
	function OnCheckedChanged =
	(
		if _tetraQAShowErrors.Checked == true then
		(
			_tetraQADataList.Rows.Clear()
			_tetraQADataList.Rows.AddRange _errordata
		)
		else
		(
			_errordata = #()
			PopulateData()
			PopulateSelectedData()
		)
	)		
	function OnCellMouseDoubleClick e =
	(
		if e.ColumnIndex == 0 then
		(
			try
			(
				curSelection = #()
				curObj = getNodeByName ((_tetraQADataList.Item e.ColumnIndex e.RowIndex).Value)
				if curObj != undefined and curObj.isHidden == false do
				(
					AppendIfUnique curSelection curObj				
					getChilds = curObj.children
					if getChilds.count > 0 then
					(
						for child in getChilds do AppendIfUnique curSelection child
					)
					max select none
					select curSelection
				)				
			)catch(format "Exception : %\n" (getCurrentException()))
		)
	)
	-- Initialize Main Window
	function InitializeMainWindow =
	(
		_tetraQAMaxForm.MinimumSize = (dotNetObject "System.Drawing.Size" _tetraQAMaxFormWH.x _tetraQAMaxFormWH.y)
		_tetraQAMaxForm.Text = "Tetra QA"
		_tetraQAMaxForm.TopLevel = true
		_tetraQAMaxForm.TopMost = false
		_tetraQAMaxForm.FormBorderStyle = _tetraQAMaxForm.FormBorderStyle.Sizable
		
		InitializeCheckList()
		InitializeDataList()
		InitializeCarData()
		InitializeShowErrors()
		InitializeValidateScene()

		_tetraQAMaxForm.Controls.Add _tetraQACarName
		_tetraQAMaxForm.Controls.Add _tetraQACarLocation
		_tetraQAMaxForm.Controls.Add _tetraQAShowErrors
		_tetraQAMaxForm.Controls.Add _tetraQACheckList
		_tetraQAMaxForm.Controls.Add _tetraQADataList
		_tetraQAMaxForm.Controls.Add _tetraQAValidateScene

		dotNet.AddEventHandler _tetraQAMaxForm "Activated" OnActivated
		dotNet.AddEventHandler _tetraQAMaxForm "Resize" OnResize
		dotNet.AddEventHandler _tetraQAMaxForm "MaximumSizeChanged" OnMaximumSizeChanged	
		
		dotNet.AddEventHandler _tetraQACheckList "ItemCheck" OnItemCheck
		dotNet.AddEventHandler _tetraQACheckList "ItemChecked" OnItemChecked		
		
		dotNet.AddEventHandler _tetraQADataList "CellMouseDoubleClick" OnCellMouseDoubleClick
		
		dotNet.AddEventHandler _tetraQAShowErrors "CheckedChanged" OnCheckedChanged
		
		dotNet.AddEventHandler _tetraQAValidateScene "Click" OnClick
		
		dotNet.setLifetimeControl _tetraQADataList #mxs
	)
	function Show =
	(	
		InitializeMainWindow()
		_tetraQAMaxForm.ShowModeless()
	)	
	Show()
)
