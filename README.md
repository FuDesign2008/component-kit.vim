# component-kit.vim

Tools for generate/refract component

## Config

1. `g:vue_component_middle_name`: The middle name for creating & finding script/css file, default is `'comp'`
1. `g:vue_component_script_extension`: The extention for creating & finding script file, default is `'js'`
1. `g:vue_component_css_extension`: The extention for creating & finding css file, default is `'css'`
1. `g:vue_component_template_dir`: The template directory for creating component ( @see `:CompCreate` command ), `template.js` for `.js`, `template.vue` for `.vue`, and so on.
    - If `g:vue_component_template_dir` is equal `built-in`, the plugin will use template files in this plugin
    - If `g:vue_component_template_dir` is not set, the plugin will find `.vue-component-template` directory up util home (`~`)
    - The word `ComponentName`/`component-name` in template files will be replaced by true component name

## Commands

1. `CompCreate`: create component files
    - `:CompCreate path/to/Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css` files under `path/to` folder
    - `:CompCreate path/to/Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css` files under `path/to` folder
    - `:CompCreate path/to/Example.jsx` will create `Example.jsx`, `Example.module.css` files under `path/to` folder
1. `CompCreateFolder`: create component files under a folder
    - `:CompCreate path/to/Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css`, `index.js` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css`, `index.js` files under `path/to/Example` folder
    - `:CompCreate path/to/Example.jsx` will create `Example.jsx`, `Example.module.css`, `index.js` files under `path/to/Example` folder
1. `CompFolderlize`
1. `CompLayout`: close all windows and layout all component files.
1. `CompLay`: close all windows and layout template file and script files.
1. `CompAlt`: switch `template file (if has)` -> `style file` -> `script file` -> `template file (if has)` ...

```

 // :CompLayout
-----------------
| .vue  |       |
|       |       |
|-------|  .js  |
| .css  |       |
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
