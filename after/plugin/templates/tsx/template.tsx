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
import classnames from 'classnames'

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
        class={classnames('component-name', styles.componentName)}
      >
        // TODO
      </div>
    )
  },
})
