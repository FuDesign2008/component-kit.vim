/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */
import React from 'react'
import styles from './ComponentName.MIDDLE_NAME.scss'

class ComponentName extends React.PureComponent {
  /***************************************************************************
   *  static properties and methods
   **************************************************************************/

  static defaultProps = {
    // TODO
  }

  constructor(props) {
    super(props)

    this.state = {
      // TODO
    }

    // bind this
    this.nameMethod = this.nameMethod.bind(this)
  }

  render() {
    return <div />
  }

  /***************************************************************************
   *  custom methods
   **************************************************************************/
  nameMethod() {
    // TODO
  }

  /***************************************************************************
   * lifecycle methods
   **************************************************************************/

  // componentDidMount() {}

  // componentDidUpdate(prevProps, prevState, snapshot) {}

  // componentWillUnmount() {}

  /* rarely used lifecycle methods */

  // static getDerivedStateFromProps(props, state) {}

  // shouldComponentUpdate(nextProps, nextState) {}

  // getSnapshotBeforeUpdate(prevProps, prevState) {}

  /* error boundaries */

  // static getDerivedStateFromError(error) {}

  // componentDidCatch(error, info) {}

  /* legacy lifecycle methods */

  // UNSAFE_componentWillMount() {}

  // UNSAFE_componentWillReceiveProps(nextProps) {}

  // UNSAFE_componentWillUpdate(nextProps, nextState) {}
}

export default ComponentName

