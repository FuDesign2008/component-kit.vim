# vue-component.vim

Tools for vue-like component

## Config

1. `g:vue_component_middle_name`: The middle name for creating & finding script/css file, default is `'comp'`
1. `g:vue_component_script_extension`: The extention for creating & finding script file, default is `'js'`
1. `g:vue_component_css_extension`: The extention for creating & finding css file, default is `'css'`

## Commands

1. `VueCreate`: create vue component files
    - `VueCreate Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css` files
    - `VueCreate Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css` files
1. `VueLayout`: close all windows and layout all component files.
1. `VueLay`: close all windows and layout vue and script files.
1. `VueAlt`: switch vue -> css -> script -> vue ... file

```

 // :VueLayout
-----------------
| .vue  |       |
|       |       |
|-------|  .js  |
| .css  |       |
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

## Next

1. add snippets for `.vue`/`.js`/`.css` files

    - `g:vue_component_template_dir`, find `template.js` for `.js`, `template.vue` for `.vue`, ...
    - if `g:vue_component_template_dir` is not set, find
    - `vue-component-template` folder from project root
    - `vue-component-template` from current directory
    - `vue-component-template` from home(`~`)
    - templates from plugin itself
