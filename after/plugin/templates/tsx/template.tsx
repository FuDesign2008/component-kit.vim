/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */

import React, {ReactElement} from 'react'
// import styles from './ComponentName.MIDDLE_NAME.scss'

interface ComponentNameProps {
  propName: string
}

interface ComponentNameState {
  stateName: string
}

class ComponentName extends React.PureComponent<
  ComponentNameProps,
  ComponentNameState
> {
  /***************************************************************************
   *  static properties and methods
   **************************************************************************/

  static defaultProps = {
    // TODO
  }

  constructor(props: ComponentNameProps) {
    super(props)

    this.state = {
      stateName: 'TODO',
    }

    // bind this
    this.nameMethod = this.nameMethod.bind(this)
  }

  render(): ReactElement {
    return <div />
  }

  /***************************************************************************
   *  custom methods
   **************************************************************************/

  nameMethod(): void {
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

