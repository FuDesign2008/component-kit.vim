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

" @return {String}
function! s:findTemplateFile(file, templateDir)
    if strlen(a:templateDir) == 0
        return ''
    endif

    let extension = fnamemodify(a:file, ':e')
    let templateFileName = 'template.' . extension
    let templateFile = a:templateDir . '/' . templateFileName

    if filereadable(templateFile)
        return templateFile
    endif

    return ''
endfunction

function! s:CreateAndSaveFile(filePath, templateDir, componentName, componentNameCamel, scriptExtension, styleExtension)
    let templateFilePath = s:findTemplateFile(a:filePath, a:templateDir)

    execute ':enew'
    if strlen(templateFilePath) > 0
        execute ':e ' . templateFilePath
        execute ':%s/ComponentName/' . a:componentName . '/ge'
        execute ':%s/component-name/' . a:componentNameCamel . '/ge'
        execute ':%s/STYLE_EXTENSION/' . a:styleExtension . '/ge'
        execute ':%s/SCRIPT_EXTENSION/' . a:scriptExtension . '/ge'
    endif
    execute ':saveas ' . a:filePath
    " execute ':quit'
endfunction


function! s:makeCssFile(vueFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:styleExtension
    endif
    let cssFile = fnamemodify(a:vueFile, ':r') . '.' . s:middleName .'.' . theExtension
    return cssFile
endfunction

function! s:makeScriptFile(vueFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:scriptExtension
    endif
    let scriptFile = fnamemodify(a:vueFile, ':r') . '.' . s:middleName . '.' . theExtension
    return scriptFile
endfunction

function! s:makeCssFileList(vueFile)
    let fileList = []
    for extension in s:supportCssExtensionList
        let file = s:makeCssFile(a:vueFile, extension)
        call add(fileList, file)
    endfor
    return fileList
endfunction

function! s:makeScriptFileList(vueFile)
    let fileList = []
    for extension in s:supportScriptExtensionList
        let file = s:makeScriptFile(a:vueFile, extension)
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
function! s:findTemplateDir()
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


" @param {String} vueFile
" @param {String} [scriptExtension]
" @param {String} [styleExtension]
" function! s:CreateComponent(vueFile, scriptExtension, styleExtension)
function! s:CreateComponent(...)
    let argsCount = a:0
    let vueFile = a:1

    let scriptExtension = s:scriptExtension
    if argsCount >= 2 && strlen(a:2) > 1
        let scriptExtension = a:2
    endif

    let styleExtension =  s:styleExtension
    if argsCount >= 3 && strlen(a:3) > 1
        let styleExtension = a:3
    endif

    let scriptFile = s:makeScriptFile(vueFile, scriptExtension)
    let cssFile = s:makeCssFile(vueFile, styleExtension)
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

    let templateDir = s:findTemplateDir()

    let componentName = fnamemodify(vueFile, ':t:r')
    let componentNameCamel = substitute(componentName, '\C[A-Z]',
        \ '\= "-" . tolower(submatch(0))',
        \ 'g')
    let componentNameCamel = substitute(componentNameCamel, '^-', '', '')

    for theFile in fileList
        call s:CreateAndSaveFile(theFile, templateDir, componentName, componentNameCamel, scriptExtension, styleExtension)
    endfor

    call s:LayoutComponent(vueFile, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

function! s:FindScriptFile(vueFile)
    let fileList = s:makeScriptFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction

function! s:FindStyleFile(vueFile)
    let fileList = s:makeCssFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return ''
endfunction


function! s:LayoutComponent(vueFile, includeCss)
    if exists('*timer_start')
       if s:vue_component_layout_doing
            return
        endif
        let s:vue_component_layout_doing = 1
    endif

    let scriptFile = s:FindScriptFile(a:vueFile)
    let cssFile = s:FindStyleFile(a:vueFile)

    if strlen(scriptFile) > 0
        execute ':new ' . scriptFile
        execute ':only'
        if a:includeCss && strlen(cssFile) > 0
            execute ':vnew ' . cssFile
            execute ':new ' . a:vueFile
        else
            execute ':vnew ' . a:vueFile
        endif
    else
        if a:includeCss && strlen(cssFile) > 0
            execute ':new ' . cssFile
            execute ':only'
            execute ':vnew ' . a:vueFile
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

function! s:GetVueFileByCurrent()
    let file = expand('%')
    let extension = fnamemodify(file, ':e')

    let vueFile = ''

    if index(s:supportVueExtensionList, extension) > -1
        let vueFile = file
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let vueFile = s:FindVueFile(cssFileWithoutMiddle)
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let vueFile = s:FindVueFile(scriptFileWithoutMiddle)
    endif

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

" @param {String} vueFile
" @param {String} targetType  valid values: vue, css, script
function! s:SwitchFile(vueFile, targetType)
    let targetFile = ''
    if a:targetType ==# 'vue'
        let targetFile = a:vueFile
    elseif a:targetType ==# 'css'
        let targetFile = s:FindStyleFile(a:vueFile)
    elseif a:targetType ==# 'script'
        let targetFile = s:FindScriptFile(a:vueFile)
    endif

    if strlen(targetFile) > 0
        execute ':e ' targetFile
    else
        echoerr 'Can not find '. a:targetType . 'for current buffer'
    endif
endfunction


function! s:SwitchCurrentComponent()
    let file = expand('%')
    let extension = fnamemodify(file, ':e')

    let vueFile = ''
    let targetType = ''

    if index(s:supportVueExtensionList, extension) > -1
        let vueFile = file
        let targetType = 'css'
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let vueFile = s:FindVueFile(cssFileWithoutMiddle)
        let targetType = 'script'
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let vueFile = s:FindVueFile(scriptFileWithoutMiddle)
        let targetType = 'vue'
    endif

    if strlen(vueFile) > 0
        call s:SwitchFile(vueFile, targetType)
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
        echoerr ':VueRename need the suppport of `mv` shell command'
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

function! s:GetComponentName(vueFile)
    let name = fnamemodify(a:vueFile, ':t:r')
    return name
endfunction

function! s:ComposeFilePath(filePath, componentName, newComponentName)
    let path = fnamemodify(a:filePath, ':p:h')
    let fileName = fnamemodify(a:filePath, ':t')
    let newFileName = substitute(fileName, a:componentName, a:newComponentName)
    let newFilePath = path . '/' . newFileName
    return newFilePath
endfunction

function! s:RenameComponent(name, bang)
    let vueFile = s:GetVueFileByCurrent()
    if strlen(vueFile) <= 0
        echoerr 'Can not find vue file for current buffer'
        return
    endif

    let componentName = s:GetComponentName(vueFile)
    let vueFileNew = s:ComposeFilePath(vueFile, componentName, a:name)
    let isRenameOk = s:RenameFile(vueFile, vueFileNew, a:bang)

    if isRenameOk == 0
        return
    endif

    let styleFile = s:FindStyleFile(vueFile)
    if strlen(styleFile) > 0
        let styleFileNew = s:ComposeFilePath(styleFile, componentName, a:name)
        call s:RenameFile(styleFile, styleFileNew, a:bang)
    endif

    let scriptFile = s:FindScriptFile(vueFile)
    if strlen(scriptFile) > 0
        let scriptFileNew = s:ComposeFilePath(scriptFile, componentName, a:name)
        call s:RenameFile(scriptFile, scriptFileNew, a:bang)
    endif

    let styleConfig = {
        \ 'tagname': 'style',
        \}
    let scriptConfig = {
        \ 'tagname': 'script',
        \}
    let tagInfoList = [styleConfig, scriptConfig]
    call s:UpdateHtml(vueFileNew, componentName, a:name, tagInfoList)
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
                    if has_key(langDict, nodeTagName) && !empty(langNode)
                        let lang = get(langDict, nodeTagName, '')
                        let langNode['value'] = lang
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

    call s:LayoutComponent(a:filePath, 1)
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
    let trimedInner = substitute(innerContent, '\\n', '', 'g')
    let trimedInner = trim(trimedInner)

    if strlen(trimedInner) > 0
        let html = '<' . tagname  . attrHtml . '>' . innerContent . '</'. tagname .'>'
    else
        let html = '<' . tagname  . attrHtml . '/>'
    endif

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
    let startIndex = startTokenIndex + startTokenLen
    let endIndex = -1

    if a:endToken == s:generalEndToken
        let endIndex = stridx(a:html, a:endToken, startIndex)
    else
        let endMark = '>'
        let endIndex = stridx(a:html, endMark, startIndex)
        if endIndex > -1
            let needleStart = endIndex + strlen(endMark)
            let endTokenIndex = stridx(a:html, a:endToken, needleStart)
            if endTokenIndex > -1
                let innerContentLength = endTokenIndex - needleStart
                let innerContent = strpart(a:html, needleStart, innerContentLength)
                let node['innerContent'] = innerContent
            endif
        endif
    endif

    let htmlWithAttrs = strpart(a:html, startIndex, endIndex - startIndex)
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
    let startTokenWithSpace = startToken . ' '
    let startTokenWithEndLine  = startToken . '\n'
    let realStartToken = ''
    let endToken = '</' . a:tagname .'>'
    let realEndToken = ''

    let needleIndex = 0
    let len = strlen(a:html)
    let nodeList = []

    while needleIndex < len
        let startIndex = stridx(a:html, startTokenWithSpace, needleIndex)
        " echomsg 'startTokenWithSpace: ' . startTokenWithSpace
        let realStartToken = startTokenWithSpace
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
    augroup END
endif


let &cpoptions = s:save_cpo


