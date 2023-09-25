import styles from './ComponentName.module.scss'
import classnames from 'classnames'

export const ComponentName = () => {
  return (
    <div className={classnames('component-name', styles.componentName)}>
      组件 ComponentName 待实现
    </div>
  )
}
