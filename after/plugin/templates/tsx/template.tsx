/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */

import {
  defineComponent,
  // computed,
  // toRefs,
  // ref,
  // inject,
  // PropType,
} from '@vue/composition-api'
import styles from './ComponentName.module.scss'

export default defineComponent({
  name: 'ComponentName',

  props: {
    // TODO
  },

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
