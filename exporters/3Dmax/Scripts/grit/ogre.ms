fileIn (grit_exporter_dir+"util.ms")

-- global structures
struct exportOptions (sampleRate, ikSampleRate, exportAmbient, exportAlpha, blended, exportHelpers)
struct exportAnims (names, startframes, endframes, lengths)

global Anims
global Options

global ini_file_name = "grit.ini"

global GritRolloutOgreMain

fn dft a b = ( if a == undefined then b else a )

fileIn (grit_exporter_dir+"mesh.ms")
fileIn (grit_exporter_dir+"skeleton.ms")
fileIn (grit_exporter_dir+"biped.ms")

global grit_current_mesh_floater = undefined

global GritRolloutOgreMesh

rollout GritRolloutOgreMesh "Mesh" width:272 rolledUp:false -- {{{
(
	bitmap IMGMPRO fileName:"ui/meshpro.bmp"
    checkbox CBexportMesh "Export Mesh" checked:true
    spinner SPblended "Textures to blend:" range:[0,8,1] type:#integer scale:1
	label btex "Number of textures blended with vertex colors"
	label btex2 "If you dont use blend materials, leave this to 1"
    checkbox CBexportColor "Export Vertex Ambient Lighting"
    checkbox CBexportAlpha "Export Vertex Alpha"
    checkbox CBgeneratetangents "Normal Map" checked:false
    checkbox CBtangentsmirrored "Tangents mirrored" checked:false
    checkbox CBtangentsrotated "Tangents rotated" checked:false

    fn update = (
        -- we might get called when the floater does not exist
        if grit_current_mesh_floater == undefined then return()

        if (getCurrentSelection()).count != 1 then (
        ) else (
            local obj = (getCurrentSelection())[1]
            SPblended.value = dft (getUserProp obj "gritMeshBlendedTextures") 1
            CBexportColor.triState = if dft (getUserProp obj "gritMeshExportColour") false then 1 else 0
            CBexportAlpha.triState = if dft (getUserProp obj "gritMeshExportAlpha") false then 1 else 0
            CBgeneratetangents.triState = if dft (getUserProp obj "gritMeshGenerateTangents") false then 1 else 0
            CBtangentsmirrored.triState = if dft (getUserProp obj "gritMeshTangentsMirrored") false then 1 else 0
            CBtangentsrotated.triState = if dft (getUserProp obj "gritMeshTangentsRotated") false then 1 else 0
        )   

        local v = CBexportMesh.enabled and CBexportMesh.checked and ((getCurrentSelection()).count == 1)
        SPblended.enabled = v
        CBexportColor.enabled = v
        CBexportAlpha.enabled = v
        CBgeneratetangents.enabled = v
        CBtangentsmirrored.enabled = v
        CBtangentsrotated.enabled = v
    )       
    on GritRolloutOgreMesh open do update()
    on CBexportMesh changed state do update()

    fn update_from_value name v = (
        setUserProp ((getCurrentSelection())[1]) name v
        update()
    )

    on SPblended changed v do update_from_value "gritMeshBlendedTextures" v
    on CBexportColor changed v do update_from_value "gritMeshExportColour" v
    on CBexportAlpha changed v do update_from_value "gritMeshExportAlpha" v
    on CBgeneratetangents changed v do update_from_value "gritMeshGenerateTangents" v
    on CBtangentsMirrored changed v do update_from_value "gritMeshTangentsMirrored" v
    on CBtangentsRotated changed v do update_from_value "gritMeshTangentsRotated" v

) --}}}

rollout GritRolloutMaterial "Materials" width:272 rolledUp:true -- {{{
(
button ExpMats "Export materials" toolTip:"Exports selected object's materials"
-- this script was made by shadow link but he doesn't own any rights about this. really. <3

fn splitMatFile fileName = (
	matSplitSlash = filterString fileName "\\"
	return matSplitSlash[matSplitSlash.count]
)	

fn exportmatToListener mat = (
	materialName = mat.name
	if mat.diffuseMap != undefined then
	(
		diffMap = mat.diffuseMap.bitmap.fileName
	)
	if mat.bumpMap != undefined then
	(
		normMap = mat.bumpMap.bitmap.fileName
	)
	if mat.specularMap != undefined then
	(
		specMap = mat.specularMap.bitmap.fileName
	)
	if diffMap == undefined then (
		diffMap = ""
	)else(
		diffMap = splitMatFile diffMap as String
		diffMap = "diffuseMap=`" + diffMap + "`"
	)
	if normMap == undefined then (
		normMap = ""
	)else(
		normMap = splitMatFile normMap as String
		normMap = ", normalMap=`" + normMap + "`"
	)
	if specMap == undefined then (
		specMap = ""
	)else(
		specMap = splitMatFile specMap as String
		specMap = ", specularMap=`" + specMap + "`"
	)
	format "material `%` { %%% }\n" materialName diffMap normMap specMap to:listener
)

    on ExpMats pressed do
    (
	if (classof selection[1].material) == MultiMaterial then 
		(
		for mats = 1 to selection[1].material.numsubs do
			(
			exportmatToListener selection[1].material[mats]
			)
		)
	else(
		exportmatToListener selection[1].material
		)
	)
	
)
-- }}}

rollout GritRolloutOgreAnimation "Animation" width:272 rolledUp:true -- {{{
(
	bitmap IMGAPRO fileName:"ui/animpro.bmp"
    checkbox CBexportSkeleton "Export Skeleton" enabled:false
    --checkbox CBbiped "Biped Export" pos:[13,44] width:246 height:19 enabled:false
    spinner SPsamplerate "Sample Rate" enabled:false range:[0,10000,0] type:#float scale:0.5 
    spinner SPiksamplerate "IK Sample Rate" enabled:false range:[0,10000,5] type:#float scale:0.5 
    checkbox CBexporthelpers "Export non-bones objects (must be in the modifier)" enabled:false checked:false
    button addAnimation "Add" enabled:false toolTip:"add an animation to the list"
    button deleteAnimation "Delete" enabled:false toolTip:"remove an animation from the list"
    combobox ListAnimations "" enabled:false
    spinner SPframestart "start frame" enabled:false range:[0,10000,0] type:#integer scale:1
    spinner SPframeend "end frame " enabled:false range:[0,10000,100] type:#integer scale:1
    spinner SPanimlength "length (in sec)" range:[0,10000,10] type:#float scale:0.1
    --on CBbiped changed state do
    --(
    --)

    on GritRolloutOgreAnimation open do
    (
        CBexportSkeleton.enabled = false;
        --CBbiped.enabled = false;
        --CBbiped.checked = false;
        SPsamplerate.enabled = false;
        SPiksamplerate.enabled = false;
        CBexporthelpers.enabled = false;
        addAnimation.enabled = false;
        deleteAnimation.enabled = false;
        ListAnimations.enabled = false;
        SPframestart.enabled = false;
        SPframeend.enabled = false;
        SPanimlength.enabled = false;

        select = getCurrentSelection()
        if ((select[1]!=undefined) and (iskindof select[1] GeometryClass)) then
        (
            CBexportSkeleton.enabled = (getSkin(select[1]) != undefined) or (getPhysique(select[1]) != undefined)
            if (CBexportSkeleton.enabled and CBexportSkeleton.checked) then
            (
                --CBbiped.enabled = true;
                --CBbiped.checked = (getPhysique(select[1]) != undefined);
                SPsamplerate.enabled = true;
                SPiksamplerate.enabled = true;
                CBexporthelpers.enabled = true;
                addAnimation.enabled = true;
                deleteAnimation.enabled = true;
                ListAnimations.enabled = true;
                SPframestart.enabled = true;
                SPframeend.enabled = true;
                SPanimlength.enabled = true;
            )
        )
        
        Anims = exportAnims names:#() startframes:#() endframes:#() lengths:#();
    )
    on CBexportSkeleton changed state do
    (
        select = getCurrentSelection()
        if ((select[1]!=undefined) and (iskindof select[1] GeometryClass)) then
        (
            --CBbiped.enabled = state;
            --CBbiped.checked = (getPhysique(select[1]) != undefined);
            SPsamplerate.enabled = state;
            SPiksamplerate.enabled = state;
            CBexporthelpers.enabled = state;
            addAnimation.enabled = state;
            deleteAnimation.enabled = state;
            ListAnimations.enabled = state;
            SPframestart.enabled = state;
            SPframeend.enabled = state;
            SPanimlength.enabled = state;
        )
    )
    on addAnimation pressed do
    (
        if (ListAnimations.text != "") then
        (
            local array=#();
            for n in ListAnimations.items do
                append array n;
            append array ListAnimations.text;
            ListAnimations.items = array;
            append Anims.names ListAnimations.items[ListAnimations.items.count];
            append Anims.startframes SPframestart.value;
            append Anims.endframes SPframeend.value;
            append Anims.lengths SPanimlength.value;
            ListAnimations.selection = 0;
        )		
    )
    on deleteAnimation pressed do
    (
        if ((ListAnimations.items.count > 0) and (ListAnimations.selection > 0)) then
        (
            local array=#();
            ind = ListAnimations.selection
            deleteItem Anims.names ind
            deleteItem Anims.startframes ind
            deleteItem Anims.endframes ind
            deleteItem Anims.lengths ind
            for n in Anims.names do
                append array n;
            ListAnimations.items = array;
            ListAnimations.selection = 1;
        )
    )
    on ListAnimations selected num  do
    (
        if (ListAnimations.items.count >= num) then
        (
            SPframestart.value = Anims.startframes[num]
            SPframeend.value = Anims.endframes[num]
            SPanimlength.value = Anims.lengths[num]
        )		
    )
    on SPframestart changed val do
    (
        if ((ListAnimations.items.count > 0) and (ListAnimations.selection > 0)) then
        (
            if (ListAnimations.text == Anims.names[ListAnimations.selection]) then
                Anims.startframes[ListAnimations.selection] = SPframestart.value;
        )		
    )
    on SPframeend changed val do
    (
        if ((ListAnimations.items.count > 0) and (ListAnimations.selection > 0)) then
        (
            if (ListAnimations.text == Anims.names[ListAnimations.selection]) then
                Anims.endframes[ListAnimations.selection] = SPframeend.value;
        )		
    )
    on SPanimlength changed val do
    (
        if ((ListAnimations.items.count > 0) and (ListAnimations.selection > 0)) then
        (
            if (ListAnimations.text == Anims.names[ListAnimations.selection]) then
                Anims.lengths[ListAnimations.selection] = SPanimlength.value;
        )		
    )
) -- }}}

Rollout GritRolloutAbout "Help" -- {{{
(
	group "" (
		bitmap IMGABO fileName:"ui/about.bmp"
		label lab1 "Grit Mesh/.skeleton exporter"
		label bspc "Coded by someone, fixed and improved for Grit"
		label bspc2 "by Spark"
		label bspc3 "Export .mesh.xml and .mesh (Use XMLConverter)"
		label bspc4 "Materials are defined by the name"
		label VERSION "1.0.0"
		hyperlink LBLOG "Grit Blog" address:"http://gritengine.com" color:orange across:3 align:#center
		hyperlink LFORM "Grit Forum" address:"http://gritengine.com/game-engine-forum" color:orange align:#center
		hyperlink LWIKI "Grit Wiki" address:"http://gritengine.com/game-engine-wiki" color:orange align:#center
	)
) -- }}}

rollout GritRolloutOgreMain "Main" width:272 -- {{{
(
	bitmap IMGEXP fileName:"ui/export.bmp"
    button chooseDir "Browse save Dir" toolTip:"Choose dir where files are written" across:2
    button Export "Export Selection" toolTip:"Write OGRE files"
    checkbox doPause "Keep command window open after exit" enabled:true checked:false
    edittext editDir ""
    progressBar exportProgress "" color:orange
	bitmap IMGXML fileName:"ui/xmlcon.bmp"
    label lbl01 "XML Converter Program"
    editText editXMLConverter ""
    button browseXMLconverter "Browse" toolTip:"choose your XML converter"
    
    on GritRolloutOgreMain open do
    (
        local lastDir = getINISetting ((getDir #scripts) + ini_file_name) "Settings" "lastDir"
        lastAnimName = getINISetting ((getDir #scripts) + ini_file_name) "Settings" "lastAnimName"
        lastfirstFrame = getINISetting ((getDir #scripts) + ini_file_name) "Settings" "lastFrameStart"
        lastlastFrame = getINISetting ((getDir #scripts) + ini_file_name) "Settings" "lastFrameEnd"
        lastAnimLength = getINISetting ((getDir #scripts) + ini_file_name) "Settings" "lastAnimLength"
        if lastDir != undefined then
            editDir.text = lastDir

        editXMLconverter.text = getINISetting ((getDir #scripts) + ini_file_name) "Directories" "XMLConverter"
        print editXMLconverter.text;

        if (not (doesFileExist editXMLconverter.text)) then (
            if (editXMLConverter.text == "") then (
                MessageBox ("Please specify the location of OgreXMLConverter.exe using this rollout dialog.  It is usually located in the SVN in grit_core/media/Tools") title:"ERROR!"
            ) else (
                MessageBox ("Could not find OgreXMLConverter at: "+editXMLConverter.text) title:"ERROR!"
            )
            editXMLconverter.text = ""
        )
    )
    on chooseDir pressed do
    (
        local filename = getSavePath caption:"Output directory" initialDir: editDir.text 
        if (filename != undefined) then (
            editDir.text = filename
            setINISetting ((getDir #scripts) + ini_file_name) "Settings" "lastDir" editDir.text	
        )
    )
    on browseXMLconverter pressed  do
    (
        local filename = getOpenFileName types:"Executables(*.exe)|*.exe|"
        if (filename == undefined) then return()
        editXMLConverter.text = filename

        if doesFileExist filename then
        (
            setINISetting ((getDir #scripts) + ini_file_name) "Directories" "XMLConverter" editXMLconverter.text;
        )
        else
        (
            MessageBox ("Could not find OgreXMLConverter at the given location: "+filename) title:"ERROR!"
            editXMLconverter.text = ""
        )
    )
    on Export pressed do
    (
        local xmlc = editXMLconverter.text
        if (not (doesFileExist xmlc)) then (
            MessageBox ("Could not find OgreXMLConverter at: \""+xmlc+"\"") title:"ERROR!"
            return()
        ) else if (editDir.text == "") then (
            messageBox "You have to choose an output directory."
            return()
        ) else if (getCurrentSelection()).count == 0 then (
            messageBox "You have to select something for export."
            return()
        )

        clearlistener()

        local selected_objs = selection as array

        for m in selected_objs do (

            local out_file = editDir.text + "\\" + m.name
            
            local options = exportOptions exportAmbient:false exportAlpha:false blended:0
            local exportingMeshDone = false
            local exportingSkelDone = false

            options.blended = dft (getUserProp m "gritMeshBlendedTextures") 1
            options.exportAmbient = dft (getUserProp m "gritMeshExportColour") false
            options.exportAlpha = dft (getUserProp m "gritMeshExportAlpha") false
            local tangents = dft (getUserProp m "gritMeshGenerateTangents") false
            local mirrored = dft (getUserProp m "gritMeshTangentsMirrored") false
            local rotated = dft (getUserProp m "gritMeshTangentsRotated") false

            options.exportHelpers = (GritRolloutOgreAnimation.CBexporthelpers.enabled and GritRolloutOgreAnimation.CBexporthelpers.checked);
            
            if (not (iskindof m GeometryClass or iskindof m Dummy)) then (

                messageBox "You have to select some geometry for export.  Skipping an object."

            ) else (

                if (GritRolloutOgreMesh.CBexportMesh.enabled and GritRolloutOgreMesh.CBexportMesh.checked) then
                (
                    exportProgress.value = 0
                    exportingMeshDone = write_mesh_xml m options out_file
                    exportProgress.value = 0
                )
            
                -- exports skeleton
                -------------------
                if (GritRolloutOgreAnimation.CBexportSkeleton.enabled and GritRolloutOgreAnimation.CBexportSkeleton.checked) then
                (
                    options.sampleRate = GritRolloutOgreAnimation.SPsamplerate.value
                    options.ikSampleRate = GritRolloutOgreAnimation.SPiksamplerate.value
                
                    exportingSkelDone =	writeSkeleton m options Anims out_file
                )
                
                fn exec cmd params = (
                        -- write a batch file and execute that
                        -- this is a workaround for the commandline length restrictions in max
                        local bat_file = sysInfo.tempdir + "max_grit_export.bat"
                        local batchfile = createFile (bat_file)
                        format "\"%\" %\n" cmd params to:batchfile
                        format "@IF ERRORLEVEL 1 GOTO BROKEN\n" to:batchfile
                        if doPause.checked then format "@pause\n" to:batchfile
                        format "@exit\n" to:batchfile
                        format ":BROKEN\n" to:batchfile
                        format "@echo ------------------------------------------------------------------------\n" to:batchfile
                        format "@echo OgreXMLConverter has returned an error.  See above for more information.\n" to:batchfile
                        format "@echo ------------------------------------------------------------------------\n" to:batchfile
                        format "@pause\n" to:batchfile
                        close batchfile
                        local r = ShellLaunch "cmd.exe" ("/C "+bat_file)
                        if not r then (
                            MessageBox "The external utility failed.  I will now show you the executed command in notepad." title:"ERROR!"
                            ShellLaunch "notepad" bat_file
                        )
                        --HiddenDOSCommand ("del "+bat_file)
                )

                if (exportingMeshDone or exportingSkelDone) then (					

                    local OptionConv = "-e";
            
                    if (exportingMeshDone) then (

                        OptionConv = OptionConv + " -log \""+out_file+".mesh.log\""

                        if tangents then OptionConv = OptionConv + " -t";
                        if mirrored then OptionConv = OptionConv + " -tm -ts 4";
                        if rotated then OptionConv = OptionConv + " -tr";

                        exec xmlc (OptionConv + " \"" + out_file + ".mesh.xml\" \"" + out_file + ".mesh\"")
                    )
                    if (exportingSkelDone) then (
                        OptionConv = OptionConv + " -log \""+out_file+".skeleton.log\""
                        exec xmlc ("\"" + out_file + ".skeleton.xml\" \"" + out_file + ".skeleton\"")
                    )
                )
            )
        )
        select selected_objs -- have to alter selection whilst exporting mesh
    )
) -- }}}

callbacks.removescripts id:#GritOgreMeshSelection
callbacks.addScript #selectionSetChanged "GritRolloutOgreMesh.update()" id:#GritOgreMeshSelection

macroScript showGritOgreWindow
	category:"Grit Tools"
	internalCategory:"Grit Tools"
	buttonText:"Grit .mesh/.skeleton Exporter"
	tooltip:"Grit .mesh/.skeleton Exporter"
	Icon:#("Grit",1)
(
	
    if grit_current_meshl_floater != undefined then (
        closeRolloutFloater grit_current_mesh_floater
    )
    grit_current_mesh_floater = newRolloutFloater "Grit .mesh/.skeleton Exporter" 280 500
	addRollout GritRolloutOgreMain grit_current_mesh_floater
	addRollout GritRolloutOgreMesh grit_current_mesh_floater
	addRollout GritRolloutMaterial grit_current_mesh_floater
	addRollout GritRolloutOgreAnimation grit_current_mesh_floater
	addRollout GritRolloutAbout grit_current_mesh_floater
)
