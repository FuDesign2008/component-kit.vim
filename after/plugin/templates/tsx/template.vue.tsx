import {
  defineComponent,
  // computed,
  // toRefs,
  // ref,
  // inject,
  // PropType,
} from '@vue/composition-api'
import styles from './ComponentName.module.scss'

export const ComponentName = defineComponent({
  name: 'ComponentName',

  // emits: { },

  // props: { },

  setup(/*props, context*/) {
    // TODO
    return {
      // TODO
      /** public data or methods **/
      // TODO
    }
  },

  render() {
    // TODO
    return (
      <div
        class={{
          'component-name': true,
          [styles.componentName]: true,
        }}
      >
        // TODO
      </div>
    )
  },
})
