scriptencoding utf-8

if &compatible || exists('b:kit_component')
    finish
endif
let b:kit_component = 1
let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('s:kit_component')
    finish
endif



let s:scriptDir= expand('<sfile>:p:h')
let s:isDiffMode = &diff

let s:kit_component = 1

" use when creating  and finding component files
let s:middleName = { 'vue': 'comp', 'wpy': 'comp', 'jsx': 'module', 'tsx': 'module' }

" only use when creating component files
let s:scriptExtension = 'js'
let s:styleExtension = 'css'

let s:autoLayout = 0

let s:kit_component_layout_doing = 0

" only use when finding component files
"
" wpy is used for https://github.com/Tencent/wepy
let s:supportTemplateExtensionList = ['vue', 'wpy', 'tsx', 'jsx']
let s:supportScriptExtensionList = [ 'js', 'ts', 'json']
let s:supportCssExtensionList = ['css', 'scss', 'less']
let s:extensionLangMap = {
            \'js': 'javascript',
            \ 'ts': 'ts',
            \ 'css': 'css',
            \ 'scss': 'scss',
            \}

let s:supportExtensionFullList = []
call extend(s:supportExtensionFullList, s:supportTemplateExtensionList)
call extend(s:supportExtensionFullList, s:supportScriptExtensionList)
call extend(s:supportExtensionFullList, s:supportCssExtensionList)


if exists('g:kit_component_middle_name') && strlen(g:kit_component_middle_name) > 0
    let s:middleName = g:kit_component_middle_name
endif

if exists('g:kit_component_script_extension') && strlen(g:kit_component_script_extension) > 0
    let s:scriptExtension = g:kit_component_script_extension
endif

if exists('g:kit_component_css_extension') && strlen(g:kit_component_css_extension) > 0
    let s:styleExtension = g:kit_component_css_extension
endif

if exists('g:kit_component_auto_layout')
    let s:autoLayout = g:kit_component_auto_layout
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

" @return {string}
function! s:ReadFile(filePath)
    if !empty(a:filePath) && filereadable(a:filePath)
        let lines = readfile(a:filePath)
        let text = join(lines, s:lineJoinSplitter)
        return text
    endif

    return ''
endfunction

" @return {0|1}
function! s:WriteFile(text, filePath)
    if !empty(a:filePath)
        let lines = split(a:text, s:lineSplitPattern)
        call writefile(lines, a:filePath, 's')
        return 1
    endif

    return 0
endfunction

" @return {String}
function! s:FormatDate()
    let time = localtime()
    let dateFormat = '%Y-%m-%d'
    let dateAsString = strftime(dateFormat, time)
    return dateAsString
endfunction

" @return {0|1}
function! s:CreateAndWriteFile(filePath, templateDir, componentName, componentNameCamel, scriptExtension, styleExtension, templateExtension)
    let templateFilePath = s:findTemplateFile(a:filePath, a:templateDir)
    let templateText = s:ReadFile(templateFilePath)
    let middleName = get(s:middleName, a:templateExtension)

    let content = ''
    let dateAsString = s:FormatDate()

    if strlen(templateText) > 0
        let newText = templateText
        let newText = substitute(newText, 'ComponentName', a:componentName, 'g')
        let newText = substitute(newText, 'component-name', a:componentNameCamel, 'g')
        let newText = substitute(newText, 'MIDDLE_NAME', middleName, 'g')
        let newText = substitute(newText, 'TEMPLATE_EXTENSION', a:templateExtension, 'g')
        let newText = substitute(newText, 'STYLE_EXTENSION', a:styleExtension, 'g')
        let newText = substitute(newText, 'SCRIPT_EXTENSION', a:scriptExtension, 'g')
        let newText = substitute(newText, 'CREATE_DATE', dateAsString, 'g')
        let content = newText
    endif

    let writeOk = s:WriteFile(content, a:filePath)
    return writeOk
endfunction

"@return {0|1}
function! s:UpdateComponentNameInFile(filePath, componentName, componentNameNew)
    let originalText = s:ReadFile(a:filePath)
    if strlen(originalText) == 0
        echoerr 'Failed to read file: ' . a:filePath
        return 0
    endif


    " template or script file
    let newText = substitute(originalText, a:componentName, a:componentNameNew  , 'g')
    let newText = substitute(newText, 'ComponentName', a:componentNameNew  , 'g')

    " template or style file
    let className = s:Camelize(a:componentName)
    let classNameNew = s:Camelize(a:componentNameNew)
    let newText = substitute(newText, className, classNameNew  , 'g')
    let newText = substitute(newText, 'component-name', classNameNew  , 'g')

    let writeOk = s:WriteFile(newText, a:filePath)
    return writeOk
endfunction

" @return {0|1}
function! s:CreateAndWriteFileList(fileList, templateFile, scriptExtension, styleExtension, templateExtension)
    for theFile in a:fileList
        if filereadable(theFile)
            echoerr theFile . ' does exist!'
            return 0
        endif
    endfor

    let targetDir = fnamemodify(a:templateFile, ':p:h')
    if !isdirectory(targetDir)
        call mkdir(targetDir, 'p')
    endif

    let templateDir = s:FindTemplateDirWithType(a:templateFile)
    let componentName = s:GetComponentName(a:templateFile)
    let componentNameCamel = s:Camelize(componentName)

    for theFile in a:fileList
        call s:CreateAndWriteFile(theFile, templateDir, componentName, componentNameCamel, a:scriptExtension, a:styleExtension, a:templateExtension)
    endfor
    return 1
endfunction


function! s:MakeCssFile(templateFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:styleExtension
    endif
    let templateExtension = fnamemodify(a:templateFile, ':e')
    let middleName = get(s:middleName, templateExtension)
    let cssFile = fnamemodify(a:templateFile, ':r') . '.' . middleName .'.' . theExtension
    return cssFile
endfunction

"@param {string} templateFile
"@param {string} extension
function! s:MakeIndexFile(templateFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let fileName = 'index.' . theExtension
    let indexFile = fnamemodify(a:templateFile, ':p:h') . '/' . fileName
    return indexFile
endfunction

"@param {string} templateFile
"@param {string} extension
function! s:MakeScriptFile(templateFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let templateExtension = fnamemodify(a:templateFile, ':e')
    let middleName = get(s:middleName, templateExtension)
    let scriptFile = fnamemodify(a:templateFile, ':r') . '.' . middleName . '.' . theExtension
    return scriptFile
endfunction

function! s:MakeCssFileList(templateFile)
    let fileList = []
    for extension in s:supportCssExtensionList
        let file = s:MakeCssFile(a:templateFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:MakeScriptFileList(templateFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:MakeScriptFile(a:templateFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:MakeIndexFileList(templateFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:MakeIndexFile(a:templateFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction


" @return {String}
function! s:findTemplateDirUp()
    let currentDir = fnamemodify(getcwd(), ':p')
    let templateDirName = '.kit-component-template'

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
    if exists('g:kit_component_template_dir')
        if g:kit_component_template_dir ==# 'built-in'
            return s:scriptDir . '/' . 'templates'
        endif
        if !isdirectory(g:kit_component_template_dir)
            echoerr 'g:kit_component_template_dir is not a directory: ' . g:kit_component_template_dir
            return ''
        endif
        return g:kit_component_template_dir
    else
        let templateDir = s:findTemplateDirUp()
        if strlen(templateDir) > 0
            return templateDir
        endif
    endif

    echoerr 'Can not find .kit-component-template directory, please set g:kit_component_template_dir in .vimrc'
    return ''
endfunction

" @return {String}
function!  s:FindTemplateDirWithType(templateFile)
    let templateDir = s:FindTemplateDir()
    let extension = fnamemodify(a:templateFile, ':e')
    if strlen(templateDir) == 0
        return ''
    endif
    let templateDirWithType = templateDir . '/' . extension
    return templateDirWithType
endfunction

" @param {string} templateFile
" @return {string}
function! s:CompleteExtension(templateFile)
    let extension = fnamemodify(a:templateFile, ':e')
    let index = index(s:supportTemplateExtensionList, extension)
    if index > -1
        return a:templateFile
    else
        return a:templateFile  . '.vue'
    endif
endfunction

function! s:Camelize(str)
    let camelized = substitute(a:str, '\C[A-Z]',
        \ '\= "-" . tolower(submatch(0))',
        \ 'g')
    let camelized = substitute(camelized, '^-', '', '')
    return camelized
endfunction

" function! s:ParseCreateParams(templateFile, scriptOrStyleExtension?, styleOrScriptExtension?)
function! s:ParseCreateParams(args, templateFile, withFolder)
    let result = {}

    if a:templateFile ==# ''
        return result
    endif

    let templateExtension = fnamemodify(a:templateFile, ':e')
    let length = len(a:args)

    let cssExtension = s:styleExtension
    let scriptExtension = s:scriptExtension

    if length >= 1 && length <= 3
        let counter = 1
        while counter < length
            let item = get(a:args, counter)
            if index(s:supportCssExtensionList, item) > -1
                let cssExtension = item
            elseif index(s:supportScriptExtensionList, item) > -1
                let scriptExtension = item
            endif
            let counter += 1
        endwhile
    else
        return result
    endif

    "  针对 *.tsx/*.jsx 特殊处理
    if templateExtension ==# 'tsx'
        let scriptExtension = 'ts'
    elseif templateExtension ==# 'jsx'
        let scriptExtension = 'js'
    endif


    let result['templateFile'] =  a:templateFile
    let result['templateExtension'] = templateExtension
    let result['cssExtension'] = cssExtension
    let result['scriptExtension'] = scriptExtension
    return result
endfunction

" @param {String} templateFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponent(templateFile, scriptExtension, styleExtension)
function! s:CreateComponent(...)
    let templateFile = s:CompleteExtension(a:1)
    let config = s:ParseCreateParams(a:000, templateFile, 0)

    if empty(config)
        echomsg 'Parameter is not valid'
        return
    endif

    let scriptExtension = get(config, 'scriptExtension')
    let styleExtension = get(config, 'styleExtension')
    let templateExtension = get(config, 'templateExtension')

    let scriptFile = s:MakeScriptFile(templateFile, scriptExtension)
    let cssFile = s:MakeCssFile(templateFile, styleExtension)

    if templateExtension ==# 'tsx' || templateExtension ==# 'jsx'
        " *.tsx/*.jsx 不需要 script
        let fileList = [templateFile, cssFile]
    else
        let fileList = [templateFile, scriptFile, cssFile]
    endif


    let isCreateOk = s:CreateAndWriteFileList(fileList, templateFile, scriptExtension, styleExtension, templateExtension)
    if !isCreateOk
        return
    endif

    call s:LayoutComponent(templateFile, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

" @param {String} templateFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponentWithFolder(templateFile, scriptExtension, styleExtension)
function! s:CreateComponentWithFolder(...)
    let completed = s:CompleteExtension(a:1)
    let path = fnamemodify(completed, ':p:r')
    let templateFileName = fnamemodify(completed, ':p:t')
    let templateFile = path . '/' . templateFileName

    let config = s:ParseCreateParams(a:000, templateFile, 1)

    if empty(config)
        echomsg 'Parameter is not valid'
        return
    endif


    let scriptExtension = get(config, 'scriptExtension')
    let styleExtension = get(config, 'styleExtension')
    let templateExtension = get(config, 'templateExtension')

    let scriptFile = s:MakeScriptFile(templateFile, scriptExtension)
    let cssFile = s:MakeCssFile(templateFile, styleExtension)
    let indexFile = s:MakeIndexFile(templateFile, scriptExtension)


    if templateExtension ==# 'wpy'
        " *.wpy 不需要 index
        let fileList = [templateFile, scriptFile, cssFile]
    elseif templateExtension ==# 'tsx' || templateExtension ==# 'jsx'
        " *.tsx/*.jsx 不需要 script
        let fileList = [indexFile, templateFile, cssFile]
    else
        let fileList = [indexFile, templateFile, scriptFile, cssFile]
    endif

    let isCreateOk =   s:CreateAndWriteFileList(fileList, templateFile, scriptExtension, styleExtension, templateExtension)
    if !isCreateOk
        return
    endif

    call s:LayoutComponent(templateFile, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

function! s:FindScriptFile(templateFile)
    let fileList = s:MakeScriptFileList(a:templateFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindStyleFile(templateFile)
    let fileList = s:MakeCssFileList(a:templateFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindIndexFile(templateFile)
    let fileList = s:MakeIndexFileList(a:templateFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:DetectFolder(templateFile)
    let folderName = s:GetFolderName(a:templateFile)
    let componentName = s:GetComponentName(a:templateFile)
    if folderName !=# componentName
        return 0
    endif
    let indexFile = s:FindIndexFile(a:templateFile)
    return empty(indexFile) ? 0 : 1
endfunction


"@param {string} templateFile
"@param {0|1} includeCss
function! s:LayoutComponent(templateFile, includeCss)
    if exists('*timer_start')
       if s:kit_component_layout_doing
            return
        endif
        let s:kit_component_layout_doing = 1
    endif

    let scriptFile = s:FindScriptFile(a:templateFile)
    let cssFile = s:FindStyleFile(a:templateFile)
    let withFolder = s:DetectFolder(a:templateFile)
    let indexFile = s:FindIndexFile(a:templateFile)

    if strlen(scriptFile) > 0
        execute ':new ' . scriptFile
        execute ':only'
        if a:includeCss && strlen(cssFile) > 0
            if withFolder
                execute ':vnew ' . indexFile
                execute ':new ' . cssFile
                execute ':new ' . a:templateFile
            else
                execute ':vnew ' . cssFile
                execute ':new ' . a:templateFile
            endif
        else
            execute ':vnew ' . a:templateFile
        endif
    else
        if a:includeCss && strlen(cssFile) > 0
            execute ':new ' . a:templateFile
            execute ':only'
            if withFolder
                execute ':vnew ' . indexFile
                execute ':new ' . cssFile
            else
                execute ':vnew ' . cssFile
            endif
        else
            " echomsg 'There is no script/style file'
            execute ':new ' . a:templateFile
            execute ':only'
        endif
    endif

    if exists('*timer_start')
        call timer_start(1000, 'KitLayoutComponentEnd')
    endif
endfunction

function! s:FindTemplateFile(prefix)
    for extension in s:supportTemplateExtensionList
        let file = a:prefix . '.' . extension
        if filereadable(file)
            return file
        endif
    endfor
    return ''
endfunction

function! s:GetTemplateFileByFile(file)
    let extension = fnamemodify(a:file, ':e')
    let isIndexFile = s:IsIndexFile(a:file)

    let templateFile = ''

    if isIndexFile
        let componentName = s:GetComponentNameFromIndex(a:file)
        let prefix = fnamemodify(a:file, ':p:h') . '/' . componentName
        let templateFile = s:FindTemplateFile(prefix)
    elseif index(s:supportTemplateExtensionList, extension) > -1
        let templateFile = a:file
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(a:file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let templateFile = s:FindTemplateFile(cssFileWithoutMiddle)
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(a:file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let templateFile = s:FindTemplateFile(scriptFileWithoutMiddle)
    endif

    return templateFile
endfunction

function! s:GetTemplateFileByCurrent()
    let file = expand('%')
    let templateFile = s:GetTemplateFileByFile(file)
    return templateFile
endfunction


function! s:LayoutCurrentComponent()
    if &diff || s:isDiffMode
        return
    endif

    let templateFile = s:GetTemplateFileByCurrent()
    if strlen(templateFile) > 0
        call s:LayoutComponent(templateFile, 1)
    else
        echomsg 'Can not find template file for current buffer'
    endif
endfunction

function! s:LayoutTemplateAndScript()
    if &diff || s:isDiffMode
        return
    endif

    let templateFile = s:GetTemplateFileByCurrent()

    if strlen(templateFile) > 0
        call s:LayoutComponent(templateFile, 0)
    else
        echomsg 'Can not find template file for current buffer'
    endif
endfunction

function! s:GetNextFile(templateFile, currentType)
    let nextFile = ''

    if a:currentType ==# 'index'
        let nextFile = a:templateFile
    elseif a:currentType ==# 'template'
        let nextFile = s:FindStyleFile(a:templateFile)
    elseif a:currentType ==# 'css'
        let nextFile = s:FindScriptFile(a:templateFile)
    elseif a:currentType ==# 'script'
        let nextFile = s:FindIndexFile(a:templateFile)
    endif

    return nextFile
endfunction

" @param {String} templateFile
" @param {String} currentType  valid values: template, css, script, index
function! s:SwitchFile(templateFile, currentType)
    let orderList = ['index', 'template', 'css', 'script']
    let targetFile = ''

    for type in orderList
        let nextFile = s:GetNextFile(a:templateFile, type)
        if !empty(nextFile)
            let targetFile = nextFile
            break
        endif
    endfor

    if strlen(targetFile) > 0
        execute ':e ' targetFile
    else
        echomsg 'Can not find '. a:currentType . 'for current buffer'
    endif
endfunction

function! s:SwitchCurrentComponent()
    let file = expand('%')
    let extension = fnamemodify(file, ':e')

    let templateFile = s:GetTemplateFileByFile(file)
    let currentType = ''
    if s:IsIndexFile(file)
        let currentType = 'index'
    elseif index(s:supportTemplateExtensionList, extension) > -1
        let currentType = 'template'
    elseif index(s:supportCssExtensionList, extension) > -1
        let currentType = 'css'
    elseif index(s:supportScriptExtensionList, extension) > -1
        let currentType = 'script'
    endif

    if strlen(templateFile) > 0
        call s:SwitchFile(templateFile, currentType)
    else
        echomsg 'Can not find template file for current buffer'
    endif
endfunction

function! s:ResetStatus()
    let s:kit_component_layout_doing = 0
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
    if executable('mv') == 0
        echoerr 'Need the suppport of `mv` shell command'
        return 0
    endif

    if isdirectory(a:folder) == 0
        echoerr 'Failed to find directory: ' . a:folder
        return 0
    endif
    let prefix = a:bang ? 'mv -fv' : 'mv -nv'
    let command = prefix . ' "' . a:folder . '" "' . a:newFolder . '"'
    try
        call system(command)
    catch
        return 0
    endtry

    return 1
endfunction

function! s:GetComponentName(templateFile)
    let name = fnamemodify(a:templateFile, ':t:r')
    return name
endfunction

function! s:GetComponentNameFromIndex(indexFile)
    let name = fnamemodify(a:indexFile, ':h:t')
    return name
endfunction

function! s:GetFolderName(templateFile)
    let name = fnamemodify(a:templateFile, ':h:t')
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
function s:Rename3Files(templateFile, newComponentName, bang)
    let componentName = s:GetComponentName(a:templateFile)
    let templateFileNew = s:ComposeFilePath(a:templateFile, componentName, a:newComponentName)
    let isRenameOk = s:RenameFile(a:templateFile, templateFileNew, a:bang)

    if isRenameOk
        call s:UpdateComponentNameInFile(templateFileNew, componentName, a:newComponentName)
    else
        return ''
    endif

    let styleFile = s:FindStyleFile(a:templateFile)
    if strlen(styleFile) > 0
        let styleFileNew = s:ComposeFilePath(styleFile, componentName, a:newComponentName)
        let isRenameOk = s:RenameFile(styleFile, styleFileNew, a:bang)
        if isRenameOk
            call s:UpdateComponentNameInFile(styleFileNew, componentName, a:newComponentName)
        endif
    endif

    let scriptFile = s:FindScriptFile(a:templateFile)
    if strlen(scriptFile) > 0
        let scriptFileNew = s:ComposeFilePath(scriptFile, componentName, a:newComponentName)
        let isRenameOk = s:RenameFile(scriptFile, scriptFileNew, a:bang)
        if isRenameOk
            call s:UpdateComponentNameInFile(scriptFileNew, componentName, a:newComponentName)
        endif
    endif

    let styleConfig = {
        \ 'tagname': 'style',
        \}
    let scriptConfig = {
        \ 'tagname': 'script',
        \}
    let tagInfoList = [styleConfig, scriptConfig]
    call s:UpdateHtml(templateFileNew, componentName, a:newComponentName, tagInfoList)
    return templateFileNew
endfunction


function! s:RenameComponentWithoutFolder(templateFile, name, bang)
    let templateFileNew = s:Rename3Files(a:templateFile, a:name, a:bang)
    if !empty(templateFileNew)
        call s:LayoutComponent(templateFileNew, 1)
    endif
endfunction

" @return {0|1}
function s:UpdateIndexFile(templateFile, componentName, newComponentName, bang)
    let indexFile = s:FindIndexFile(a:templateFile)
    if empty(indexFile)
        echoerr 'Failed to find index file.'
        return 0
    endif

    let originalText = s:ReadFile(indexFile)
    if strlen(originalText) == 0
        echoerr 'Failed to read file: ' . indexFile
        return
    endif

    let newText = substitute(originalText, a:componentName, a:newComponentName, 'g')

    let writeOk = s:WriteFile(newText, indexFile)
    return writeOk
endfunction

function! s:RenameComponentWithFolder(templateFile, newComponentName, bang)
    let componentName = s:GetComponentName(a:templateFile)
    let path = fnamemodify(a:templateFile, ':p:h')
    let newPath = fnamemodify(a:templateFile, ':p:h:h') . '/' . a:newComponentName
    let renameFolderOk = s:RenameFolderName(path, newPath, a:bang)
    if !renameFolderOk
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. a:templateFile
        return
    endif

    let templateFileName = fnamemodify(a:templateFile, ':p:t')
    let templateFileAfterRename = newPath . '/' . templateFileName
    let templateFileNew = s:Rename3Files(templateFileAfterRename, a:newComponentName, a:bang)
    if empty(templateFileNew)
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. a:templateFile
        return
    endif
    call s:UpdateIndexFile(templateFileAfterRename, componentName, a:newComponentName, a:bang)
    call s:LayoutComponent(templateFileNew, 1)
endfunction


function! s:RenameComponent(name, bang)
    let templateFile = s:GetTemplateFileByCurrent()
    if strlen(templateFile) <= 0
        echoerr 'Can not find template file for current buffer'
        return
    endif

    let theName = trim(a:name)
    let withFolder = s:DetectFolder(templateFile)
    if withFolder
        call s:RenameComponentWithFolder(templateFile, theName, a:bang)
    else
        call s:RenameComponentWithoutFolder(templateFile, theName, a:bang)
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

    let templateFile = s:GetTemplateFileByCurrent()
    if strlen(templateFile) == 0
        echoerr 'Can not find template file for current buffer'
        return
    endif

    let filePath = ''
    let isScript = 1


    if index(s:supportCssExtensionList, a:extension) > -1
        let filePath = s:FindStyleFile(templateFile)
        let isScript = 0
    elseif index(s:supportScriptExtensionList, a:extension) > -1
        let filePath = s:FindScriptFile(templateFile)
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
    call s:UpdateHtml(templateFile, nameWithExt, nameWithNewExt, tagInfoList)

    if isScript
        let indexFile = s:FindIndexFile(templateFile)
        if !empty(indexFile)
            let indexFileNew = s:ChangeExtension(indexFile, a:extension)
            if indexFileNew !=# indexFile
                call s:RenameFile(indexFile, indexFileNew, a:bang)
            endif
        endif
    endif

    call s:LayoutComponent(templateFile, 1)
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

function! s:RemoveFile(filePath, removedList)
    if strlen(a:filePath) > 0
        let result = delete(a:filePath, '')
        if result == 0
            call add(a:removedList, a:filePath)
        endif
    endif
endfunction

function! s:RemoveComponentWithTemplateFile(templateFile)
    let withFolder = s:DetectFolder(a:templateFile)

    if withFolder
        let folderPath = fnamemodify(a:templateFile, ':p:h')
        let result = -1
        if isdirectory(folderPath)
            let result = delete(folderPath, 'rf')
        endif
        if result == -1
            echoerr 'Failed to remove directory: ' . folderPath
        else
            echo 'Success remove component of current buffer.'
        endif
    else
        let scriptFile = s:FindScriptFile(a:templateFile)
        let cssFile = s:FindStyleFile(a:templateFile)
        let removedFileList = []
        call s:RemoveFile(scriptFile, removedFileList)
        call s:RemoveFile(cssFile, removedFileList)
        call s:RemoveFile(a:templateFile, removedFileList)

        if len(removedFileList)
            execute ':enew'
            echo 'Success to remove files: ' . join(removedFileList, ', ')
        else
            echo 'Failed to remove component of current buffer.'
        endif
    endif

endfunction

function! s:RemoveCurrentComponent()
    let templateFile = s:GetTemplateFileByCurrent()
    if strlen(templateFile) > 0
        call s:RemoveComponentWithTemplateFile(templateFile)
    else
        echomsg 'Can not find template file for current buffer.'
    endif
endfunction

function! s:MoveFileToFolder(filePath, folderPath, movedFileList)
    if strlen(a:filePath) == 0 || filereadable(a:filePath) == 0
        return
    endif

    let fileName = fnamemodify(a:filePath, ':t')
    let filePathNew = a:folderPath . '/' . fileName
    let fileContent = readfile(a:filePath, 'b')
    call writefile(fileContent, filePathNew, 'b')

    call s:RemoveFile(a:filePath, a:movedFileList)
endfunction

function! s:BuildIndexFile(templateFile, scriptFileExt)
    let indexFilePath = s:MakeIndexFile(a:templateFile, a:scriptFileExt)
    if strlen(indexFilePath) > 0
        let templateDir = s:FindTemplateDirWithType(a:templateFile)
        let componentName = s:GetComponentName(a:templateFile)
        let componentNameCamel = s:Camelize(componentName)
        let templateExtension = fnamemodify(a:templateFile, ':e')

        call s:CreateAndWriteFile(indexFilePath, templateDir, componentName, componentNameCamel, a:scriptFileExt, 'STYLE_EXTENSION', templateExtension)
    endif
endfunction

function! s:FolderizeComponentWithTemplateFile(templateFile)
    let withFolder = s:DetectFolder(a:templateFile)

    if withFolder
        echo 'Component of current buffer is already in folder structure.'
        return
    endif

    let folderPath = fnamemodify(a:templateFile, ':p:r')
    let successToCreateFolder = mkdir(folderPath)
    if successToCreateFolder == 0
        echoerr 'Failed to create folder: ' . folderPath
        return
    endif

    let scriptFile = s:FindScriptFile(a:templateFile)
    let cssFile = s:FindStyleFile(a:templateFile)
    let movedFileList = []

    call s:MoveFileToFolder(scriptFile, folderPath, movedFileList)
    call s:MoveFileToFolder(cssFile, folderPath, movedFileList)
    call s:MoveFileToFolder(a:templateFile, folderPath, movedFileList)

    if len(movedFileList) > 0
        let templateFileName = fnamemodify(a:templateFile, ':t')
        let templateFileNew = folderPath . '/' . templateFileName

        let scriptFileExt = 'ts'
        if strlen(scriptFile) > 0
            let scriptFileExt = fnamemodify(scriptFile, ':e')
        endif

        call s:BuildIndexFile(templateFileNew, scriptFileExt)

        call s:LayoutComponent(templateFileNew, 1)

        echo 'Success to folderize component of current buffer.'
    else
        echo 'Failed to folderize component of current buffer.'
    endif

endfunction

function! s:FolderizeCurrentComponent()
    let templateFile = s:GetTemplateFileByCurrent()
    if strlen(templateFile) > 0
        call s:FolderizeComponentWithTemplateFile(templateFile)
    else
        echomsg 'Can not find template file for current buffer.'
    endif
endfunction

function! KitLayoutAuto(timer)
    let isOpen =  s:isQuickFixOpened()
    if isOpen
        return
    endif

    if s:autoLayout == 1
        call s:LayoutTemplateAndScript()
    elseif s:autoLayout == 2
        call s:LayoutCurrentComponent()
    endif
endfunction

function! KitLayoutComponentEnd(timer)
    call s:ResetStatus()
endfunction

function! KitLayoutAutoWithDelay()
    if s:kit_component_layout_doing
        return
    endif
    call timer_start(10, 'KitLayoutAuto')
endfunction

function! CompRenameCompleter(argLead, cmdLine, cursorPos)
    let templateFile = s:GetTemplateFileByCurrent()

    if strlen(templateFile) > 0
        let componentName = s:GetComponentName(templateFile)
        if strlen(componentName) > 0
            let trimed = trim(a:argLead)
            if strlen(trimed) > 0
                if stridx(componentName, trimed) > -1
                    return [componentName]
                endif
            else
                return [componentName]
            endif
        endif
    endif

    return []
endfunction

function! CompRenameExtCompleter(argLead, cmdLine, cursorPos)
    let trimed = trim(a:argLead)
    if strlen(trimed) == 0
        return s:supportExtensionFullList
    endif

    let length = len(s:supportExtensionFullList)
    let matchList = []
    for item in s:supportExtensionFullList
        if stridx(item, trimed) > -1
            call add(matchList, item)
        endif
    endfor

    return matchList
endfunction



command! -nargs=+ -complete=file CompCreate call s:CreateComponent(<f-args>)
command! -nargs=+ -complete=file CompCreateFolder call s:CreateComponentWithFolder(<f-args>)
command! CompLayout call s:LayoutCurrentComponent()
command! CompLay call s:LayoutTemplateAndScript()
command! CompAlt call s:SwitchCurrentComponent()
command! CompReset call s:ResetStatus()

" :CompRename[!] {newame}
command! -nargs=1 -complete=customlist,CompRenameCompleter -bang CompRename :call s:RenameComponent("<args>", "<bang>")
" :CompRenameExt[!] {extension}
command! -nargs=1 -complete=customlist,CompRenameExtCompleter -bang CompRenameExt :call s:RenameExtension("<args>", "<bang>")

command! -nargs=0 CompRemove :call s:RemoveCurrentComponent()
command! -nargs=0 CompFolderize :call s:FolderizeCurrentComponent()



if exists('*timer_start')
    augroup componentkit
        autocmd!
        autocmd BufReadPost *.vue,*.wpy,*.jsx,*.tsx  call KitLayoutAutoWithDelay()
        autocmd BufReadPost index.ts,index.js  call KitLayoutAutoWithDelay()
    augroup END
endif


let &cpoptions = s:save_cpo


