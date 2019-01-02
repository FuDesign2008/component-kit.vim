# vue-component.vim

Tools for vue-like component

## Config

1. `g:vue_component_middle_name`: The middle name for creating & finding script/css file, default is `'comp'`
1. `g:vue_component_script_extension`: The extention for creating & finding script file, default is `'js'`
1. `g:vue_component_css_extension`: The extention for creating & finding css file, default is `'css'`

## Commands

1. `VueLayout`: layout vue component files like `ComponentName.vue`, `ComponentName.comp.js`, `ComponentName.comp.css`
1. `VueCreate`: create vue component files, e.g.
    - `VueCreate Example.vue` will create `Example.vue`, `Example.comp.js`, `Example.comp.css` files
    - `VueCreate Example.wpy` will create `Example.wpy`, `Example.comp.js`, `Example.comp.css` files

## Support

1. [Vue](https://vuejs.org/)
1. [wepy](https://github.com/Tencent/wepy)
