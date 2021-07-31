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

let s:autoLayout = 'all'

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

if exists('g:kit_component_auto_layout') && index(['simple', 'complex', 'all', 'disable', 'folder'], g:kit_component_auto_layout) > -1
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
function! s:findMainFile(file, templateDir)
    if strlen(a:templateDir) == 0
        return ''
    endif

    let extension = fnamemodify(a:file, ':e')
    let isIndexFile = s:IsIndexFile(a:file)

    if isIndexFile
        let mainFileName = 'index.' . extension
        let mainFile = a:templateDir . '/' . mainFileName
    else
        let mainFileName = 'template.' . extension
        let mainFile = a:templateDir . '/' . mainFileName
    endif

    if filereadable(mainFile)
        return mainFile
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
function! s:CreateAndWriteFile(filePath, templateDir, componentName, scriptExtension, styleExtension, mainExtension)
    let mainFilePath = s:findMainFile(a:filePath, a:templateDir)
    let templateText = s:ReadFile(mainFilePath)
    let middleName = get(s:middleName, a:mainExtension)

    let content = ''
    let dateAsString = s:FormatDate()

    let kebabCase = s:ToKebabCase(a:componentName)
    let camelCase = s:ToCamelCase(a:componentName)

    if strlen(templateText) > 0
        let newText = templateText
        let newText = substitute(newText, '\<ComponentName\>\C', a:componentName, 'g')
        let newText = substitute(newText, '\<component-name\>\C', kebabCase, 'g')
        let newText = substitute(newText, '\<componentName\>\C', camelCase, 'g')
        let newText = substitute(newText, '\<MIDDLE_NAME\>\C', middleName, 'g')
        let newText = substitute(newText, '\<TEMPLATE_EXTENSION\>\C', a:mainExtension, 'g')
        let newText = substitute(newText, '\<STYLE_EXTENSION\>\C', a:styleExtension, 'g')
        let newText = substitute(newText, '\<SCRIPT_EXTENSION\>\C', a:scriptExtension, 'g')
        let newText = substitute(newText, '\<CREATE_DATE\>\C', dateAsString, 'g')
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


    let newText = originalText

    " update PascalCase (template or script file)
    let newText = substitute(newText, '\<' . a:componentName . '\>\C', a:componentNameNew  , 'g')
    let newText = substitute(newText, '\<ComponentName\>\C', a:componentNameNew  , 'g')

    " update kebab case (template or style file)
    let kebabCase = s:ToKebabCase(a:componentName)
    let kebabCaseNew = s:ToKebabCase(a:componentNameNew)
    let newText = substitute(newText, '\<' . kebabCase . '\>\C', kebabCaseNew, 'g')
    let newText = substitute(newText, '\<component-name\>\C', kebabCaseNew, 'g')

    "update camel case
    let camelCase = s:ToCamelCase(a:componentName)
    let camelCaseNew = s:ToCamelCase(a:componentNameNew)
    let newText = substitute(newText, '\<'. camelCase . '\>\C', camelCaseNew, 'g')
    let newText = substitute(newText, '\<componentName\>\C', camelCaseNew, 'g')

    let writeOk = s:WriteFile(newText, a:filePath)
    return writeOk
endfunction

" @return {0|1}
function! s:CreateAndWriteFileList(fileList, mainFile, scriptExtension, styleExtension, mainExtension)
    for theFile in a:fileList
        if filereadable(theFile)
            echoerr theFile . ' does exist!'
            return 0
        endif
    endfor

    let targetDir = fnamemodify(a:mainFile, ':p:h')
    if !isdirectory(targetDir)
        call mkdir(targetDir, 'p')
    endif

    let templateDir = s:FindTemplateDirWithType(a:mainFile)
    let componentName = s:GetComponentName(a:mainFile)

    for theFile in a:fileList
        call s:CreateAndWriteFile(theFile, templateDir, componentName, a:scriptExtension, a:styleExtension, a:mainExtension)
    endfor
    return 1
endfunction


function! s:MakeCssFile(mainFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:styleExtension
    endif
    let mainExtension = fnamemodify(a:mainFile, ':e')
    let middleName = get(s:middleName, mainExtension)
    let cssFile = fnamemodify(a:mainFile, ':r') . '.' . middleName .'.' . theExtension
    return cssFile
endfunction

"@param {string} mainFile
"@param {string} extension
function! s:MakeIndexFile(mainFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let fileName = 'index.' . theExtension
    let indexFile = fnamemodify(a:mainFile, ':p:h') . '/' . fileName
    return indexFile
endfunction

"@param {string} mainFile
"@param {string} extension
function! s:MakeScriptFile(mainFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let mainExtension = fnamemodify(a:mainFile, ':e')
    let middleName = get(s:middleName, mainExtension)
    let scriptFile = fnamemodify(a:mainFile, ':r') . '.' . middleName . '.' . theExtension
    return scriptFile
endfunction

function! s:MakeCssFileList(mainFile)
    let fileList = []
    for extension in s:supportCssExtensionList
        let file = s:MakeCssFile(a:mainFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:MakeScriptFileList(mainFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:MakeScriptFile(a:mainFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:MakeIndexFileList(mainFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:MakeIndexFile(a:mainFile, extension)
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
function!  s:FindTemplateDirWithType(mainFile)
    let templateDir = s:FindTemplateDir()
    let extension = fnamemodify(a:mainFile, ':e')
    if strlen(templateDir) == 0
        return ''
    endif
    let templateDirWithType = templateDir . '/' . extension
    return templateDirWithType
endfunction

" @param {string} mainFile
" @return {string}
function! s:CompleteExtension(mainFile)
    let extension = fnamemodify(a:mainFile, ':e')
    let index = index(s:supportTemplateExtensionList, extension)
    if index > -1
        return a:mainFile
    else
        return a:mainFile  . '.vue'
    endif
endfunction

" AbcEfg -> abc-efg
function! s:ToKebabCase(str)
    return tolower(substitute(a:str, '\C\([a-z]\)\([A-Z]\)', '\1-\2', 'g'))
endfunction

" AbcEfg -> abcEfg
function! s:ToCamelCase(str)
    return tolower(strcharpart(a:str, 0, 1)) . strcharpart(a:str, 1)
endfunction

" function! s:ParseCreateParams(mainFile, scriptOrStyleExtension?, styleOrScriptExtension?)
function! s:ParseCreateParams(args, mainFile, withFolder)
    let result = {}

    if a:mainFile ==# ''
        return result
    endif

    let mainExtension = fnamemodify(a:mainFile, ':e')
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
    if mainExtension ==# 'tsx'
        let scriptExtension = 'ts'
    elseif mainExtension ==# 'jsx'
        let scriptExtension = 'js'
    endif


    let result['mainFile'] =  a:mainFile
    let result['mainExtension'] = mainExtension
    let result['styleExtension'] = cssExtension
    let result['scriptExtension'] = scriptExtension
    return result
endfunction

" @param {String} mainFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponent(mainFile, scriptExtension, styleExtension)
function! s:CreateComponent(...)
    let mainFile = s:CompleteExtension(a:1)
    let config = s:ParseCreateParams(a:000, mainFile, 0)

    if empty(config)
        echomsg 'Parameter is not valid'
        return
    endif

    let scriptExtension = get(config, 'scriptExtension')
    let styleExtension = get(config, 'styleExtension')
    let mainExtension = get(config, 'mainExtension')

    let scriptFile = s:MakeScriptFile(mainFile, scriptExtension)
    let cssFile = s:MakeCssFile(mainFile, styleExtension)

    if mainExtension ==# 'tsx' || mainExtension ==# 'jsx'
        " *.tsx/*.jsx 不需要 script
        let fileList = [mainFile, cssFile]
    else
        let fileList = [mainFile, scriptFile, cssFile]
    endif


    let isCreateOk = s:CreateAndWriteFileList(fileList, mainFile, scriptExtension, styleExtension, mainExtension)
    if !isCreateOk
        return
    endif

    call s:LayoutComponent(mainFile, 1, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

" @param {String} mainFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponentWithFolder(mainFile, scriptExtension, styleExtension)
function! s:CreateComponentWithFolder(...)
    let completed = s:CompleteExtension(a:1)
    let path = fnamemodify(completed, ':p:r')
    let mainFileName = fnamemodify(completed, ':p:t')
    let mainFile = path . '/' . mainFileName

    let config = s:ParseCreateParams(a:000, mainFile, 1)

    if empty(config)
        echomsg 'Parameter is not valid'
        return
    endif


    let scriptExtension = get(config, 'scriptExtension')
    let styleExtension = get(config, 'styleExtension')
    let mainExtension = get(config, 'mainExtension')

    let scriptFile = s:MakeScriptFile(mainFile, scriptExtension)
    let cssFile = s:MakeCssFile(mainFile, styleExtension)
    let indexFile = s:MakeIndexFile(mainFile, scriptExtension)


    if mainExtension ==# 'wpy'
        " *.wpy 不需要 index
        let fileList = [mainFile, scriptFile, cssFile]
    elseif mainExtension ==# 'tsx' || mainExtension ==# 'jsx'
        " *.tsx/*.jsx 不需要 script
        let fileList = [indexFile, mainFile, cssFile]
    else
        let fileList = [indexFile, mainFile, scriptFile, cssFile]
    endif

    let isCreateOk =   s:CreateAndWriteFileList(fileList, mainFile, scriptExtension, styleExtension, mainExtension)
    if !isCreateOk
        return
    endif

    call s:LayoutComponent(mainFile, 1, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

function! s:FindScriptFile(mainFile)
    let fileList = s:MakeScriptFileList(a:mainFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindStyleFile(mainFile)
    let fileList = s:MakeCssFileList(a:mainFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindIndexFile(mainFile)
    let fileList = s:MakeIndexFileList(a:mainFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:DetectFolder(mainFile)
    let folderName = s:GetFolderName(a:mainFile)
    let componentName = s:GetComponentName(a:mainFile)
    if folderName !=# componentName
        return 0
    endif
    let indexFile = s:FindIndexFile(a:mainFile)
    return empty(indexFile) ? 0 : 1
endfunction


"@param {string} mainFile
"@param {0|1} includeCss
function! s:LayoutComponent(mainFile, includeCss, includeIndex)
    if exists('*timer_start')
       if s:kit_component_layout_doing
            return
        endif
        let s:kit_component_layout_doing = 1
    endif

    let scriptFile = s:FindScriptFile(a:mainFile)
    let cssFile = s:FindStyleFile(a:mainFile)
    let withFolder = s:DetectFolder(a:mainFile)
    let indexFile = s:FindIndexFile(a:mainFile)

    " Now the template file
    let fileCount = 1
    if strlen(scriptFile)
        let fileCount +=1
    endif

    if strlen(cssFile)
        let fileCount +=1
    endif

    if fileCount == 1
        echomsg 'Layout cancel: only 1 file'
        call s:ResetStatus()
        return
    endif

    if strlen(scriptFile) > 0
        execute ':new ' . scriptFile
        execute ':only'
        if a:includeCss && strlen(cssFile) > 0
            if withFolder
                if a:includeIndex
                    execute ':vnew ' . indexFile
                    execute ':new ' . cssFile
                    execute ':new ' . a:mainFile
                else
                    execute ':vnew ' . cssFile
                    execute ':new ' . a:mainFile
                endif
            else
                execute ':vnew ' . cssFile
                execute ':new ' . a:mainFile
            endif
        else
            execute ':vnew ' . a:mainFile
        endif
    else
        if a:includeCss && strlen(cssFile) > 0
            execute ':new ' . a:mainFile
            execute ':only'
            if withFolder
                if a:includeIndex
                    execute ':vnew ' . indexFile
                    execute ':new ' . cssFile
                else
                    execute ':vnew ' . cssFile
                endif
            else
                execute ':vnew ' . cssFile
            endif
        else
            " echomsg 'There is no script/style file'
            execute ':new ' . a:mainFile
            execute ':only'
        endif
    endif

    if exists('*timer_start')
        call timer_start(500, 'KitLayoutComponentEnd')
    endif
endfunction

function! s:FindMainFile(prefix)
    for extension in s:supportTemplateExtensionList
        let file = a:prefix . '.' . extension
        if filereadable(file)
            return file
        endif
    endfor
    return ''
endfunction

function! s:GetMainFileByFile(file)
    let extension = fnamemodify(a:file, ':e')
    let isIndexFile = s:IsIndexFile(a:file)

    let mainFile = ''

    if isIndexFile
        let componentName = s:GetComponentNameFromIndex(a:file)
        let prefix = fnamemodify(a:file, ':p:h') . '/' . componentName
        let mainFile = s:FindMainFile(prefix)
    elseif index(s:supportTemplateExtensionList, extension) > -1
        let mainFile = a:file
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(a:file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let mainFile = s:FindMainFile(cssFileWithoutMiddle)
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(a:file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let mainFile = s:FindMainFile(scriptFileWithoutMiddle)
    endif

    return mainFile
endfunction

function! s:GetMainFileByCurrent()
    let file = expand('%')
    let mainFile = s:GetMainFileByFile(file)
    return mainFile
endfunction


function! s:LayoutCurrentComponent(includeIndex)
    if &diff || s:isDiffMode
        return
    endif

    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) > 0
        call s:LayoutComponent(mainFile, 1, a:includeIndex)
    else
        echomsg 'Can not find template file for current buffer'
    endif
endfunction

function! s:EditCurrentFolder()
    let file = expand('%')
    let folder = fnamemodify(file, ':h')
    execute ':edit ' . folder
endfunction

function! s:LayoutTemplateAndScript()
    if &diff || s:isDiffMode
        return
    endif

    let mainFile = s:GetMainFileByCurrent()

    if strlen(mainFile) > 0
        call s:LayoutComponent(mainFile, 0, 0)
    else
        echomsg 'Can not find template file for current buffer'
    endif
endfunction

function! s:GetNextFile(mainFile, currentType)
    let nextFile = ''

    if a:currentType ==# 'index'
        let nextFile = a:mainFile
    elseif a:currentType ==# 'template'
        let nextFile = s:FindStyleFile(a:mainFile)
    elseif a:currentType ==# 'css'
        let nextFile = s:FindScriptFile(a:mainFile)
    elseif a:currentType ==# 'script'
        let nextFile = s:FindIndexFile(a:mainFile)
    endif

    return nextFile
endfunction

" @param {String} mainFile
" @param {String} currentType  valid values: template, css, script, index
function! s:SwitchFile(mainFile, currentType)
    let orderList = ['index', 'template', 'css', 'script']
    let targetFile = ''

    for type in orderList
        let nextFile = s:GetNextFile(a:mainFile, type)
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

    let mainFile = s:GetMainFileByFile(file)
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

    if strlen(mainFile) > 0
        call s:SwitchFile(mainFile, currentType)
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


function! s:DoCompLayoutWithMode(mode)
    if a:mode ==# 'all'
        call s:LayoutCurrentComponent(1)
    elseif a:mode ==# 'complex'
        call s:LayoutCurrentComponent(0)
    elseif a:mode ==# 'folder'
        call s:EditCurrentFolder()
    elseif a:mode ==# 'simple'
         call s:LayoutTemplateAndScript()
    endif
endfunction


" @params {string} mode  simple, complex, all, folder
function! s:CompLayoutWithMode(...)
    if a:0 == 0
         call s:LayoutTemplateAndScript()
        return
    endif

    let mode = a:1
    call s:DoCompLayoutWithMode(mode)
endfunction

function! s:GetComponentName(mainFile)
    let name = fnamemodify(a:mainFile, ':t:r')
    return name
endfunction

function! s:GetComponentNameFromIndex(indexFile)
    let name = fnamemodify(a:indexFile, ':h:t')
    return name
endfunction

function! s:GetFolderName(mainFile)
    let name = fnamemodify(a:mainFile, ':h:t')
    return name
endfunction

function! s:ComposeFilePath(filePath, componentName, newComponentName)
    let path = fnamemodify(a:filePath, ':p:h')
    let fileName = fnamemodify(a:filePath, ':t')
    let newFileName = substitute(fileName,  '\<' . a:componentName . '\>\C', a:newComponentName, 'g')
    let newFilePath = path . '/' . newFileName
    return newFilePath
endfunction

" @return {string}
function s:Rename3Files(mainFile, newComponentName, bang)
    let componentName = s:GetComponentName(a:mainFile)
    let mainFileNew = s:ComposeFilePath(a:mainFile, componentName, a:newComponentName)
    let isRenameOk = s:RenameFile(a:mainFile, mainFileNew, a:bang)

    if isRenameOk
        call s:UpdateComponentNameInFile(mainFileNew, componentName, a:newComponentName)
    else
        return ''
    endif

    let styleFile = s:FindStyleFile(a:mainFile)
    if strlen(styleFile) > 0
        let styleFileNew = s:ComposeFilePath(styleFile, componentName, a:newComponentName)
        let isRenameOk = s:RenameFile(styleFile, styleFileNew, a:bang)
        if isRenameOk
            call s:UpdateComponentNameInFile(styleFileNew, componentName, a:newComponentName)
        endif
    endif

    let scriptFile = s:FindScriptFile(a:mainFile)
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
    call s:UpdateHtml(mainFileNew, '\<' . componentName . '\>\C', a:newComponentName , tagInfoList)
    return mainFileNew
endfunction


function! s:RenameComponentWithoutFolder(mainFile, name, bang)
    let mainFileNew = s:Rename3Files(a:mainFile, a:name, a:bang)
    if !empty(mainFileNew)
        call s:LayoutComponent(mainFileNew, 1, 1)
    endif
endfunction

" @return {0|1}
function s:UpdateIndexFile(mainFile, componentName, newComponentName, bang)
    let indexFile = s:FindIndexFile(a:mainFile)
    if empty(indexFile)
        echoerr 'Failed to find index file.'
        return 0
    endif

    let originalText = s:ReadFile(indexFile)
    if strlen(originalText) == 0
        echoerr 'Failed to read file: ' . indexFile
        return
    endif

    let newText = substitute(originalText, '\<' . a:componentName . '\>\C', a:newComponentName, 'g')

    let writeOk = s:WriteFile(newText, indexFile)
    return writeOk
endfunction

function! s:RenameComponentWithFolder(mainFile, newComponentName, bang)
    let componentName = s:GetComponentName(a:mainFile)
    let path = fnamemodify(a:mainFile, ':p:h')
    let newPath = fnamemodify(a:mainFile, ':p:h:h') . '/' . a:newComponentName
    let renameFolderOk = s:RenameFolderName(path, newPath, a:bang)
    if !renameFolderOk
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. a:mainFile
        return
    endif

    let mainFileName = fnamemodify(a:mainFile, ':p:t')
    let mainFileAfterRename = newPath . '/' . mainFileName
    let mainFileNew = s:Rename3Files(mainFileAfterRename, a:newComponentName, a:bang)
    if empty(mainFileNew)
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. a:mainFile
        return
    endif
    call s:UpdateIndexFile(mainFileAfterRename, componentName, a:newComponentName, a:bang)
    call s:LayoutComponent(mainFileNew, 1, 1)
endfunction


function! s:RenameComponent(name, bang)
    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) <= 0
        echoerr 'Can not find template file for current buffer'
        return
    endif

    let theName = trim(a:name)
    let withFolder = s:DetectFolder(mainFile)
    if withFolder
        call s:RenameComponentWithFolder(mainFile, theName, a:bang)
    else
        call s:RenameComponentWithoutFolder(mainFile, theName, a:bang)
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
function! s:UpdateHtml(filePath, srcPartRegExp, srcPartNewRegExp, tagInfoList)
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
                let newSrcValue = substitute(srcValue,  a:srcPartRegExp, a:srcPartNewRegExp, 'g')
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

    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) == 0
        echoerr 'Can not find template file for current buffer'
        return
    endif

    let filePath = ''
    let isScript = 1


    if index(s:supportCssExtensionList, a:extension) > -1
        let filePath = s:FindStyleFile(mainFile)
        let isScript = 0
    elseif index(s:supportScriptExtensionList, a:extension) > -1
        let filePath = s:FindScriptFile(mainFile)
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
    call s:UpdateHtml(mainFile, nameWithExt, nameWithNewExt, tagInfoList)

    if isScript
        let indexFile = s:FindIndexFile(mainFile)
        if !empty(indexFile)
            let indexFileNew = s:ChangeExtension(indexFile, a:extension)
            if indexFileNew !=# indexFile
                call s:RenameFile(indexFile, indexFileNew, a:bang)
            endif
        endif
    endif

    call s:LayoutComponent(mainFile, 1, 1)
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

function! s:RemoveComponentWithMainFile(mainFile)
    let withFolder = s:DetectFolder(a:mainFile)

    if withFolder
        let folderPath = fnamemodify(a:mainFile, ':p:h')
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
        let scriptFile = s:FindScriptFile(a:mainFile)
        let cssFile = s:FindStyleFile(a:mainFile)
        let removedFileList = []
        call s:RemoveFile(scriptFile, removedFileList)
        call s:RemoveFile(cssFile, removedFileList)
        call s:RemoveFile(a:mainFile, removedFileList)

        if len(removedFileList)
            execute ':enew'
            echo 'Success to remove files: ' . join(removedFileList, ', ')
        else
            echo 'Failed to remove component of current buffer.'
        endif
    endif

endfunction

function! s:RemoveCurrentComponent()
    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) > 0
        call s:RemoveComponentWithMainFile(mainFile)
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

function! s:BuildIndexFile(mainFile, scriptFileExt)
    let indexFilePath = s:MakeIndexFile(a:mainFile, a:scriptFileExt)
    if strlen(indexFilePath) > 0
        let templateDir = s:FindTemplateDirWithType(a:mainFile)
        let componentName = s:GetComponentName(a:mainFile)
        let mainExtension = fnamemodify(a:mainFile, ':e')

        call s:CreateAndWriteFile(indexFilePath, templateDir, componentName, a:scriptFileExt, 'STYLE_EXTENSION', mainExtension)
    endif
endfunction

function! s:FolderizeComponentWithMainFile(mainFile)
    let withFolder = s:DetectFolder(a:mainFile)

    if withFolder
        echo 'Component of current buffer is already in folder structure.'
        return
    endif

    let folderPath = fnamemodify(a:mainFile, ':p:r')
    let successToCreateFolder = mkdir(folderPath)
    if successToCreateFolder == 0
        echoerr 'Failed to create folder: ' . folderPath
        return
    endif

    let scriptFile = s:FindScriptFile(a:mainFile)
    let cssFile = s:FindStyleFile(a:mainFile)
    let movedFileList = []

    call s:MoveFileToFolder(scriptFile, folderPath, movedFileList)
    call s:MoveFileToFolder(cssFile, folderPath, movedFileList)
    call s:MoveFileToFolder(a:mainFile, folderPath, movedFileList)

    if len(movedFileList) > 0
        let mainFileName = fnamemodify(a:mainFile, ':t')
        let mainFileNew = folderPath . '/' . mainFileName

        let scriptFileExt = 'ts'
        if strlen(scriptFile) > 0
            let scriptFileExt = fnamemodify(scriptFile, ':e')
        endif

        call s:BuildIndexFile(mainFileNew, scriptFileExt)

        call s:LayoutComponent(mainFileNew, 1, 1)

        echo 'Success to folderize component of current buffer.'
    else
        echo 'Failed to folderize component of current buffer.'
    endif

endfunction

function! s:FolderizeCurrentComponent()
    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) > 0
        call s:FolderizeComponentWithMainFile(mainFile)
    else
        echomsg 'Can not find template file for current buffer.'
    endif
endfunction

" @params {string} mode  simple, complex, all, disable, folder
function! s:SetAutoLayout(...)
    if a:0 == 0
        let s:autoLayout = 'simple'
    else
        let modes = ['simple', 'complex', 'all', 'disable', 'folder']
        if index(modes, a:1) > -1
            let s:autoLayout = a:1
        else
            let s:autoLayout = 'simple'
        endif
    endif

    call s:CompLayoutWithMode(s:autoLayout)
endfunction

function! KitLayoutAuto(timer)
    let isOpen =  s:isQuickFixOpened()
    if isOpen
        return
    endif

    call s:DoCompLayoutWithMode(s:autoLayout)
endfunction

function! KitLayoutComponentEnd(timer)
    call s:ResetStatus()
endfunction


function! KitLayoutAutoWithDelay()
    if s:autoLayout ==# 'disable'
        return
    endif

    if s:kit_component_layout_doing
        return
    endif
    call timer_start(10, 'KitLayoutAuto')
endfunction

function! CompRenameCompleter(argLead, cmdLine, cursorPos)
    let mainFile = s:GetMainFileByCurrent()

    if strlen(mainFile) > 0
        let componentName = s:GetComponentName(mainFile)
        if strlen(componentName) > 0
            let hint = trim(a:argLead)
            if strlen(hint) > 0
                if stridx(componentName, hint) > -1
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

    call sort(matchList)

    return matchList
endfunction

function! CompLayoutCompleter(argLead, cmdLine, cursorPos)
    let modes = ['simple', 'complex', 'all', 'folder']
    let hint = trim(a:argLead)
    let length = len(hint)

    if length == 0
        call sort(modes)
        return modes
    endif

    let matchList = []
    for item in modes
        if stridx(item, hint) > -1
            call add(matchList, item)
        endif
    endfor

    call sort(matchList)
    return matchList
endfunction

function! CompAutoLayoutCompleter(argLead, cmdLine, cursorPos)
    let modes = ['simple', 'complex', 'all', 'disable', 'folder']
    let hint = trim(a:argLead)
    let length = len(hint)

    if length == 0
        call sort(modes)
        return modes
    endif

    let matchList = []
    for item in modes
        if stridx(item, hint) > -1
            call add(matchList, item)
        endif
    endfor

    call sort(matchList)
    return matchList
endfunction



command! -nargs=+ -complete=file CompCreate call s:CreateComponent(<f-args>)
command! -nargs=+ -complete=file CompCreateFolder call s:CreateComponentWithFolder(<f-args>)
command! -nargs=? -complete=customlist,CompLayoutCompleter CompLayout call s:CompLayoutWithMode(<f-args>)
command! CompAlt call s:SwitchCurrentComponent()
command! CompReset call s:ResetStatus()
command! -nargs=? -complete=customlist,CompAutoLayoutCompleter CompLayoutAuto call s:SetAutoLayout(<f-args>)

" :CompRename[!] {newame}
command! -nargs=1 -complete=customlist,CompRenameCompleter -bang CompRename :call s:RenameComponent("<args>", "<bang>")
" :CompRenameExt[!] {extension}
command! -nargs=1 -complete=customlist,CompRenameExtCompleter -bang CompRenameExt :call s:RenameExtension("<args>", "<bang>")

command! -nargs=0 CompRemove :call s:RemoveCurrentComponent()
command! -nargs=0 CompFolderize :call s:FolderizeCurrentComponent()



if exists('*timer_start')
    augroup componentkit
        autocmd!
        autocmd BufReadPost *.vue,*.wpy,*.jsx,*.tsx,*.comp.ts,*.comp.js,*.comp.scss,*.comp.less,*.comp.css  call KitLayoutAutoWithDelay()
        autocmd BufReadPost index.ts,index.js  call KitLayoutAutoWithDelay()
    augroup END
endif


let &cpoptions = s:save_cpo


