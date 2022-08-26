/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */

import React, { ReactElement, useEffect } from 'react'
import { useSelector, useDispatch, shallowEqual } from 'react-redux'
import styles from './ComponentName.module.scss'
import { fetchData } from '../sliceName'
import { RootState } from 'src/pages/home/store/rootReducer'

export interface ComponentNameProps {
    propName: string
}

function ComponentName(props: ComponentNameProps): ReactElement {
    // 获取数据
    const dispatch = useDispatch()

    useEffect(() => {
        dispatch(fetchData({}))
    }, [])

    // 绑定数据
    const { data } = useSelector((state: RootState) => {
        return {
            data: state.sliceName.data,
        }
    }, shallowEqual)

    // TODO

    return <div className={styles.container}></div>
}

export default ComponentName
