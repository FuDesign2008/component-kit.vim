# vue-component.vim

Tools for vue-like component

## Config

1. `g:vue_component_middle_name`: The middle name for creating & finding script/style file, default is `'comp'`
1. `g:vue_component_script_extension`: The extension for creating & finding script file, default is `'js'`
1. `g:vue_component_css_extension`: The extension for creating & finding style file, default is `'css'`
1. `g:vue_component_template_dir`: The template directory for creating component ( @see `:VueCreate` command ), `template.js` for `.js`, `template.vue` for `.vue`, and so on.
    - If `g:vue_component_template_dir` is equal `built-in`, the plugin will use template files in this plugin
    - If `g:vue_component_template_dir` is not set, the plugin will find `.vue-component-template` directory up util home (`~`)
    - The word `ComponentName`/`component-name` in template files will be replaced by true component name
    - The word `VUE_EXTENSION/STYLE_EXTENSION`/`SCRIPT_EXTENSION` in template files will be replaced by vue/style/script extension for creating
1. `g:vue_component_auto_layout`: Call `:VueLay` / `:VueLayout` automatically when opening `*.vue`/`*.wpy` or `index.js/index.ts` files, only support if vim (8.0+) has `timer_start` command, see `:help timer_start`
    - If the value is `0`, no command will be called
    - If the value is `1`, command `:VueLay` will be called
    - If the value is `2`, command `:VueLayout` will be called

## Commands

1. `VueCreate`: create vue component files, syntax `VueCreate ./path/ComponentName.[extension] [script extension] [style extension]`
    - `VueCreate Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css` files
    - `VueCreate Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css` files
    - `VueCreate Example.vue ts` will create `Example.vue`, 'Example.comp.ts', `Example.comp.css` files
    - `VueCreate Example.vue ts scss` will create `Example.vue`, 'Example.comp.ts', `Example.comp.scss` files
1. `VueCreateFolder`: like `VueCreate`, create all files under a folder
    - `VueCreate Example.vue` will create`Example/index.js`, `Example/Example.vue`, `Example/Example.comp.js`, `Example/Example.comp.css` files
    - `VueCreate Example.wpy` will create `Example/index.js`, `Example/Example.wpy`, `Example/Example.comp.js`, `Example/Example.comp.css` files
    - `VueCreate Example.vue ts` will create `Example/index.ts`, `Example/Example.vue`, 'Example/Example.comp.ts', `Example/Example.comp.css` files
    - `VueCreate Example.vue ts scss` will create `Example/index.ts`, `Example/Example.vue`, 'Example/Example.comp.ts', `Example/Example.comp.scss` files
1. `VueLayout`: close all windows and layout all component files.
1. `VueLay`: close all windows and layout vue and script files.
1. `VueAlt`: switch index -> vue -> style -> script -> index -> vue ... file
1. `VueReset`: reset the status of the plugin
1. `VueRename`: rename all files of a vue component, and change style/script file path in template file
    - `VueRename NewName` will rename vue/style/script file to `NewName.vue`, `NewName.comp.css`, `NewName.comp.js`
1. `VueRenameExt`: rename the extension of style/script file, and change style/script file path in template file
1. `VueRemove`: remove all files of the component of current buffer
1. `VueFolderize`: change current component to folder structure

```

 // :VueLayout
-----------------
| .vue  |       |
|       |       |
|-------|  .js  |
| .css  |       |
|       |       |
-----------------

 // :VueLayout
-----------------
| .vue  |       |
|       |       |
|-------|  .js  |
| .css  |       |
|       |       |
|-------|       |
| index |       |
|       |       |
-----------------


 // :VueLay
-----------------
|       |       |
|       |       |
| .vue  |  .js  |
|       |       |
|       |       |
-----------------


```

## Support

This toolkit supports vue-like component:

1. [Vue](https://vuejs.org/)
1. [wepy](https://github.com/Tencent/wepy)
