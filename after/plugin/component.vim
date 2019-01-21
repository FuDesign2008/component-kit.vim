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

let s:vue_component = 1

" use when creating  and finding component files
let s:middleName = 'comp'

" only use when creating component files
let s:scriptExtension = 'js'
let s:cssExtension = 'css'

" only use when finding component files
"
" wpy is used for https://github.com/Tencent/wepy
let s:supportVueExtensionList = ['vue', 'wpy']
let s:supportScriptExtensionList = [ 'js', 'ts', 'jsx', 'json']
let s:supportCssExtensionList = ['css', 'scss', 'less']

if exists('g:vue_component_middle_name') && strlen(g:vue_component_middle_name) > 0
    let s:middleName = g:vue_component_middle_name
endif

if exists('g:vue_component_script_extension') && strlen(g:vue_component_script_extension) > 0
    let s:scriptExtension = g:vue_component_script_extension
endif

if exists('g:vue_component_css_extension') && strlen(g:vue_component_css_extension) > 0
    let s:cssExtension = g:vue_component_css_extension
endif

if index(s:supportScriptExtensionList, s:scriptExtension) == -1
    call add(s:supportScriptExtensionList, s:scriptExtension)
endif

if index(s:supportCssExtensionList, s:cssExtension) == -1
    call add(s:supportCssExtensionList, s:cssExtension)
endif

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

function! s:CreateAndSaveFile(filePath, templateDir, componentName, componentNameCamel)
    let templateFilePath = s:findTemplateFile(a:filePath, a:templateDir)

    execute ':enew'
    if strlen(templateFilePath) > 0
        execute ':e ' . templateFilePath
        execute ':%s/ComponentName/' . a:componentName . '/ge'
        execute ':%s/component-name/' . a:componentNameCamel . '/ge'
    endif
    execute ':saveas ' . a:filePath
    " execute ':quit'
endfunction


function! s:makeCssFile(vueFile, extension)
    let theExtension = a:extension
    if theExtension ==# ''
        let theExtension = s:cssExtension
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


function! s:CreateComponent(vueFile)
    let scriptFile = s:makeScriptFile(a:vueFile, '')
    let cssFile = s:makeCssFile(a:vueFile, '')
    let fileList = [a:vueFile, scriptFile, cssFile]

    for theFile in fileList
        if filereadable(theFile)
            echoerr theFile . ' does exist!'
            return
        endif
    endfor

    let targetDir = fnamemodify(a:vueFile, ':p:h')
    if !isdirectory(targetDir)
        call mkdir(targetDir, 'p')
    endif

    let templateDir = s:findTemplateDir()

    let componentName = fnamemodify(a:vueFile, ':t:r')
    let componentNameCamel = substitute(componentName, '\C[A-Z]',
        \ '\= "-" . tolower(submatch(0))',
        \ 'g')
    let componentNameCamel = substitute(componentNameCamel, '^-', '', '')

    for theFile in fileList
        call s:CreateAndSaveFile(theFile, templateDir, componentName, componentNameCamel)
    endfor

    call s:LayoutComponent(a:vueFile, 1)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

function! s:findScriptFile(vueFile)
    let fileList = s:makeScriptFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return get(fileList, 0, '')
endfunction

function! s:findCssFile(vueFile)
    let fileList = s:makeCssFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return get(fileList, 0, '')
endfunction



function! s:LayoutComponent(vueFile, includeCss)
    let scriptFile = s:findScriptFile(a:vueFile)
    let cssFile = s:findCssFile(a:vueFile)

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
            execute ':new ' . a:vueFile
            execute ':only'
        endif
    endif
endfunction

function! s:findVueFile(prefix)
    for extension in s:supportVueExtensionList
        let file = a:prefix . '.' . extension
        if filereadable(file)
            return file
        endif
    endfor
    return ''
endfunction


function! s:LayoutCurrentComponent()
    let file = expand('%')
    let extension = fnamemodify(file, ':e')

    let vueFile = ''

    if index(s:supportVueExtensionList, extension) > -1
        let vueFile = file
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let vueFile = s:findVueFile(cssFileWithoutMiddle)
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let vueFile = s:findVueFile(scriptFileWithoutMiddle)
    endif

    if strlen(vueFile) > 0
        call s:LayoutComponent(vueFile, 1)
    else
        echoerr 'Can not find vue file for current buffer'
    endif
endfunction

function! s:LayoutVueAndScript()
    let file = expand('%')
    let extension = fnamemodify(file, ':e')

    let vueFile = ''

    if index(s:supportVueExtensionList, extension) > -1
        let vueFile = file
    elseif index(s:supportCssExtensionList, extension) > -1
        let cssFile = fnamemodify(file, ':r')
        let cssFileWithoutMiddle = fnamemodify(cssFile, ':r')
        let vueFile = s:findVueFile(cssFileWithoutMiddle)
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let vueFile = s:findVueFile(scriptFileWithoutMiddle)
    endif

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
        let targetFile = s:findCssFile(a:vueFile)
    elseif a:targetType ==# 'script'
        let targetFile = s:findScriptFile(a:vueFile)
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
        let vueFile = s:findVueFile(cssFileWithoutMiddle)
        let targetType = 'script'
    elseif index(s:supportScriptExtensionList, extension) > -1
        let scriptFile = fnamemodify(file, ':r')
        let scriptFileWithoutMiddle = fnamemodify(scriptFile, ':r')
        let vueFile = s:findVueFile(scriptFileWithoutMiddle)
        let targetType = 'vue'
    endif

    if strlen(vueFile) > 0
        call s:SwitchFile(vueFile, targetType)
    else
        echoerr 'Can not find vue file for current buffer'
    endif
endfunction

command! -nargs=1 -complete=file VueCreate call s:CreateComponent(<f-args>)
command! VueLayout call s:LayoutCurrentComponent()
command! VueLay call s:LayoutVueAndScript()
command! VueAlt call s:SwitchCurrentComponent()

let &cpoptions = s:save_cpo


