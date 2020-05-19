# component-kit.vim

Tools for generate/refract component

## Config

1.  `g:vue_component_middle_name`: The middle name for creating & finding script/style file, default is `'comp'`
1.  `g:vue_component_script_extension`: The extension for creating & finding script file, default is `'js'`
1.  `g:vue_component_css_extension`: The extension for creating & finding style file, default is `'css'`
1.  `g:vue_component_template_dir`: The template directory for creating component ( @see `:CompCreate` command ), `template.js` for `.js`, `template.vue` for `.vue`, and so on. - If `g:vue_component_template_dir` is equal `built-in`, the plugin will use template files in this plugin - If `g:vue_component_template_dir` is not set, the plugin will find `.vue-component-template` directory up util home (`~`) - The word `ComponentName`/`component-name` in template files will be replaced by true component name - The word `VUE_EXTENSION/STYLE_EXTENSION`/`SCRIPT_EXTENSION` in template files will be replaced by vue/style/script extension for creating
1.  `g:vue_component_auto_layout`: Call `:CompLay` / `:CompLayout` automatically when opening `*.vue`/`*.wpy` or `index.js/index.ts` files, only support if vim (8.0+) has `timer_start` command, see `:help timer_start`
    -   If the value is `0`, no command will be called
    -   If the value is `1`, command `:CompLay` will be called
    -   If the value is `2`, command `:CompLayout` will be called

## Commands

1. `CompCreate`: create vue component files, syntax `:CompCreate ./path/to/ComponentName.[extension] [script extension]? [style extension]?`
    - `:CompCreate path/to/Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css` files under `path/to` folder
    - `:CompCreate path/to/Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css` files under `path/to` folder
    - `:CompCreate path/to/Example.vue ts` will create `Example.vue`, `Example.comp.ts`, `Example.comp.css` files
    - `:CompCreate path/to/Example.vue ts scss` will create `Example.vue`, 'Example.comp.ts', `Example.comp.scss` files
    - `:CompCreate path/to/Example.jsx` will create `Example.jsx`, `Example.module.css` files under `path/to` folder
    - `:CompCreate path/to/Example.tsx scss` will create `Example.tsx`, `Example.module.scss` files under `path/to` folder
1. `CompCreateFolder`: like `CompCreate`, create all files under a folder
    - `:CompCreate path/to/Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css`, `index.js` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css`, `index.js` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.vue ts` will create `index.ts`, `Example.vue`, `Example.comp.ts`, `Example.comp.css` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.vue scss` will create `index.ts`, `Example.vue`, `Example.comp.ts`, `Example.comp.scss` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.jsx` will create `Example.jsx`, `Example.module.css`, `index.js` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.tsx scss` will create `Example.jsx`, `Example.module.scss`, `index.ts` files under `path/to/Example` folder
1. `CompLayout`: close all windows and layout all component files.
1. `CompLay`: close all windows and layout vue and script files.
1. `CompAlt`: switch index -> template (if has) -> style -> script -> index -> template (if has) ... file
1. `CompReset`: reset the status of the plugin
1. `CompRename`: rename all files of a vue component, and change style/script file path in template file
    - `CompRename NewName` will rename vue/style/script file to `NewName.vue`, `NewName.comp.css`, `NewName.comp.js`
1. `CompRenameExt`: rename the extension of style/script file, and change style/script file path in template file
1. `CompRemove`: remove all files of the component of current buffer
1. `CompFolderize`: change current component to folder structure

```

 // :CompLayout
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


 // :CompLay
-----------------
|       |       |
|       |       |
| .vue  |  .js  |
|       |       |
|       |       |
-----------------


```

## Support

This toolkit supports component like:

1. [Vue](https://vuejs.org/)
1. [wepy](https://github.com/Tencent/wepy)
1. [React](https://reactjs.org/docs/react-component.html)

## TODO

1. 增加对 react 的支持
1. 分层
    - `component-kit`: npm 包，支持命令行处理
    - `component-kit.vim`: vim 编辑器支持
    - `component-kit-vsc`: vs code 编辑器支持
