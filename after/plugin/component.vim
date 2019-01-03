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


function! s:CreateAndSaveFile(filePath)
    execute ':enew'
    execute ':saveas ' . a:filePath
    execute ':quit'
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

function! s:CreateComponent(vueFile)
    let scriptFile = s:makeScriptFile(a:vueFile, '')
    let cssFile = s:makeCssFile(a:vueFile, '')
    let fileList = [a:vueFile, scriptFile, cssFile]

    for theFile in fileList
        if filereadable(theFile)
            echoerr theFile . 'does exist!'
            return
        endif
    endfor

    let targetDir = fnamemodify(a:vueFile, ':p:h')
    if !isdirectory(targetDir)
        call mkdir(targetDir, 'p')
    endif

    for theFile in fileList
        call s:CreateAndSaveFile(theFile)
    endfor

    call s:LayoutComponent(a:vueFile)
    echomsg 'Success to create ' . join(fileList, ', ')
endfunction

function! s:getScriptFile(vueFile)
    let fileList = s:makeScriptFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return get(fileList, 0, '')
endfunction

function! s:getCssFile(vueFile)
    let fileList = s:makeCssFileList(a:vueFile)
    for theFile in fileList
        if filereadable(theFile)
            return theFile
        endif
    endfor
    return get(fileList, 0, '')
endfunction



function! s:LayoutComponent(vueFile)
    let scriptFile = s:getScriptFile(a:vueFile)
    let cssFile = s:getCssFile(a:vueFile)
    let fileList = [a:vueFile, scriptFile, cssFile]

    for theFile in fileList
        if !filereadable(theFile)
            echoerr  theFile . ' is not readable'
            return
        endif
    endfor

    execute ':new ' . scriptFile
    execute ':only'
    execute ':vnew ' . cssFile
    execute ':new ' . a:vueFile

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
    let lower = tolower(extension)

    let vueFile = ''

    if index(s:supportVueExtensionList, extension)
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
        call s:LayoutComponent(vueFile)
    else
        echoerr 'Can not find vue file for current buffer'
    endif
endfunction

command! -nargs=1 -complete=file VueCreate call s:CreateComponent(<f-args>)
command! VueLayout call s:LayoutCurrentComponent()

let &cpoptions = s:save_cpo


