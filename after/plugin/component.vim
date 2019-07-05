"
" insert jira content into markdown as a list item with link
"

if &compatible || exists('b:vue_component')
    finish
endif
let b:vue_component = 1
let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('s:vue_component')
    finish
endif



let s:scriptDir= expand('<sfile>:p:h')
let s:isDiffMode = &diff

let s:vue_component = 1

" use when creating  and finding component files
let s:middleName = 'comp'

" only use when creating component files
let s:scriptExtension = 'js'
let s:styleExtension = 'css'

let s:autoLayout = 0

let s:vue_component_layout_doing = 0

" only use when finding component files
"
" wpy is used for https://github.com/Tencent/wepy
let s:supportVueExtensionList = ['vue', 'wpy']
let s:supportScriptExtensionList = [ 'js', 'ts', 'jsx', 'json']
let s:supportCssExtensionList = ['css', 'scss', 'less']
let s:extensionLangMap = {
            \'js': 'javascript',
            \ 'ts': 'ts',
            \ 'css': 'css',
            \ 'scss': 'scss',
            \}

if exists('g:vue_component_middle_name') && strlen(g:vue_component_middle_name) > 0
    let s:middleName = g:vue_component_middle_name
endif

if exists('g:vue_component_script_extension') && strlen(g:vue_component_script_extension) > 0
    let s:scriptExtension = g:vue_component_script_extension
endif

if exists('g:vue_component_css_extension') && strlen(g:vue_component_css_extension) > 0
    let s:styleExtension = g:vue_component_css_extension
endif

if exists('g:vue_component_auto_layout')
    let s:autoLayout = g:vue_component_auto_layout
endif

if index(s:supportScriptExtensionList, s:scriptExtension) == -1
    call add(s:supportScriptExtensionList, s:scriptExtension)
endif

if index(s:supportCssExtensionList, s:styleExtension) == -1
    call add(s:supportCssExtensionList, s:styleExtension)
endif

" const variable, readonly
let s:generalEndToken =  '/>'
let s:attributeJoinSplitter = '\n  '
let s:lineJoinSplitter = '\n'
let s:lineSplitPattern = '\\n'

function! s:IsIndexFile(file)
    let index = matchend(a:file, 'index\.[jt]s')
    return index > -1
endfunction

" @return {String}
function! s:findTemplateFile(file, templateDir)
    if strlen(a:templateDir) == 0
        return ''
    endif

    let extension = fnamemodify(a:file, ':e')
    let isIndexFile = s:IsIndexFile(a:file)

    if isIndexFile
        let templateFileName = 'index.' . extension
        let templateFile = a:templateDir . '/' . templateFileName
    else
        let templateFileName = 'template.' . extension
        let templateFile = a:templateDir . '/' . templateFileName
    endif

    if filereadable(templateFile)
        return templateFile
    endif

    return ''
endfunction

function! s:CreateAndWriteFile(filePath, templateDir, componentName, componentNameCamel, scriptExtension, styleExtension, vueExtension)
    let templateFilePath = s:findTemplateFile(a:filePath, a:templateDir)

    let lines = []

    if !empty(templateFilePath) && filereadable(templateFilePath)
        let templateLines = readfile(templateFilePath)
        let templateText = join(templateLines, s:lineJoinSplitter)

        let newText = templateText
        let newText = substitute(newText, 'ComponentName', a:componentName  , 'g')
        let newText = substitute(newText, 'component-name', a:componentNameCamel  , 'g')
        let newText = substitute(newText, 'VUE_EXTENSION', a:vueExtension  , 'g')
        let newText = substitute(newText, 'STYLE_EXTENSION', a:styleExtension  , 'g')
        let newText = substitute(newText, 'SCRIPT_EXTENSION', a:scriptExtension  , 'g')

        let lines = split(newText, s:lineSplitPattern)
    endif

    call writefile(lines, a:filePath, 's')
endfunction


function! s:MakeCssFile(vueFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:styleExtension
    endif
    let cssFile = fnamemodify(a:vueFile, ':r') . '.' . s:middleName .'.' . theExtension
    return cssFile
endfunction

"@param {string} vueFile
"@param {string} extension
function! s:MakeIndexFile(vueFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let fileName = 'index.' . theExtension
    let indexFile = fnamemodify(a:vueFile, ':p:h') . '/' . fileName
    return indexFile
endfunction

"@param {string} vueFile
"@param {string} extension
function! s:MakeScriptFile(vueFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let scriptFile = fnamemodify(a:vueFile, ':r') . '.' . s:middleName . '.' . theExtension
    return scriptFile
endfunction

function! s:MakeCssFileList(vueFile)
    let fileList = []
    for extension in s:supportCssExtensionList
        let file = s:MakeCssFile(a:vueFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:MakeScriptFileList(vueFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:MakeScriptFile(a:vueFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:MakeIndexFileList(vueFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:MakeIndexFile(a:vueFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction


" @return {String}
function! s:findTemplateDirUp()
    let currentDir = fnamemodify(getcwd(), ':p')
    let templateDirName = '.vue-component-template'

    " the length of the root path  will more than 1
    while strlen(currentDir) > 1
        let templateDir = currentDir . '/' . templateDirName
        if isdirectory(templateDir)
            return templateDir
        endif
        let currentDir = fnamemodify(currentDir, ':h')
    endwhile

    return ''
endfunction


" @return {String}
function! s:FindTemplateDir()
    if exists('g:vue_component_template_dir')
        if g:vue_component_template_dir ==# 'built-in'
            return s:scriptDir . '/' . 'templates'
        endif
        if !isdirectory(g:vue_component_template_dir)
            echoerr 'g:vue_component_template_dir is not a directory: ' . g:vue_component_template_dir
            return ''
        endif
        return g:vue_component_template_dir
    else
        let templateDir = s:findTemplateDirUp()
        if strlen(templateDir) > 0
            return templateDir
        endif
    endif

    echoerr 'Can not find .vue-component-template directory, please set g:vue_component_template_dir in .vimrc'
    return ''
endfunction

" @param {string} vueFile
" @return {string}
function! s:CompleteExtension(vueFile)
    let extension = fnamemodify(a:vueFile, ':e')
    let index = index(s:supportVueExtensionList, extension)
    if index > -1
        return a:vueFile
    else
        return a:vueFile  . '.vue'
    endif
endfunction


" @param {String} vueFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponent(vueFile, scriptExtension, styleExtension)
function! s:CreateComponent(...)
    let argsCount = a:0
    let vueFile = s:CompleteExtension(a:1)
    let vueExtension = fnamemodify(vueFile, ':e')

    let scriptExtension = s:scriptExtension
    if argsCount >= 2 && strlen(a:2) > 1
        let scriptExtension = a:2
    endif

    let styleExtension =  s:styleExtension
    if argsCount >= 3 && strlen(a:3) > 1
        let styleExtension = a:3
    endif

    let scriptFile = s:MakeScriptFile(vueFile, scriptExtension)
    let cssFile = s:MakeCssFile(vueFile, styleExtension)
    let fileList = [vueFile, scriptFile, cssFile]

    for theFile in fileList
        if filereadable(theFile)
            echoerr theFile . ' does exist!'
            return
        endif
    endfor

    let targetDir = fnamemodify(vueFile, ':p:h')
    if !isdirectory(targetDir)
        call mkdir(targetDir, 'p')
    endif

    let templateDir = s:FindTemplateDir()

    let componentName = s:GetComponentName(vueFile)
    let componentNameCamel = substitute(componentName, '\C[A-Z]',
        \ '\= "-" . tolower(submatch(0))',
        \ 'g')
    let componentNameCamel = substitute(componentNameCamel, '^-', '', '')

    for theFile in fileList
        call s:CreateAndWriteFile(theFile, templateDir, componentName, componentNameCamel, scriptExtension, styleExtension, vueExtension)
    endfor

    call s:LayoutComponent(vueFile, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

" @param {String} vueFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponentWithFolder(vueFile, scriptExtension, styleExtension)
function! s:CreateComponentWithFolder(...)
    let argsCount = a:0
    let completed = s:CompleteExtension(a:1)
    let path = fnamemodify(completed, ':p:r')
    let vueFileName = fnamemodify(completed, ':p:t')
    let vueFile = path . '/' . vueFileName
    let vueExtension = fnamemodify(vueFile, ':e')

    let scriptExtension = s:scriptExtension
    if argsCount >= 2 && strlen(a:2) > 1
        let scriptExtension = a:2
    endif

    let styleExtension =  s:styleExtension
    if argsCount >= 3 && strlen(a:3) > 1
        let styleExtension = a:3
    endif

    let scriptFile = s:MakeScriptFile(vueFile, scriptExtension)
    let cssFile = s:MakeCssFile(vueFile, styleExtension)
    let indexFile = s:MakeIndexFile(vueFile, scriptExtension)
    let fileList = [indexFile, vueFile, scriptFile, cssFile]

    for theFile in fileList
        if filereadable(theFile)
            echoerr theFile . ' does exist!'
            return
        endif
    endfor

    let targetDir = fnamemodify(vueFile, ':p:h')
    if !isdirectory(targetDir)
        call mkdir(targetDir, 'p')
    endif

    let templateDir = s:FindTemplateDir()

    let componentName = s:GetComponentName(vueFile)
    let componentNameCamel = substitute(componentName, '\C[A-Z]',
        \ '\= "-" . tolower(submatch(0))',
        \ 'g')
    let componentNameCamel = substitute(componentNameCamel, '^-', '', '')

    for theFile in fileList
        call s:CreateAndWriteFile(theFile, templateDir, componentName, componentNameCamel, scriptExtension, styleExtension, vueExtension)
    endfor

    call s:LayoutComponent(vueFile, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

function! s:FindScriptFile(vueFile)
    let fileList = s:MakeScriptFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindStyleFile(vueFile)
    let fileList = s:MakeCssFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindIndexFile(vueFile)
    let fileList = s:MakeIndexFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:DetectFolder(vueFile)
    let folderName = s:GetFolderName(a:vueFile)
    let componentName = s:GetComponentName(a:vueFile)
    if folderName !=# componentName
        return 0
    endif
    let indexFile = s:FindIndexFile(a:vueFile)
    return empty(indexFile) ? 0 : 1
endfunction


"@param {string} vueFile
"@param {0|1} includeCss
function! s:LayoutComponent(vueFile, includeCss)
    if exists('*timer_start')
       if s:vue_component_layout_doing
            return
        endif
        let s:vue_component_layout_doing = 1
    endif

    let scriptFile = s:FindScriptFile(a:vueFile)
    let cssFile = s:FindStyleFile(a:vueFile)
    let withFolder = s:DetectFolder(a:vueFile)
    let indexFile = s:FindIndexFile(a:vueFile)

    if strlen(scriptFile) > 0
        execute ':new ' . scriptFile
        execute ':only'
        if a:includeCss && strlen(cssFile) > 0
            if withFolder
                execute ':vnew ' . indexFile
                execute ':new ' . cssFile
                execute ':new ' . a:vueFile
            else
                execute ':vnew ' . cssFile
                execute ':new ' . a:vueFile
            endif
        else
            if withFolder
                execute ':vnew ' . indexFile
                execute ':new ' . a:vueFile
            else
                execute ':vnew ' . a:vueFile
            endif
        endif
    else
        if a:includeCss && strlen(cssFile) > 0
            execute ':new ' . cssFile
            execute ':only'
            if withFolder
                execute ':vnew ' . indexFile
                execute ':new ' . a:vueFile
            else
                execute ':vnew ' . a:vueFile
            endif
        else
            echomsg 'There is no script/style file'
            " execute ':new ' . a:vueFile
            " execute ':only'
        endif
    endif

    if exists('*timer_start')
        call timer_start(1000, 'VueLayoutComponentEnd')
    endif
endfunction

function! s:FindVueFile(prefix)
    for extension in s:supportVueExtensionList
        let file = a:prefix . '.' . extension
        if filereadable(file)
            return file
        endif
    endfor
    return ''
endfunction

function! s:GetVueFileByFile(file)
    let extension = fnamemodify(a:file, ':e')
    let isIndexFile = s:IsIndexFile(a:file)

    let vueFile = ''

    if isIndexFile
        let componentName = s:GetComponentNameFromIndex(a:file)
        let prefix = fnamemodify(a:file, ':p:h') . '/' . componentName
        let vueFile = s:FindVueFile(prefix)
    elseif index(s:supportVueExtensionList, extension) > -1
        let vueFile = a:file
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(a:file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let vueFile = s:FindVueFile(cssFileWithoutMiddle)
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(a:file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let vueFile = s:FindVueFile(scriptFileWithoutMiddle)
    endif

    return vueFile
endfunction

function! s:GetVueFileByCurrent()
    let file = expand('%')
    let vueFile = s:GetVueFileByFile(file)
    return vueFile
endfunction


function! s:LayoutCurrentComponent()
    if &diff || s:isDiffMode
        return
    endif

    let vueFile = s:GetVueFileByCurrent()
    if strlen(vueFile) > 0
        call s:LayoutComponent(vueFile, 1)
    else
        echoerr 'Can not find vue file for current buffer'
    endif
endfunction

function! s:LayoutVueAndScript()
    if &diff || s:isDiffMode
        return
    endif

    let vueFile = s:GetVueFileByCurrent()

    if strlen(vueFile) > 0
        call s:LayoutComponent(vueFile, 0)
    else
        echoerr 'Can not find vue file for current buffer'
    endif
endfunction

function! s:GetNextFile(vueFile, currentType)
    let nextFile = ''

    if a:currentType ==# 'index'
        let nextFile = a:vueFile
    elseif a:currentType ==# 'vue'
        let nextFile = s:FindStyleFile(a:vueFile)
    elseif a:currentType ==# 'css'
        let nextFile = s:FindScriptFile(a:vueFile)
    elseif a:currentType ==# 'script'
        let nextFile = s:FindIndexFile(a:vueFile)
    endif

    return nextFile
endfunction

" @param {String} vueFile
" @param {String} currentType  valid values: vue, css, script, index
function! s:SwitchFile(vueFile, currentType)
    let orderList = ['index', 'vue', 'css', 'script']
    let targetFile = ''

    for type in orderList
        let nextFile = s:GetNextFile(a:vueFile, type)
        if !empty(nextFile)
            let targetFile = nextFile
            break
        endif
    endfor

    if strlen(targetFile) > 0
        execute ':e ' targetFile
    else
        echoerr 'Can not find '. a:currentType . 'for current buffer'
    endif
endfunction

function! s:SwitchCurrentComponent()
    let file = expand('%')
    let extension = fnamemodify(file, ':e')

    let vueFile = s:GetVueFileByFile(file)
    let currentType = ''
    if s:IsIndexFile(file)
        let currentType = 'index'
    elseif index(s:supportVueExtensionList, extension) > -1
        let currentType = 'vue'
    elseif index(s:supportCssExtensionList, extension) > -1
        let currentType = 'css'
    elseif index(s:supportScriptExtensionList, extension) > -1
        let currentType = 'script'
    endif

    if strlen(vueFile) > 0
        call s:SwitchFile(vueFile, currentType)
    else
        echoerr 'Can not find vue file for current buffer'
    endif
endfunction

function! s:ResetStatus()
    let s:vue_component_layout_doing = 0
endfunction


function! s:isQuickFixOpened()
    for index in range(1, winnr('$'))
        let bnum = winbufnr(index)
        if getbufvar(bnum, '&buftype') ==# 'quickfix'
            return 1
        endif
    endfor
    return 0
endfunction


"return 0 or 1
function! s:RenameFile(filePath, newFilePath, bang)
    if executable('mv') == 0
        echoerr 'Need the suppport of `mv` shell command'
        return 0
    endif

    if filereadable(a:filePath) == 0
        echoerr 'The file is not readable: ' . a:filePath
        return 0
    endif
    let prefix = a:bang ? 'mv -fv' : 'mv -nv'
    let command = prefix . ' "' . a:filePath . '" "' . a:newFilePath . '"'
    try
        call system(command)
    catch
        return 0
    endtry

    return 1
endfunction

"return 0 or 1
function! s:RenameFolderName(folder, newFolder, bang)
    return s:RenameFile(a:folder, a:newFolder, a:bang)
endfunction

function! s:GetComponentName(vueFile)
    let name = fnamemodify(a:vueFile, ':t:r')
    return name
endfunction

function! s:GetComponentNameFromIndex(indexFile)
    let name = fnamemodify(a:indexFile, ':h:t')
    return name
endfunction

function! s:GetFolderName(vueFile)
    let name = fnamemodify(a:vueFile, ':h:t')
    return name
endfunction

function! s:ComposeFilePath(filePath, componentName, newComponentName)
    let path = fnamemodify(a:filePath, ':p:h')
    let fileName = fnamemodify(a:filePath, ':t')
    let newFileName = substitute(fileName, a:componentName, a:newComponentName, 'g')
    let newFilePath = path . '/' . newFileName
    return newFilePath
endfunction

" @return {string}
function s:Rename3Files(vueFile, newComponentName, bang)
    let componentName = s:GetComponentName(a:vueFile)
    let vueFileNew = s:ComposeFilePath(a:vueFile, componentName, a:newComponentName)
    let isRenameOk = s:RenameFile(a:vueFile, vueFileNew, a:bang)

    if isRenameOk == 0
        return ''
    endif

    let styleFile = s:FindStyleFile(a:vueFile)
    if strlen(styleFile) > 0
        let styleFileNew = s:ComposeFilePath(styleFile, componentName, a:newComponentName)
        call s:RenameFile(styleFile, styleFileNew, a:bang)
    endif

    let scriptFile = s:FindScriptFile(a:vueFile)
    if strlen(scriptFile) > 0
        let scriptFileNew = s:ComposeFilePath(scriptFile, componentName, a:newComponentName)
        call s:RenameFile(scriptFile, scriptFileNew, a:bang)
    endif

    let styleConfig = {
        \ 'tagname': 'style',
        \}
    let scriptConfig = {
        \ 'tagname': 'script',
        \}
    let tagInfoList = [styleConfig, scriptConfig]
    call s:UpdateHtml(vueFileNew, componentName, a:newComponentName, tagInfoList)
    return vueFileNew
endfunction


function! s:RenameComponentWithoutFolder(vueFile, name, bang)
    let vueFileNew = s:Rename3Files(a:vueFile, a:name, a:bang)
    if !empty(vueFileNew)
        call s:LayoutComponent(vueFileNew, 1)
    endif
endfunction

" @return {0|1}
function s:UpdateIndexFile(vueFile, componentName, newComponentName, bang)
    let indexFile = s:FindIndexFile(a:vueFile)
    if empty(indexFile)
        echoerr 'Failed to find index file.'
        return 0
    endif
    if filereadable(indexFile) == 0
        echoerr 'File is not readable: ' . indexFile
        return 0
    endif

    let lineList = readfile(indexFile)
    let originText = join(lineList, s:lineJoinSplitter)
    let newText = substitute(originText, a:componentName, a:newComponentName, 'g')
    let newLineList = split(newText, s:lineSplitPattern)
    if !empty(newLineList)
        call writefile(newLineList, indexFile, 's')
        return 1
    endif
    return 0
endfunction

function! s:RenameComponentWithFolder(vueFile, newComponentName, bang)
    let componentName = s:GetComponentName(a:vueFile)
    let path = fnamemodify(a:vueFile, ':p:h')
    let newPath = fnamemodify(a:vueFile, ':p:h:h') . '/' . a:newComponentName
    let renameFolderOk = s:RenameFolderName(path, newPath, a:bang)
    if !renameFolderOk
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. a:vueFile
        return
    endif

    let vueFileName = fnamemodify(a:vueFile, ':p:t')
    let vueFileAfterRename = newPath . '/' . vueFileName
    let vueFileNew = s:Rename3Files(vueFileAfterRename, a:newComponentName, a:bang)
    if empty(vueFileNew)
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. a:vueFile
        return
    endif
    call s:UpdateIndexFile(vueFileAfterRename, componentName, a:newComponentName, a:bang)
    call s:LayoutComponent(vueFileNew, 1)
endfunction


function! s:RenameComponent(name, bang)
    let vueFile = s:GetVueFileByCurrent()
    if strlen(vueFile) <= 0
        echoerr 'Can not find vue file for current buffer'
        return
    endif

    let withFolder = s:DetectFolder(vueFile)
    if withFolder
        call s:RenameComponentWithFolder(vueFile, a:name, a:bang)
    else
        call s:RenameComponentWithoutFolder(vueFile, a:name, a:bang)
    endif
endfunction


function! s:ModifiedNodeFilter(index, value)
    let isModified = get(a:value, 'isModified', 0)
    return isModified
endfunction


" @return {AttributeNode}
function! s:FindAttributeNode(attrNodeList, name)
    for attrNode in a:attrNodeList
        let theName = get(attrNode, 'name', '')
        if theName ==# a:name
            return attrNode
        endif
    endfor
endfunction

" @param {Array<String>}
function! s:MergeNodeListToLines(nodeList, html)
    let  modifiedNodeList = filter(copy(a:nodeList), function('s:ModifiedNodeFilter'))
    let length = len(modifiedNodeList)
    if length == 0
        return
    endif

    call sort(modifiedNodeList, 's:NodeCompare')

    let index = 0
    let newHtmlArray = []
    let lastEndIndex = 0


    while index < length
        let node = get(modifiedNodeList, index, {})
        if !empty(node)
            let startIndex = get(node, 'startIndex', -1)
            let endIndex = get(node, 'endIndex', -1)
            " echo 'node text: |' . strpart(a:html, startIndex, endIndex - startIndex) . '|'
            if startIndex > -1 && endIndex > -1
                let htmlBeforeStart = strpart(a:html, lastEndIndex, startIndex - lastEndIndex)
                " echo 'htmlBeforeStart: |' . htmlBeforeStart . '|'
                call add(newHtmlArray, htmlBeforeStart)
                let nodeAsHtml = s:NodeToHtml(node, a:html)
                " echo 'nodeAsHtml: |' . nodeAsHtml . '|'
                call add(newHtmlArray, nodeAsHtml)
                let lastEndIndex = endIndex
            endif
        endif
        let index = index + 1
    endwhile

    let htmlAfter = strpart(a:html, lastEndIndex)
    call add(newHtmlArray, htmlAfter)

    let newHtml = join(newHtmlArray, '')
    let newLines = split(newHtml, s:lineSplitPattern)

    return newLines
endfunction

" @param {String} filePath
" @param {String} srcPart
" @param {String} srcPartNew
" @param {Array} tagInfoList
function! s:UpdateHtml(filePath, srcPart, srcPartNew, tagInfoList)
    if filereadable(a:filePath) == 0 || len(a:tagInfoList) == 0
        echoerr 'File is not readable: ' . a:filePath
        return
    endif

    let lineList = readfile(a:filePath)
    let originalHtml = join(lineList, s:lineJoinSplitter)

    let nodeList = []
    let langDict = {}
    for tagInfo in a:tagInfoList
        let tagname = get(tagInfo, 'tagname', '')
        " echomsg 'tagname: ' . tagname
        if tagname !=# ''
            let tagNodeList = s:ParseTag(tagname, originalHtml)
            if has_key(tagInfo, 'lang')
                let langDict[tagname] = get(tagInfo, 'lang')
            endif
            call extend(nodeList, tagNodeList)
        endif
    endfor

    for node in nodeList
        let nodeTagName = get(node, 'name', '')
        if has_key(node, 'attrs')
            let attrNodeList = get(node, 'attrs', {})
            let srcNode = s:FindAttributeNode(attrNodeList, 'src')
            if !empty(srcNode)
                let srcValue = get(srcNode, 'value', '')
                let newSrcValue = substitute(srcValue, a:srcPart, a:srcPartNew, 'g')
                if newSrcValue !=# srcValue
                    let srcNode['value'] = newSrcValue
                    let langNode = s:FindAttributeNode(attrNodeList, 'lang')
                    let lang = get(langDict, nodeTagName, '')
                    if has_key(langDict, nodeTagName)
                        if empty(langNode)
                            let newLangNode = {
                                \ 'name': 'lang',
                                \ 'value': lang,
                                \}

                            call add(attrNodeList, newLangNode)
                        else
                            let langNode['value'] = lang
                        endif
                    endif
                    let node['isModified'] = 1
                endif
            endif

        endif
    endfor

    " echo originalHtml
    " echo nodeList
    let newLines = s:MergeNodeListToLines(nodeList, originalHtml)

    if !empty(newLines)
        call writefile(newLines, a:filePath, 's')
    endif

    " call s:LayoutComponent(a:filePath, 1)
endfunction

function! s:ChangeExtension(filePath, extension)
    let oldExtension = fnamemodify(a:filePath, ':e')
    let dirPath = fnamemodify(a:filePath, ':p:h')
    let nameWithoutExt = fnamemodify(a:filePath, ':t:r')
    let nameWithNewExt = nameWithoutExt . '.' . a:extension
    let newFilePath = dirPath . '/' . nameWithNewExt
    return newFilePath
endfunction

" rename the extension of style/script
function! s:RenameExtension(extension, bang)

    let vueFile = s:GetVueFileByCurrent()
    if strlen(vueFile) == 0
        echoerr 'Can not find vue file for current buffer'
        return
    endif

    let filePath = ''
    let isScript = 1


    if index(s:supportCssExtensionList, a:extension) > -1
        let filePath = s:FindStyleFile(vueFile)
        let isScript = 0
    elseif index(s:supportScriptExtensionList, a:extension) > -1
        let filePath = s:FindScriptFile(vueFile)
    endif

    if strlen(filePath) == 0
        echomsg 'Can not find style file or script file for current buffer.'
        return
    endif

    let oldExtension = fnamemodify(filePath, ':e')
    let dirPath = fnamemodify(filePath, ':p:h')
    let nameWithExt = fnamemodify(filePath, ':t')
    let nameWithoutExt = fnamemodify(filePath, ':t:r')
    let nameWithNewExt = nameWithoutExt . '.' . a:extension
    let newFilePath = dirPath . '/' . nameWithNewExt

    let isRenameOk = s:RenameFile(filePath, newFilePath, a:bang)
    if !isRenameOk
        echoerr 'Failed to rename file: ' . filePath
        return
    endif

    let lang = get(s:extensionLangMap, a:extension, '')
    let tagname = isScript ? 'script' : 'style'
    let tagConfig = {
        \ 'tagname': tagname,
        \ 'lang': lang
        \ }
    let tagInfoList = [tagConfig]
    call s:UpdateHtml(vueFile, nameWithExt, nameWithNewExt, tagInfoList)

    if isScript
        let indexFile = s:FindIndexFile(vueFile)
        if !empty(indexFile)
            let indexFileNew = s:ChangeExtension(indexFile, a:extension)
            if indexFileNew !=# indexFile
                call s:RenameFile(indexFile, indexFileNew, a:bang)
            endif
        endif
    endif

    call s:LayoutComponent(vueFile, 1)
endfunction


function! s:MatchStopChar(stopCharStack, oneChar)
    let result = {
            \ 'push': 0,
            \ 'pop': 0,
            \}
    let stopChars = [' ', '"', "'"]

    if count(stopChars, a:oneChar) == 0
        return result
    endif

    let quotationList = ["'", '"']
    let lastIndex = len(a:stopCharStack) - 1
    let lastStopChar = get(a:stopCharStack, lastIndex)


    if lastStopChar ==# a:oneChar
        let result['pop'] = 1
    else
        if !(count(quotationList, lastStopChar) > 0 && count(quotationList, a:oneChar) > 0)
            let result['push'] = 1
        endif
    endif

    return result
endfunction


" @return {Array<String>}
function! s:SplitAttributes(text)
    let stack = []
    let stopCharStack = [' ']
    let attrTextList = []

    let index = 0
    let length = strlen(a:text)

    while index < length
        let theChar = strpart(a:text, index, 1)
        let matchResult = s:MatchStopChar(stopCharStack, theChar)

        let shouldPop = get(matchResult, 'pop', 0)
        let shouldPush = get(matchResult, 'push', 0)

        if shouldPush
            call add(stopCharStack, theChar)
            call add(stack, theChar)
        elseif shouldPop
            call remove(stopCharStack, -1)
            call add(stack, theChar)

            let stopCharStackLength = len(stopCharStack)
            if stopCharStackLength == 0
                let attrText = join(stack, '')
                " echo 'before trim: |' . attrText . '|'
                let attrText = trim(attrText)
                " echo 'trimed: |' . attrText . '|'
                if strlen(attrText) > 0
                    call add(attrTextList, attrText)
                endif
                " reset
                let stopCharStack = [' ']
                let stack = []
            endif
        else
            call add(stack, theChar)
        endif
        let index = index + 1
    endwhile

    let stackLength = len(stack)
    if stackLength > 0
        let attrText = join(stack, '')
        let attrText = trim(attrText)
        if strlen(attrText) > 0
            call add(attrTextList, attrText)
        endif
    endif

    return attrTextList
endfunction

" @return {Array<AttributeNode>}
"
" AttributeNode properties
"  * name {String}
"  * [value] {String} optional
"
function! s:ParseAttributes(html)
    " echomsg 'ParseAttributes: |' . a:html . '|'
    let length = strlen(a:html)
    if length == 0
        return []
    endif

    let htmlWithBlank = ' ' . a:html . ' '
    let htmlWithBlank = substitute(htmlWithBlank, '\\n', ' ', 'g')
    let attrTextList = s:SplitAttributes(htmlWithBlank)
    let attrNodeList = []

    for attrText in attrTextList
        let equalMarkIndex = stridx(attrText, '=', 0)
        let attrNode = {}
        if equalMarkIndex == -1
            let attrNode['name'] = attrText
        else
            let name = strpart(attrText, 0, equalMarkIndex - 0)
            let textAfterEqualMark = strpart(attrText, equalMarkIndex + 1)
            let quotationList = ['"', "'"]
            let quotationStr = join(quotationList, '')
            let value = trim(textAfterEqualMark, quotationStr)
            let value = trim(value)
            let attrNode['name'] = name
            let attrNode['value'] = value
        endif
        if !empty(attrNode)
            call add(attrNodeList, attrNode)
        endif
    endfor

    " echo attrNodeList
    return attrNodeList
endfunction

" @return {String}
function! s:AttributesToHtml(attrs)
    let attrList = []
    let ignoreIfNoValue = ['lang']

    for attrItem in a:attrs
        let attrAsString = ''

        let name = get(attrItem, 'name', '')
        let value = get(attrItem, 'value', '')

        if strlen(value) > 0
            let attrAsString =  name . '="' . value . '"'
        else
            if index(ignoreIfNoValue, name) == -1
                let attrAsString = name
            endif
        endif

        if strlen(attrAsString) > 0
            call add(attrList, attrAsString)
        endif
    endfor

    let html = join(attrList, s:attributeJoinSplitter)
    if len(attrList) > 0
        let html = s:attributeJoinSplitter . html . s:attributeJoinSplitter
    endif
    return html
endfunction

" @return {String}
function! s:NodeToHtml(node, originalHtml)
    let isModified = get(a:node, 'isModified', 0)
    if isModified == 0
        let startIndex = get(a:node, 'startIndex', 0)
        let endIndex = get(a:node, 'endIndex', 0)
        let len = endIndex - startIndex
        let html = strpart(a:originalHtml, startIndex, len)
        return html
    endif

    let tagname = get(a:node, 'name', '')
    let attrHtml = ''

    if has_key(a:node, 'attrs')
        let attrs = get(a:node, 'attrs')
        let attrHtml = s:AttributesToHtml(attrs)
    endif

    let innerContent = get(a:node, 'innerContent', '')
    let html = '<' . tagname  . attrHtml . '>' . innerContent . '</'. tagname .'>'

    return html
endfunction

" @return {Node}
" Node properties:
"  * name {String} tag name
"  * [attrs] {Array<AttributeNode>} optional
"  * [innerContent] {String} optional
"  * startIndex {Integer} start index in original html
"  * endIndex {Integer}  end index in original html
"  * isModified {0|1} default is 0
"
function! s:ParseNode(tagname, html, startToken, endToken)
    " echo 'ParseNode -----'
    " echo 'html: ' . a:html
    " echo 'tagname: ' . a:tagname
    " echo 'startToken: ' . a:startToken
    " echo 'endToken: ' . a:endToken

    let node = {}
    let node['name'] = a:tagname
    let attributes = {}

    let startTokenLen = strlen(a:startToken)
    let startTokenIndex = stridx(a:html, a:startToken, 0)
    " echomsg 'startTokenIndex: ' .startTokenIndex

    let htmlWithAttrs = ''

     " <tagname>xxx</tagname>
    if stridx(a:startToken, '>') > -1
        let htmlWithAttrs = ''
        let needleStart = startTokenIndex + startTokenLen
        let endTokenIndex = stridx(a:html, a:endToken, needleStart)
        if endTokenIndex > -1
            let innerContentLength = endTokenIndex - needleStart
            let innerContent = strpart(a:html, needleStart, innerContentLength)
            let node['innerContent'] = innerContent
        endif
    else
        let attrStartIndex = startTokenIndex + startTokenLen
        let attrEndIndex = -1
        " <tagname abc />
        if a:endToken == s:generalEndToken
            let endTokenIndex = stridx(a:html, a:endToken, attrStartIndex)
        else
            " <tagname abc > xxxx </tagname>
            let endMark = '>'
            let attrEndIndex = stridx(a:html, endMark, attrStartIndex)
            if attrEndIndex > -1
                let needleStart = attrEndIndex + strlen(endMark)
                let endTokenIndex = stridx(a:html, a:endToken, needleStart)
                if endTokenIndex > -1
                    let innerContentLength = endTokenIndex - needleStart
                    let innerContent = strpart(a:html, needleStart, innerContentLength)
                    let node['innerContent'] = innerContent
                endif
            endif
        endif

        let htmlWithAttrs = strpart(a:html, attrStartIndex, attrEndIndex - attrStartIndex)
    endif

    let attrNodeList = s:ParseAttributes(htmlWithAttrs)

    if !empty(attrNodeList)
        let node['attrs'] = attrNodeList
    endif

    let node['isModified'] = 0

    return node
endfunction

function! s:NodeCompare(nodeA, nodeB)
    let startIndexA = get(a:nodeA, 'startIndex', -1)
    let startIndexB = get(a:nodeB, 'startIndex', -1)
    if startIndexA == startIndexB
        return 0
    elseif startIndexA > startIndexB
        return 1
    else
        return -1
    endif
endfunction

" @return {Array<Node>}
function! s:ParseTag(tagname, html)
    let startToken = '<' . a:tagname
    let startTokenWithClose = startToken . '>'
    let startTokenWithSpace = startToken . ' '
    let startTokenWithEndLine  = startToken . '\n'
    let realStartToken = ''
    let endToken = '</' . a:tagname .'>'
    let realEndToken = ''

    let needleIndex = 0
    let len = strlen(a:html)
    let nodeList = []

    while needleIndex < len
        let startIndex = stridx(a:html, startTokenWithClose, needleIndex)
        let realStartToken = startTokenWithClose

        if startIndex == -1
            let startIndex = stridx(a:html, startTokenWithSpace, needleIndex)
            " echomsg 'startTokenWithSpace: ' . startTokenWithSpace
            let realStartToken = startTokenWithSpace
        endif

        if startIndex == -1
            " echomsg 'startTokenWithEndLine: ' .startTokenWithEndLine
            let startIndex = stridx(a:html, startTokenWithEndLine, needleIndex)
            let realStartToken = startTokenWithEndLine
        endif
        if startIndex > -1
            let nearstEndTokenIndex = stridx(a:html, endToken, startIndex)
            let nearstGeneralEndTokenIndex = stridx(a:html, s:generalEndToken, startIndex)
            let endIndex = -1
            let endTokenIndex = -1
            if nearstEndTokenIndex > -1 && nearstGeneralEndTokenIndex > -1
                let indexList = [nearstEndTokenIndex, nearstGeneralEndTokenIndex]
                let endTokenIndex = min(indexList)
                if endTokenIndex == nearstGeneralEndTokenIndex
                    let realEndToken = s:generalEndToken
                else
                    let realEndToken = endToken
                endif
            elseif nearstEndTokenIndex > -1
                let endTokenIndex = nearstEndTokenIndex
                let realEndToken = endToken
            elseif nearstGeneralEndTokenIndex > -1
                let endTokenIndex = nearstGeneralEndTokenIndex
                let realEndToken = s:generalEndToken
            else
                echoerr 'Can not find end token for ' . startToken
            endif
            if endTokenIndex > -1
                let node = s:ParseNode(a:tagname, a:html, realStartToken, realEndToken)
                let endIndex = endTokenIndex + strlen(realEndToken)
                if !empty(node)
                    let node['startIndex'] = startIndex
                    let node['endIndex'] = endIndex
                    call add(nodeList, node)
                endif
                let needleIndex = endIndex
            else
                let needleIndex = len
            endif

        else
            let needleIndex = len
        endif
    endwhile

    return nodeList
endfunction


function! VueLayoutAuto(timer)
    let isOpen =  s:isQuickFixOpened()
    if isOpen
        return
    endif

    if s:autoLayout == 1
        execute ':VueLay'
    elseif s:autoLayout == 2
        execute ':VueLayout'
    endif
endfunction

function! VueLayoutComponentEnd(timer)
    call s:ResetStatus()
endfunction

function! VueLayoutAutoWithDelay()
    if s:vue_component_layout_doing
        return
    endif
    call timer_start(10, 'VueLayoutAuto')
endfunction

command! -nargs=+ -complete=file VueCreate call s:CreateComponent(<f-args>)
command! -nargs=+ -complete=file VueCreateFolder call s:CreateComponentWithFolder(<f-args>)
command! VueLayout call s:LayoutCurrentComponent()
command! VueLay call s:LayoutVueAndScript()
command! VueAlt call s:SwitchCurrentComponent()
command! VueReset call s:ResetStatus()
" :VueRename[!] {newame}
command! -nargs=1 -complete=file -bang VueRename :call s:RenameComponent("<args>", "<bang>")
" :VueRenameExt[!] {extension}
command! -nargs=1 -bang VueRenameExt :call s:RenameExtension("<args>", "<bang>")


if exists('*timer_start')
    augroup vuecomponent
        autocmd!
        autocmd BufReadPost *.vue,*.wpy  call VueLayoutAutoWithDelay()
        autocmd BufReadPost index.ts,index.js  call VueLayoutAutoWithDelay()
    augroup END
endif


let &cpoptions = s:save_cpo


