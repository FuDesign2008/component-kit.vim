# component-kit.vim

> Toolkit for generate/refract/layout component

⚠️ This plugin need `timers` feature (`:has('timers')`) of vim, executing `:help timers` for more.

## Screenshot

![layout](./docs/layout.gif)

## Introduction

A vue/react/other component is composed by:

1. main file: e.g. `ComponentName.vue`/`ComponentName.tsx`
1. script file (optional): e.g. `ComponentName.comp.js`
1. style file (optional): e.g. `ComponentName.comp.css`/`ComponentName.module.css`
1. index file (optional): `index.js`/`index.ts`
1. utils files... (optional)

A component may be organized in a folder, e.g.

```bash
components
    ├── ComponentNameA
    │   ├── ComponentNameA.comp.scss      // style file
    │   ├── ComponentNameA.comp.ts        // script file
    │   ├── ComponentNameA.vue            // main file
    │   └── index.ts                      // index file
    │
    └── ComponentNameB
         ├── ComponentNameB.module.scss    // style file
         ├── ComponentNameB.tsx            // main file
         └── index.ts                      // index file
```

Or be organized without a folder, e.g.

```bash
components
    ├── ComponentNameA.comp.scss       // style file
    ├── ComponentNameA.comp.ts         // script file
    ├── ComponentNameA.vue             // main file
    ├── ComponentNameB.module.scss     // style file
    └── ComponentNameB.tsx             // main file

```

## Commands

| command arguments           | main        | script          | style               | index(`CompCreateFolder`) |
| :-------------------------- | :---------- | :-------------- | :------------------ | :------------------------ |
| path/to/Example.wpy         | Example.wpy | Example.comp.js | Example.comp.css    | index.js                  |
| path/to/Example.vue         | Example.vue | Example.comp.js | Example.comp.css    | index.js                  |
| path/to/Example.vue ts      | Example.vue | Example.comp.ts | Example.comp.css    | index.ts                  |
| path/to/Example.vue ts scss | Example.vue | Example.comp.ts | Example.comp.scss   | index.ts                  |
| path/to/Example.jsx         | Example.jsx | -               | Example.module.css  | index.js                  |
| path/to/Example.jsx scss    | Example.jsx | -               | Example.module.scss | index.js                  |
| path/to/Example.tsx         | Example.tsx | -               | Example.module.css  | index.ts                  |
| path/to/Example.tsx scss    | Example.tsx | -               | Example.module.scss | index.ts                  |
| path/to/Example.ts          | Example.ts  | -               | Example.module.css  | index.ts                  |
| path/to/Example.ts scss     | Example.ts  | -               | Example.module.scss | index.ts                  |

1. `CompCreate`: create vue component files
    - syntax `:CompCreate ./path/to/ComponentName.[main-extension] [script-extension]? [style-extension]?`
    - create main/script(optional)/style files
1. `CompCreateFolder`: like `CompCreate`, create all files under `path/to/ComponentName` folder
    - create main/script(optional)/style/index files
1. `CompLayout simple/complex/all/folder`: close all windows and layout complonent files.
1. `CompLayoutAuto simple/complex/all/folder/disable`: set auto layout when opening files
1. `CompAlt`: switch `main file` -> `script file` (optional) -> `style file` (optional) -> `index file` (optional) -> `main file` -> ...
1. `CompReset`: reset the status of the plugin
1. `CompRename`: rename all files of a vue component, and change style/script file path in template file
    - `CompRename NewName` will rename vue/style/script file to `NewName.vue`, `NewName.comp.css`, `NewName.comp.js`
1. `CompRenameExt`: rename the extension of style/script file, and change style/script file path in template file
1. `CompRemove`: remove all files of the component of current buffer
1. `CompFolderize`: change current component to folder structure

### `:CompLayout`/`:CompLayoutAuto`

A component is composed by:

1. main file
1. script file (optional)
1. style file (optional)
1. index file (optional)
1. utils files... (optional)

-   `folder` = the component folder
-   `all` = `1 + 2 + 3 + 4` (default value)
-   `complex` = `1 + 2 +3`
-   `simple` = `1 + 2`

```

 // :CompLayout all
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

 // :CompLayout complex
-----------------
| .vue  |       |
|       |       |
|-------|  .js  |
| .css  |       |
|       |       |
-----------------


 // :CompLayout simple
-----------------
|       |       |
|       |       |
| .vue  |  .js  |
|       |       |
|       |       |
-----------------


```

## Config

1.  `g:kit_component_middle_name`: The middle name for creating & finding script/style file, default is `{ 'vue': 'comp', 'wpy': 'comp', 'jsx': 'module', 'tsx': 'module' }`
1.  `g:kit_component_script_extension`: The extension for creating & finding script file, default is `'js'`
1.  `g:kit_component_css_extension`: The extension for creating & finding style file, default is `'css'`
1.  `g:kit_component_template_dir`: The template directory for creating component ( @see `:CompCreate` command ), `template.js` for `.js`, `template.vue` for `.vue`, and so on. - If `g:kit_component_template_dir` is equal `built-in`, the plugin will use template files in this plugin - If `g:kit_component_template_dir` is not set, the plugin will find `.kit-component-template` directory up util home (`~`) - The word `ComponentName`/`component-name` in template files will be replaced by true component name - The word `MAIN_EXTENSION/STYLE_EXTENSION`/`SCRIPT_EXTENSION` in template files will be replaced by vue/style/script extension for creating
1.  `g:kit_component_auto_layout`: Call `:CompLayout` automatically when opening `*.vue`/`*.wpy` or `index.js/index.ts` files, only support if vim (8.0+) has `timer_start` command, see `:help timer_start`
    -   If the value is `disable`, no command will be called
    -   If the value is `simple`, command `:CompLayout simple` will be called
    -   If the value is `complex`, command `:CompLayout complex` will be called
    -   If the value is `all`, command `:CompLayout all` will be called
    -   If the value is `folder`, command `:CompLayout folder` will be called

## Support

This toolkit supports component like:

1. [Vue](https://vuejs.org/)
1. [wepy](https://github.com/Tencent/wepy)
1. [React](https://reactjs.org/docs/react-component.html)
