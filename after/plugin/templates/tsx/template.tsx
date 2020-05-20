/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */

import { Component } from 'react'
import styles from './ComponentName.MIDDLE_NAME.scss'

interface ComponentNameProps {
    propName: string
}

interface ComponentNameState {
    stateName: string
}

class ComponentName extends Component<ComponentNameProps, ComponentNameState> {
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

    render() {
        return <div />
    }

    nameMethod() {
        // TODO
    }

    // Lifecycle Methods

    // componentDidMount() {}
    // componentDidUpdate(prevProps, prevState, snapshot) {}
    // componentWillUnmount() {}

    // Rarely Used Lifecycle Methods

    // static getDerivedStateFromProps(props, state) {}
    // shouldComponentUpdate(nextProps, nextState) {}
    // getSnapshotBeforeUpdate(prevProps, prevState) {}

    // Error boundaries
    // static getDerivedStateFromError(error) {}
    // componentDidCatch(error, info) {}

    // Legacy Lifecycle Methods
    // UNSAFE_componentWillMount() {}
    // UNSAFE_componentWillReceiveProps(nextProps) {}
    // UNSAFE_componentWillUpdate(nextProps, nextState) {}
}

export default ComponentName
