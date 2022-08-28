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
let s:auto_layout_default = 'all'
let s:autoLayout = s:auto_layout_default
let s:kit_component_layout_doing = 0

" only use when finding component files
"
" wpy is used for https://github.com/Tencent/wepy
let s:supportMainFileExtensionList = ['vue', 'wpy', 'tsx', 'jsx', 'ts']
let s:supportScriptExtensionList = [ 'js', 'ts', 'json']
let s:supportStyleExtensionList = ['css', 'scss', 'less']
let s:extensionLangMap = {
            \'js': 'javascript',
            \ 'ts': 'ts',
            \ 'css': 'css',
            \ 'scss': 'scss',
            \ 'less': 'less',
            \}

let s:supportExtensionFullList = []
call extend(s:supportExtensionFullList, s:supportMainFileExtensionList)
call extend(s:supportExtensionFullList, s:supportScriptExtensionList)
call extend(s:supportExtensionFullList, s:supportStyleExtensionList)


if exists('g:kit_component_auto_layout') && index(['simple', 'complex', 'all', 'disable', 'folder'], g:kit_component_auto_layout) > -1
    let s:autoLayout = g:kit_component_auto_layout
endif


" const variable, readonly
let s:generalEndToken =  '/>'
let s:attributeJoinSplitter = '\n  '
let s:lineJoinSplitter = '\n'
let s:lineSplitPattern = '\\n'

function! s:GetLang(fileNameOrExt)
    if stridx(a:fileNameOrExt, '.') > -1
        let lastExt = fnamemodify(a:fileNameOrExt, ':e')
    else
        let lastExt = a:fileNameOrExt
    endif
    let lang = get(s:extensionLangMap, lastExt, '')
    return lang
endfunction

function! s:IsIndexFile(file)
    let index = matchend(a:file, 'index\.[jt]s')
    return index > -1
endfunction

" @return {String}
function! s:FindTemplateFile(file, templateDir)
    if strlen(a:templateDir) == 0
        return ''
    endif

    let extension = fnamemodify(a:file, ':e:e')
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

" @return  {ReadFileResult}
" @interface ReadFileResult {
"   readSuccess: 0 | 1
"   text: string
" }
function! s:ReadFile(filePath)
    if !empty(a:filePath) && filereadable(a:filePath)
        let lines = readfile(a:filePath)
        let text = join(lines, s:lineJoinSplitter)
        return { 'readSuccess': 1, 'text': text }
    endif
    return { 'readSuccess': 0, 'text': '' }
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


" @param {string} filePath
" @param {string} templateDir
" @param {CreateConfig} config
" @return {0|1}
function! s:CreateAndWriteFile(filePath, templateDir, config)
    let templateFilePath = s:FindTemplateFile(a:filePath, a:templateDir)
    let readTemplateResult = s:ReadFile(templateFilePath)
    let templateText = get(readTemplateResult, 'text', '')

    let content = ''

    let componentName = get(a:config, 'componentName', '')
    let pascalCase = s:ToPascalCase(componentName)
    let kebabCase = s:ToKebabCase(componentName)
    let camelCase = s:ToCamelCase(componentName)

    if strlen(templateText) > 0
        let mainExtension = get(a:config, 'mainExtension', '')
        let styleExtension = get(a:config, 'styleExtension', '')
        let styleLang = get(a:config, 'styleLang', '')
        let scriptExtension = get(a:config, 'scriptExtension', '')
        let scriptLang = get(a:config, 'scriptLang', '')

        let newText = templateText
        let newText = substitute(newText, '\<ComponentName\>\C', pascalCase, 'g')
        let newText = substitute(newText, '\<component-name\>\C', kebabCase, 'g')
        let newText = substitute(newText, '\<componentName\>\C', camelCase, 'g')

        if strlen(mainExtension)
            let newText = substitute(newText, '\<MAIN_EXTENSION\>\C', mainExtension, 'g')
        endif
        if strlen(styleExtension)
            let newText = substitute(newText, '\<STYLE_EXTENSION\>\C', styleExtension,  'g')
        endif
        if strlen(styleLang)
            let newText = substitute(newText, '\<STYLE_LANG\>\C', styleLang,  'g')
        endif
        if strlen(scriptExtension)
            let newText = substitute(newText, '\<SCRIPT_EXTENSION\>\C',  scriptExtension, 'g')
        endif
        if strlen(scriptLang)
            let newText = substitute(newText, '\<SCRIPT_LANG\>\C', scriptLang,  'g')
        endif

        let dateAsString = s:FormatDate()
        let newText = substitute(newText, '\<CREATE_DATE\>\C', dateAsString, 'g')

        let content = newText
    endif

    let writeOk = s:WriteFile(content, a:filePath)
    return writeOk
endfunction

"@return {0|1}
function! s:UpdateComponentNameInFile(filePath, componentName, componentNameNew)
    let readResult = s:ReadFile(a:filePath)

    if readResult.readSuccess == 0
        echoerr 'Failed to read file: ' . a:filePath
        return 0
    endif


    let originalText = get(readResult, 'text', '')
    let newText = originalText

    " update PascalCase (template or script file)
    let pascalCase = s:ToPascalCase(a:componentName)
    let pascalCaseNew = s:ToPascalCase(a:componentNameNew)
    let newText = substitute(newText, '\<' . a:componentName . '\>\C', pascalCase  , 'g')
    let newText = substitute(newText, '\<ComponentName\>\C', pascalCaseNew  , 'g')

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

" @param {string[]} fileList
" @param {string} mainFile
" @param {CreateConfig} config
" @return {0|1}
function! s:CreateAndWriteFileList(fileList, mainFile, config)
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

    for theFile in a:fileList
        call s:CreateAndWriteFile(theFile, templateDir, a:config)
    endfor
    return 1
endfunction


function! s:MakeStyleFile(mainFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        return ''
    endif
    let styleFile = fnamemodify(a:mainFile, ':r')  .'.' . theExtension
    return styleFile
endfunction

"@param {string} mainFile
"@param {string} extension
"@return {string}
function! s:MakeIndexFile(mainFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        return ''
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
        return ''
    endif
    let scriptFile = fnamemodify(a:mainFile, ':r') . '.' . theExtension
    return scriptFile
endfunction


" @return {String}
function! s:FindTemplateDirUp()
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
        let templateDir = s:FindTemplateDirUp()
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
    let index = index(s:supportMainFileExtensionList, extension)
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
" abcEfg -> abcEfg
function! s:ToCamelCase(str)
    return tolower(strcharpart(a:str, 0, 1)) . strcharpart(a:str, 1)
endfunction

" abcEfg -> AbcEfg
" AbcEfg -> AbcEfg
function! s:ToPascalCase(str)
    return toupper(strcharpart(a:str, 0, 1)) . strcharpart(a:str, 1)
endfunction

" @return 0 | 1
function! s:EndWith(text, subText)
    let index = strridx(a:text, a:subText)
    if index == -1
        return 0
    endif
    return index + len(a:subText) == len(a:text)
endfunction

" @param {string} fileName
" @param {string} type  'main'/'script'/'style
" @return {0|1}
function! s:IsSupportedByExtension(fileName, type)
    let extList = []
    if a:type ==# 'main'
        let extList = s:supportMainFileExtensionList
    elseif a:type ==# 'style'
        let extList = s:supportStyleExtensionList
    elseif a:type ==# 'script'
        let extList = s:supportScriptExtensionList
    endif

    for item in extList
        let dotItem = '.' . item
        if s:EndWith(a:fileName, dotItem)
            return 1
        endif
    endfor

    return 0
endfunction

" @param {string} fileName
" @return {0|1}
function! s:IsSupportedStyleExtension(fileName)
    return s:IsSupportedByExtension(a:fileName, 'style')
endfunction

" @param {string} fileName
" @return {0|1}
function! s:IsSupportedScriptExtension(fileName)
    return s:IsSupportedByExtension(a:fileName, 'script')
endfunction



" @param {string} fileName
" @return {0|1}
function! s:IsSupportedMainExtension(fileName)
    return s:IsSupportedByExtension(a:fileName, 'main')
endfunction

" @return {
"   scriptExtension?: string
"   styleExtension?: string
" }
function! s:ParseStyleAndScript(ext)
    let result = {}

    let fakeName = 'fake.' . a:ext
    if s:IsSupportedStyleExtension(fakeName)
        let result.styleExtension = a:ext
    elseif s:IsSupportedScriptExtension(fakeName)
        let result.scriptExtension = a:ext
    endif

    return result
endfunction


function! s:GetIndexExtension(scriptFile, mainFile)
    let indexExt = 'js'
    let scriptLastExtension = fnamemodify(a:scriptFile, ':e')
    let mainLastExtension = fnamemodify(a:mainFile, ':e')
    if empty(scriptLastExtension)
        if mainLastExtension ==# 'tsx' || mainLastExtension ==# 'ts'
            let indexExt = 'ts'
        endif
    else
        let indexExt = scriptLastExtension
    endif
    return indexExt
endfunction


" @return interface CreateConfig {
"   componentName: string
"   mainFile: string
"   mainExtension: string
"   styleExtension: string
"   styleLang: string
"   scriptExtension: string
"   scriptLang: string
"   indexExtension: string
"   isFolderize:0 | 1
" }
function! s:ParseCreateParams(args, mainFile, isFolderize)
    let result = {}

    if a:mainFile ==# ''
        return result
    endif

    let mainExtension = fnamemodify(a:mainFile, ':e')
    let length = len(a:args)
    let componentName = s:GetComponentName(a:mainFile)

    let argsLength = len(a:args)

    let styleExtension = ''
    let scriptExtension = ''

    if length >= 1 && length <= 3
        let counter = 1
        while counter < length
            let item = get(a:args, counter)
            let parsedItem = s:ParseStyleAndScript(item)
            let ext = get(parsedItem, 'styleExtension', '')

            if len(ext) > 0
                let styleExtension = ext
            else
                let ext = get(parsedItem, 'scriptExtension', '')
                if len(ext) > 0
                    let scriptExtension = ext
                endif
            endif

            let counter += 1
        endwhile
    else
        return result
    endif


    let fakeScriptFile = 'fake.' . scriptExtension
    let indexExtension = s:GetIndexExtension(fakeScriptFile, a:mainFile)

    let result['mainFile'] =  a:mainFile
    let result['componentName'] = componentName
    let result['mainExtension'] = mainExtension
    let result['styleExtension'] = styleExtension
    let result['styleLang'] = s:GetLang(styleExtension)
    let result['scriptExtension'] = scriptExtension
    let result['scriptLang'] = s:GetLang(scriptExtension)
    let result['indexExtension'] = indexExtension
    let result['isFolderize'] = a:isFolderize
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

    let fileList =[mainFile]

    let scriptFile = s:MakeScriptFile(mainFile, scriptExtension)
    if len(scriptFile) > 0
        call add(fileList, scriptFile)
    endif

    let styleFile = s:MakeStyleFile(mainFile, styleExtension)
    if len(styleFile) > 0
        call add(fileList, styleFile)
    endif

    let isCreateOk = s:CreateAndWriteFileList(fileList, mainFile, config)
    if !isCreateOk
        return
    endif

    let layoutConfig = {
                \ 'scriptFile': 1,
                \ 'styleFile': 1,
                \ 'indexFile': 1
                \ }
    call s:LayoutComponentByMainFile(mainFile, layoutConfig)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

" @param {String} mainFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponentWithFolder(mainFile, scriptExtension?, styleExtension?)
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


    let fileList = [ mainFile ]

    let scriptExtension = get(config, 'scriptExtension', '')
    let styleExtension = get(config, 'styleExtension', '')
    let mainExtension = get(config, 'mainExtension', '')
    let indexExtension = get(config, 'indexExtension', '')

    let scriptFile = s:MakeScriptFile(mainFile, scriptExtension)
    if len(scriptFile) > 0
        call add(fileList, scriptFile)
    endif

    let styleFile = s:MakeStyleFile(mainFile, styleExtension)
    if len(styleFile) > 0
        call add(fileList, styleFile)
    endif

    let indexFile = s:MakeIndexFile(mainFile, indexExtension)
    if len(indexFile) > 0
        call add(fileList, indexFile)
    endif


    let isCreateOk = s:CreateAndWriteFileList(fileList, mainFile, config)
    if !isCreateOk
        return
    endif

    let layoutConfig = {
                \ 'scriptFile': 1,
                \ 'styleFile': 1,
                \ 'indexFile': 1
                \ }
    call s:LayoutComponentByMainFile(mainFile, layoutConfig)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction


" @return {0|1}
function! s:DetectFolder(mainFile)
    let folderName = s:GetFolderName(a:mainFile)
    let componentName = s:GetComponentName(a:mainFile)
    return folderName ==# componentName
endfunction



" 获取 mainFile 相邻的文件名，排除 mainFile
" @param {string} mainFile
" @param {string} componentName
" @return {string[]}
function! s:GetSiblingFileNames(mainFile, componentName)
    let siblings = []
    let dirPath = fnamemodify(a:mainFile, ':p:h')
    let entries = readdirex(dirPath)
    let mainFileName = fnamemodify(a:mainFile, ':t')
    let componentNameDot = a:componentName . '.'
    for entry in entries
        if entry.type ==# 'file' && entry.name !=# mainFileName
            let fileName = entry.name
            let isComponentNameRelated = stridx(fileName, componentNameDot) > -1
            let isMaybeIndexFile = stridx(fileName, 'index.js') > -1 || stridx(fileName, 'index.ts') > -1
            if isComponentNameRelated || isMaybeIndexFile
                call add(siblings, fileName)
            endif
        endif
    endfor

    return siblings
endfunction



function! s:FindIndexFileNameInSiblings(names)
    for name in a:names
        let isMaybeIndexFile = stridx(name, 'index.js') > -1 || stridx(name, 'index.ts') > -1
        if isMaybeIndexFile
            return name
        endif
    endfor
    return ''
endfunction

function! s:FindStyleFileNameInSiblings(names, componentName)
    let componentNameDot = a:componentName . '.'
    for name in a:names
        if stridx(name, componentNameDot) > -1 && s:IsSupportedStyleExtension(name)
            return name
        endif
    endfor
    return ''
endfunction

function! s:FindScriptFileNameInSiblings(names, componentName)
    let componentNameDot = a:componentName . '.'
    for name in a:names
        if stridx(name, componentNameDot) > -1 && s:IsSupportedScriptExtension(name)
            return name
        endif
    endfor
    return ''
endfunction



"@param {string} mainFile
"@return interface ComponentInfo  {
"   isFolderize: 0 | 1
"   componentName: string
"   dirPath: string
"
"   mainFile: string
"   mainFileName: string
"
"   scriptFile: string
"   scriptFileName: string
"
"   styleFile: string
"   styleFileName: string
"
"   indexFile: string
"   indexFileName: string
" }
function! s:GetComponentInfo(mainFile)
    let componentName = s:GetComponentName(a:mainFile)
    let dirPath = fnamemodify(a:mainFile, ':p:h')
    let mainFileName = fnamemodify(a:mainFile, ':t')

    let siblings = s:GetSiblingFileNames(a:mainFile, componentName)

    let isFolderize = s:DetectFolder(a:mainFile)

    let indexFileName =s:FindIndexFileNameInSiblings(siblings)
    let indexFile = empty(indexFileName) ? '' : dirPath . '/' .indexFileName

    let styleFileName = s:FindStyleFileNameInSiblings(siblings, componentName)
    let styleFile = empty(styleFileName) ? '' : dirPath . '/' . styleFileName

    let scriptFileName = s:FindScriptFileNameInSiblings(siblings, componentName)
    let scriptFile = empty(scriptFileName) ? '' : dirPath . '/' . scriptFileName


    let info = {
                \ 'isFolderize': isFolderize,
                \ 'componentName': componentName,
                \ 'dirPath': dirPath,
                \ 'mainFileName': mainFileName,
                \ 'mainFile': a:mainFile,
                \ 'scriptFileName': scriptFileName,
                \ 'scriptFile': scriptFile,
                \ 'styleFileName': styleFileName,
                \ 'styleFile': styleFile,
                \ 'indexFileName': indexFileName,
                \ 'indexFile': indexFile
                \ }

    return info
endfunction

"@param {ComponentInfo} info
"@param {LayoutConfig} layoutConfig
"@interface LayoutConfig {
"   indexFile?: 0 |1
"   scriptFile?: 0 | 1
"   styleFile?: 0 | 1
"   folder?: 0 | 1
"}
function! s:LayoutComponent(info, layoutConfig)
    if exists('*timer_start')
       if s:kit_component_layout_doing
            return
        endif
        let s:kit_component_layout_doing = 1
    else
        echoerr 'Vim does not support timer'
        return
    endif

    let mainFile=get(a:info, 'mainFile', '')
    let scriptFile=get(a:info, 'scriptFile', '')
    let styleFile=get(a:info, 'styleFile', '')
    let isFolderize=get(a:info, 'isFolderize', 0)
    let indexFile=get(a:info, 'indexFile', '')
    let dirPath = get(a:info, 'dirPath', '')

    let layoutFolder = get(a:layoutConfig, 'folder', 0)
    let layoutIndexFile = get(a:layoutConfig, 'indexFile', 0)
    let layoutStyleFile = get(a:layoutConfig, 'styleFile', 0)
    let layoutScriptFile = get(a:layoutConfig, 'scriptFile', 0)

    if layoutStyleFile && strlen(scriptFile) > 0
        execute ':new ' . scriptFile
        execute ':only'
        if layoutStyleFile && strlen(styleFile) > 0
            if isFolderize
                if layoutIndexFile
                    execute ':vnew ' . indexFile
                    execute ':new ' . styleFile
                    execute ':new ' . mainFile
                else
                    execute ':vnew ' . styleFile
                    execute ':new ' . mainFile
                endif
            else
                execute ':vnew ' . styleFile
                execute ':new ' . mainFile
            endif
        else
            execute ':vnew ' . mainFile
        endif
    else
        if layoutStyleFile && strlen(styleFile) > 0
            execute ':new ' . mainFile
            execute ':only'
            if isFolderize
                if layoutIndexFile
                    execute ':vnew ' . indexFile
                    execute ':new ' . styleFile
                else
                    execute ':vnew ' . styleFile
                endif
            else
                execute ':vnew ' . styleFile
            endif
        else
            " echomsg 'There is no script/style file'
            execute ':new ' . mainFile
            execute ':only'
        endif
    endif

    if layoutFolder
        execute ':new ' . dirPath
    endif

    if exists('*timer_start')
        call timer_start(500, 'KitLayoutComponentEnd')
    endif
endfunction

"@param {string} mainFile
"@param {LayoutConfig} layoutConfig
function! s:LayoutComponentByMainFile(mainFile, layoutConfig)
    let info =s:GetComponentInfo(a:mainFile)
    call s:LayoutComponent(info, a:layoutConfig)
endfunction

function! s:FindMainFile(prefix)
    for extension in s:supportMainFileExtensionList
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
    elseif s:IsSupportedMainExtension(a:file)
        if extension ==# 'ts'
            let prefix = fnamemodify(a:file, ':r:r')
            let mainFile = s:FindMainFile(prefix)
        else
            let mainFile = a:file
        endif
    elseif s:IsSupportedStyleExtension(a:file)
        let prefix = fnamemodify(a:file, ':r:r')
        let mainFile = s:FindMainFile(prefix)
    elseif s:IsSupportedScriptExtension(a:file)
        let prefix = fnamemodify(a:file, ':r:r')
        let mainFile = s:FindMainFile(prefix)
    endif

    return mainFile
endfunction

function! s:GetMainFileByCurrent()
    let file = expand('%')
    let mainFile = s:GetMainFileByFile(file)
    return mainFile
endfunction


"@param {LayoutConfig} layoutConfig
function! s:LayoutCurrentComponent(layoutConfig)
    if &diff || s:isDiffMode
        return
    endif

    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) > 0
        call s:LayoutComponentByMainFile(mainFile, a:layoutConfig)
    else
        echomsg 'Can not find main file for current buffer'
    endif
endfunction

function! s:EditCurrentFolder()
    let file = expand('%')
    let folder = fnamemodify(file, ':h')
    execute ':edit ' . folder
endfunction


" @param {ComponentInfo} info
" @param {string} type
function! s:getFileByType(info, type)
    let theFile = ''

    if a:type ==# 'index'
        let theFile = get(a:info, 'indexFile', '')
    elseif a:type ==# 'main'
        let theFile = get(a:info, 'mainFile', '')
    elseif a:type ==# 'style'
        let theFile = get(a:info, 'styleFile', '')
    elseif a:type ==# 'script'
        let theFile = get(a:info, 'scriptFile', '')
    endif

    return theFile
endfunction

" @param {String} mainFile
" @param {String} currentType  valid values: main, style, script, index
function! s:SwitchFile(mainFile, currentType)
    let orderList = ['main', 'script', 'style', 'index']
    let targetFile = ''
    let currentIndex = index(orderList, a:currentType)
    if currentIndex == -1
        return
    endif

    let length = len(orderList)

    let theIndex = currentIndex + 1
    let limit = theIndex + length
    let info = s:GetComponentInfo(a:mainFile)

    while theIndex < limit
        let indexInArray = theIndex % length
        let theType = get(orderList, indexInArray, '')
        let nextFile = s:getFileByType(info, theType)
        if !empty(nextFile)
            let targetFile = nextFile
            break
        endif
        let theIndex += 1
    endwhile

    if strlen(targetFile) > 0
        execute ':e ' targetFile
    else
        echomsg 'Can not find next file for current buffer'
    endif
endfunction

let s:kit_component_switch_file = 0

function! s:SwitchCurrentComponent()
    if exists('*timer_start')
       if s:kit_component_switch_file
            return
        endif
        let s:kit_component_switch_file = 1
    else
        echoerr 'Vim does not support timer'
        return
    endif

    let file = expand('%')

    let mainFile = s:GetMainFileByFile(file)

    let currentType = ''
    if s:IsIndexFile(file)
        let currentType = 'index'
    elseif s:IsSupportedMainExtension(file)
        let currentType = 'main'
    elseif s:IsSupportedStyleExtension(file)
        let currentType = 'style'
    elseif s:IsSupportedScriptExtension(file)
        let currentType = 'script'
    endif

    if strlen(mainFile) > 0
        call s:SwitchFile(mainFile, currentType)
    else
        echomsg 'Can not find main file for current buffer'
    endif

    if exists('*timer_start')
        call timer_start(500, 'KitSwitchFileEnd')
    endif
endfunction

function! s:ResetStatus()
    let s:kit_component_layout_doing = 0
    let s:kit_component_switch_file = 0
endfunction


" function! s:isQuickFixOpened()
    " for index in range(1, winnr('$'))
        " let bnum = winbufnr(index)
        " if getbufvar(bnum, '&buftype') ==# 'quickfix'
            " return 1
        " endif
    " endfor
    " return 0
" endfunction


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
    let layoutConfig = {
                \ 'scriptFile': 1
                \ }

    if a:mode ==# 'folder'
        let layoutConfig.styleFile = 1
        let layoutConfig.indexFile = 1
        let layoutConfig.folder = 1
    elseif a:mode ==# 'all'
        let layoutConfig.styleFile = 1
        let layoutConfig.indexFile = 1
    elseif a:mode ==# 'complex'
        let layoutConfig.styleFile = 1
    elseif a:mode ==# 'simple'
        " do nothing
    endif

    call s:LayoutCurrentComponent(layoutConfig)
endfunction


" @param {string} mode  simple, complex, all, folder
function! s:CompLayoutWithMode(...)
    let mode = a:0 == 0 ? 'simple' : a:1
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

function! s:ComposeFilePath(dirPath, fileName, componentName, newComponentName)
    let newFileName = substitute(a:fileName,  '\<' . a:componentName . '\>\C', a:newComponentName, 'g')
    let newFilePath = a:dirPath . '/' . newFileName
    return newFilePath
endfunction

" @param {ComponentInfo} info
" @param {string} newComponentName
" @param {0|1} bang
" @return {ComponentInfo}
function s:Rename3Files(info, newComponentName, bang)
    let componentName = get(a:info, 'componentName', '')
    let dirPath = get(a:info, 'dirPath', '')

    " echomsg 'Rename3Files info/newComponentName'
    " echomsg json_encode(a:info)
    " echomsg a:newComponentName

    let mainFileName = get(a:info, 'mainFileName', '')
    let mainFile = get(a:info, 'mainFile')

    let mainFileNew = s:ComposeFilePath(dirPath, mainFileName, componentName, a:newComponentName)
    let isRenameOk = s:RenameFile(mainFile, mainFileNew, a:bang)

    if isRenameOk
        call s:UpdateComponentNameInFile(mainFileNew, componentName, a:newComponentName)
    else
        return {}
    endif

    let styleFile = get(a:info, 'styleFile', '')
    let styleFileName = get(a:info, 'styleFileName', '')
    let styleFileNew = ''
    if strlen(styleFile) > 0
        let styleFileNew = s:ComposeFilePath(dirPath, styleFileName, componentName, a:newComponentName)
        let isRenameOk = s:RenameFile(styleFile, styleFileNew, a:bang)
        if isRenameOk
            call s:UpdateComponentNameInFile(styleFileNew, componentName, a:newComponentName)
        endif
    endif

    let scriptFile = get(a:info, 'scriptFile', '')
    let scriptFileName = get(a:info, 'scriptFileName', '')
    let scriptFileNew = ''
    if strlen(scriptFile) > 0
        let scriptFileNew = s:ComposeFilePath(dirPath, scriptFileName, componentName, a:newComponentName)
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

    let newInfo = {
                \ 'isFolderize': a:info.isFolderize,
                \ 'componentName': a:newComponentName,
                \ 'dirPath': dirPath,
                \ 'mainFileName': fnamemodify(mainFileNew, ':t'),
                \ 'mainFile': mainFileNew,
                \ 'scriptFileName': fnamemodify(scriptFileNew, ':t'),
                \ 'scriptFile': scriptFileNew,
                \ 'styleFileName': fnamemodify(styleFileNew, ':t'),
                \ 'styleFile': styleFileNew,
                \ 'indexFileName': a:info.indexFileName,
                \ 'indexFile': a:info.indexFile
                \ }

    return newInfo
endfunction


function! s:RenameComponentWithoutFolder(info, name, bang)
    let newInfo = s:Rename3Files(a:info, a:name, a:bang)
    if !empty(newInfo)
        let layoutConfig = {
                    \ 'scriptFile': 1,
                    \ 'styleFile': 1,
                    \ 'indexFile': 1
                    \ }
        call s:LayoutComponent(newInfo, 1, 1)
    endif
endfunction

" @param {string} indexFile
" @param {string} componentName
" @param {string} newComponentName
" @param {0|1} bang
" @return {0|1}
function s:UpdateIndexFile(indexFile, componentName, newComponentName, bang)
    if empty(a:indexFile)
        echoerr 'Failed to find index file.'
        return 0
    endif

    let readResult = s:ReadFile(a:indexFile)
    if readResult.readSuccess == 0
        echoerr 'Failed to read file: ' . a:indexFile
        return
    endif

    let originalText = get(readResult, 'text', '')
    let newText = substitute(originalText, '\<' . a:componentName . '\>\C', a:newComponentName, 'g')

    let writeOk = s:WriteFile(newText, a:indexFile)
    return writeOk
endfunction

" @param {ComponentInfo} info
" @param {string} newComponentName
" @param {0|1} bang
function! s:RenameComponentWithFolder(info, newComponentName, bang)
    let componentName = get(a:info, 'componentName', '')
    let mainFile = get(a:info, 'mainFile', '')
    let indexFileName = get(a:info, 'indexFileName', '')
    let dirPath = get(a:info, 'dirPath', '')

    let newDirPath = fnamemodify(mainFile, ':p:h:h') . '/' . a:newComponentName
    let renameFolderOk = s:RenameFolderName(dirPath, newDirPath, a:bang)
    if !renameFolderOk
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. mainFile
        return
    endif


    let indexFileAfterDirRename = empty(a:info.indexFileName) ? '' : newDirPath . '/' . a:info.indexFileName
    let infoAfterDirRename = {
                \ 'isFolderize': a:info.isFolderize,
                \ 'componentName': componentName,
                \ 'dirPath': newDirPath,
                \ 'mainFileName': a:info.mainFileName,
                \ 'mainFile': newDirPath . '/' .  a:info.mainFileName,
                \ 'scriptFileName': a:info.scriptFileName,
                \ 'scriptFile': empty(a:info.scriptFileName) ? '' : newDirPath . '/' .  a:info.scriptFileName,
                \ 'styleFileName': a:info.styleFileName,
                \ 'styleFile': empty(a:info.styleFileName) ? '' : newDirPath . '/' .  a:info.styleFileName,
                \ 'indexFileName': a:info.indexFileName,
                \ 'indexFile': indexFileAfterDirRename
                \ }

    let newInfo = s:Rename3Files(infoAfterDirRename, a:newComponentName, a:bang)

    if empty(newInfo)
        echoerr 'Failed to rename component to  ' . a:newComponentName . ' : '. mainFile
        return
    endif

    call s:UpdateIndexFile(indexFileAfterDirRename, componentName, a:newComponentName, a:bang)

    let layoutConfig = {
                \ 'scriptFile': 1,
                \ 'styleFile': 1,
                \ 'indexFile': 1
                \ }
    call s:LayoutComponent(newInfo, layoutConfig)
endfunction


function! s:RenameComponent(name, bang)
    let mainFile = s:GetMainFileByCurrent()
    if strlen(mainFile) <= 0
        echoerr 'Can not find main file for current buffer'
        return
    endif

    let info = s:GetComponentInfo(mainFile)
    let theName = trim(a:name)
    let isFolderize = get(info, 'isFolderize', 0)
    if isFolderize
        call s:RenameComponentWithFolder(info, theName, a:bang)
    else
        call s:RenameComponentWithoutFolder(info, theName, a:bang)
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
" @param {TagInfo[]} tagInfoList
" @interface TagInfo {
"   tagname: string
"   lang: string
" }
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

endfunction

function! s:ChangeExtension(filePath, extension)
    let oldExtension = fnamemodify(a:filePath, ':e')
    let dirPath = fnamemodify(a:filePath, ':p:h')
    let nameWithoutExt = fnamemodify(a:filePath, ':t:r')
    let fileNameNew = nameWithoutExt . '.' . a:extension
    let newFilePath = dirPath . '/' . fileNameNew
    return newFilePath
endfunction

" rename the extension of style/script
" @param {string} extension   js/comp.js/comp.ts
function! s:RenameExtension(extension, bang)

    let mainFile = s:GetMainFileByCurrent()

    if strlen(mainFile) == 0
        echoerr 'Can not find main file for current buffer'
        return
    endif

    let info = s:GetComponentInfo(mainFile)

    let isScript = -1
    let fakeFileName = 'fake.' . a:extension


    if s:IsSupportedStyleExtension(fakeFileName)
        let isScript = 0
    elseif s:IsSupportedScriptExtension(fakeFileName)
        let isScript = 1
    endif

    if isScript == -1
        echomsg 'Can not find style file or script file for current buffer.'
        return
    endif

    let dirPath = get(info, 'dirPath', '')
    let fileName = isScript ? get(info, 'scriptFileName', '') : get(info, 'styleFileName')
    let filePath = isScript ? get(info, 'scriptFile', ''): get(info, 'styleFile', '')

    let nameWithoutExt = fnamemodify(fileName, ':t:r:r')
    let fileNameNew = nameWithoutExt . '.' . a:extension
    let filePathNew = dirPath . '/' . fileNameNew

    let isRenameOk = s:RenameFile(filePath, filePathNew, a:bang)
    if !isRenameOk
        echoerr 'Failed to rename file: ' . filePath
        return
    endif

    let lang = s:GetLang(fakeFileName)
    let tagname = isScript ? 'script' : 'style'
    let tagConfig = {
        \ 'tagname': tagname,
        \ 'lang': lang
        \ }
    let tagInfoList = [tagConfig]
    call s:UpdateHtml(mainFile, fileName, fileNameNew, tagInfoList)

    if isScript
        let indexFile = get(info, 'indexFile', '')
        if !empty(indexFile)
            let lastExt = fnamemodify(fakeFileName, ':e')
            let indexFileNew = s:ChangeExtension(indexFile, lastExt)
            if indexFileNew !=# indexFile
                call s:RenameFile(indexFile, indexFileNew, a:bang)
            endif
        endif
    endif

    let layoutConfig = {
                \ 'scriptFile': 1,
                \ 'styleFile': 1,
                \ 'indexFile': 1
                \ }
    call s:LayoutComponentByMainFile(mainFile, layoutConfig)
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
    let info = s:GetComponentInfo(a:mainFile)
    let isFolderize = get(info, 'isFolderize', 0)

    if isFolderize
        let dirPath = get(info, 'dirPath')
        let result = -1
        if isdirectory(dirPath)
            let result = delete(dirPath, 'rf')
        endif
        if result == -1
            echoerr 'Failed to remove directory: ' . dirPath
        else
            echo 'Success remove component of current buffer.'
        endif
    else
        let scriptFile = get(info, 'scriptFile', '')
        let styleFile =  get(info, 'styleFile', '')

        let removedFileList = []
        call s:RemoveFile(scriptFile, removedFileList)
        call s:RemoveFile(styleFile, removedFileList)
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
        echomsg 'Can not find main file for current buffer.'
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

function! s:BuildIndexFile(indexFile, mainFile, componentName)
    if strlen(a:indexFile) > 0
        let templateDir = s:FindTemplateDirWithType(a:mainFile)
        let mainExtension = fnamemodify(a:mainFile, ':e')
        let fakeConfig = {
                    \ 'componentName': a:componentName,
                    \ 'mainExtension': mainExtension
                    \ }
        call s:CreateAndWriteFile(a:indexFile, templateDir, fakeConfig)
    endif
endfunction

function! s:FolderizeComponentWithMainFile(mainFile)
    let info = s:GetComponentInfo(a:mainFile)
    let isFolderize = get(info, 'isFolderize', 0)

    if isFolderize
        echo 'Component of current buffer is already in folder structure.'
        return
    endif

    let dirPath = get(info, 'dirPath', '')
    let componentName = get(info, 'componentName', '')
    let folderPath = dirPath . '/' . componentName
    let successToCreateFolder = mkdir(folderPath)
    if successToCreateFolder == 0
        echoerr 'Failed to create folder: ' . folderPath
        return
    endif

    let scriptFile = get(info, 'scriptFile', '')
    let styleFile = get(info, 'styleFile', '')
    let movedFileList = []

    call s:MoveFileToFolder(scriptFile, folderPath, movedFileList)
    call s:MoveFileToFolder(styleFile, folderPath, movedFileList)
    call s:MoveFileToFolder(a:mainFile, folderPath, movedFileList)

    if len(movedFileList) > 0
        let mainFileName = get(info, 'mainFileName', '')
        let mainFileNew = folderPath . '/' . mainFileName

        let indexFileExt = s:GetIndexExtension(scriptFile, mainFileName)
        let indexFile = folderPath . '/' . indexFileExt
        call s:BuildIndexFile(indexFile, mainFileNew, componentName)

        let layoutConfig = {
                    \ 'scriptFile': 1,
                    \ 'styleFile': 1,
                    \ 'indexFile': 1
                    \ }
        call s:LayoutComponentByMainFile(mainFileNew, layoutConfig)

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
        echomsg 'Can not find main file for current buffer.'
    endif
endfunction

" @param {string} mode  simple, complex, all, disable, folder
function! s:SetAutoLayout(...)
    if a:0 == 0
        let s:autoLayout = s:auto_layout_default
    else
        let modes = ['simple', 'complex', 'all', 'disable', 'folder']
        if index(modes, a:1) > -1
            let s:autoLayout = a:1
        else
            let s:autoLayout = s:auto_layout_default
        endif
    endif

    call s:CompLayoutWithMode(s:autoLayout)
endfunction

function! KitLayoutAuto(timer)
    " let isOpen =  s:isQuickFixOpened()
    " if isOpen
        " return
    " endif

    call s:DoCompLayoutWithMode(s:autoLayout)
endfunction

function! KitLayoutComponentEnd(timer)
    call s:ResetStatus()
endfunction

function! KitSwitchFileEnd(timer)
    call s:ResetStatus()
endfunction

function! KitLayoutAutoWithDelay()
    if s:autoLayout ==# 'disable'
        return
    endif

    if s:kit_component_layout_doing || s:kit_component_switch_file
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
        autocmd BufReadPost *.vue,*.wpy,*.jsx,*.tsx,*.ts,*.js,*.scss,*.less,*.css  call KitLayoutAutoWithDelay()
    augroup END
endif


let &cpoptions = s:save_cpo


