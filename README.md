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
1. `VueLayout`: close all windows and layout vue component files.

```

 // :VueLayout
-----------------
| .vue  |       |
|       |       |
|-------|  .js  |
| .css  |       |
|       |       |
-----------------

```

## Support

This toolkit supports vue-like component:

1. [Vue](https://vuejs.org/)
1. [wepy](https://github.com/Tencent/wepy)

## Next

1. add snippets for `.vue`/`.js`/`.css` files
1. add commands
    - `VueLay`: close all windows and layout vue component files.
    - `VueAlt`: switch vue -> css -> script file

```

 // :VueLay

-----------------
|       |       |
|       |       |
| .vue  |  .js  |
|       |       |
|       |       |
-----------------

```
